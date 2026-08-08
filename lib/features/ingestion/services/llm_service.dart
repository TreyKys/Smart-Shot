import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sift/core/config/app_config.dart';
import 'package:sift/features/ingestion/domain/tag_vocabulary.dart';
import 'package:sift/features/ingestion/services/ocr_service.dart';

part 'llm_service.g.dart';

@Riverpod(keepAlive: true)
LLMService llmService(LlmServiceRef ref) {
  return LLMService();
}

const String _kGeminiModel = 'gemini-2.5-flash';

/// Long-edge cap for uploaded images — beyond this Gemini gains no detail.
const int _kMaxUploadEdge = 1568;

/// How many text-only screenshots to classify in a single request.
///
/// Text-only items are ~100–500 tokens each, so a dozen fits comfortably.
/// Images cannot be batched this way — a dozen of those is ~20k tokens.
const int kTextBatchSize = 12;

/// One screenshot queued for text-only classification.
@immutable
class TextAnalysisItem {
  /// Caller-assigned id, echoed back by the model so results can be matched up.
  final int id;
  final String ocrText;
  const TextAnalysisItem({required this.id, required this.ocrText});
}

class LLMService {
  final String _envApiKey;

  LLMService({String? apiKey}) : _envApiKey = apiKey ?? AppConfig.geminiApiKey {
    if (_envApiKey.isEmpty) {
      debugPrint('Warning: GEMINI_API_KEY was not supplied via --dart-define');
    }
  }

  // ── Schema ──────────────────────────────────────────────────────────────────

  /// Shape of one screenshot's analysis.
  ///
  /// Enforced server-side, which is what lets the prompt drop its "output
  /// strictly valid JSON, no markdown" pleading and lets the parser drop its
  /// fence-stripping and String-vs-List coercion. Tags are an enum over the
  /// closed vocabulary, so the model cannot invent a tag the gallery has no
  /// filter for.
  static Schema _analysisSchema({bool withId = false}) => Schema.object(
        properties: {
          if (withId)
            'id': Schema.integer(
                description: 'Echo back the id of the screenshot analysed.'),
          'tags': Schema.array(
            items: Schema.enumString(enumValues: TagVocabulary.bareNames),
            description: '1-3 categories that best describe the content.',
          ),
          'topic': Schema.string(
            description:
                'A short specific subject line, e.g. "Uber receipt, 12 Mar" '
                'or "Solana staking rewards". Free text, not a category.',
            nullable: true,
          ),
          'cleanText': Schema.string(
              description: 'Readable text from the screenshot, tidied up.',
              nullable: true),
          'urls': Schema.array(items: Schema.string(), nullable: true),
          'emails': Schema.array(items: Schema.string(), nullable: true),
          'phoneNumbers': Schema.array(items: Schema.string(), nullable: true),
          'dates': Schema.array(
            items: Schema.string(description: 'ISO 8601, YYYY-MM-DD.'),
            nullable: true,
          ),
          'cryptoAddresses':
              Schema.array(items: Schema.string(), nullable: true),
          'suggested_actions': Schema.array(
            nullable: true,
            items: Schema.object(
              properties: {
                'label': Schema.string(description: 'Short button label.'),
                'payload': Schema.string(
                    description: 'URL, address or number to act on.'),
                'intent_type':
                    Schema.enumString(enumValues: ['url', 'copy', 'dial']),
              },
              requiredProperties: ['label', 'payload', 'intent_type'],
            ),
          ),
          'suggested_app': Schema.enumString(
            enumValues: ['pulse', 'context', 'magnum_opus', 'none'],
            description: 'Best companion app, or "none".',
            nullable: true,
          ),
        },
        requiredProperties: ['tags'],
      );

  GenerativeModel _model(String apiKey, {required Schema schema}) {
    return GenerativeModel(
      model: _kGeminiModel,
      apiKey: apiKey,
      generationConfig: GenerationConfig(
        responseMimeType: 'application/json',
        responseSchema: schema,
      ),
    );
  }

  // ── Single-screenshot analysis ──────────────────────────────────────────────

  /// Analyses one screenshot, sending only what the [route] calls for.
  Future<Map<String, dynamic>> analyze(
    File file, {
    required String apiKey,
    required OcrResult ocr,
    AnalysisRoute? route,
  }) async {
    if (!_usableKey(apiKey)) return {};
    final effective = route ?? ocr.route;

    final parts = <Part>[TextPart(_promptFor(effective, ocr.text))];
    if (effective != AnalysisRoute.textOnly) {
      final (bytes, mime) = await _prepareImage(file);
      parts.add(DataPart(mime, bytes));
      debugPrint(
          'LLM: ${effective.name} route, ${bytes.length} image bytes — ${file.path}');
    } else {
      debugPrint('LLM: textOnly route, no image — ${file.path}');
    }

    final model = _model(apiKey, schema: _analysisSchema());
    final response = await model.generateContent([Content.multi(parts)]);
    return _decodeObject(response.text);
  }

  // ── Batched text-only analysis ──────────────────────────────────────────────

  /// Classifies several text-only screenshots in a single request.
  ///
  /// Returns results keyed by [TextAnalysisItem.id]. Ids missing from the map
  /// were not returned by the model and should be retried individually rather
  /// than silently dropped — one malformed item must not discard the batch.
  Future<Map<int, Map<String, dynamic>>> analyzeTextBatch(
    List<TextAnalysisItem> items, {
    required String apiKey,
  }) async {
    if (items.isEmpty || !_usableKey(apiKey)) return {};

    final buffer = StringBuffer(_kPromptBatch);
    for (final item in items) {
      buffer
        ..writeln()
        ..writeln('--- SCREENSHOT id=${item.id} ---')
        ..writeln(item.ocrText.trim());
    }

    final schema = Schema.object(
      properties: {
        'results': Schema.array(items: _analysisSchema(withId: true)),
      },
      requiredProperties: ['results'],
    );

    final model = _model(apiKey, schema: schema);
    final response =
        await model.generateContent([Content.text(buffer.toString())]);

    final decoded = _decodeObject(response.text);
    final raw = decoded['results'];
    if (raw is! List) {
      debugPrint('LLM batch: no results array — falling back to singles.');
      return {};
    }

    final out = <int, Map<String, dynamic>>{};
    for (final entry in raw) {
      if (entry is! Map) continue;
      final map = Map<String, dynamic>.from(entry);
      final id = map['id'];
      if (id is int) out[id] = map;
    }
    debugPrint('LLM batch: ${out.length}/${items.length} returned.');
    return out;
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────

  bool _usableKey(String key) {
    if (key.isEmpty || key == 'INSERT_API_KEY_HERE') {
      debugPrint('LLMService: skipping — no API key.');
      return false;
    }
    return true;
  }

  String _promptFor(AnalysisRoute route, String ocrText) {
    final trimmed = ocrText.trim();
    switch (route) {
      case AnalysisRoute.textOnly:
        return '$_kPromptBase\n\nTEXT EXTRACTED FROM THE SCREENSHOT:\n$trimmed';
      case AnalysisRoute.vision:
        return '$_kPromptBase\n\n'
            'Little or no text could be extracted from this image, so judge it '
            'primarily from what you see.';
      case AnalysisRoute.dual:
        return trimmed.isEmpty
            ? _kPromptBase
            : '$_kPromptBase\n\nTEXT EXTRACTED FROM THE IMAGE:\n$trimmed';
    }
  }

  /// Downscales and re-encodes before upload.
  ///
  /// Gemini tiles vision input at 768px, so anything beyond ~1568px on the long
  /// edge costs upload time and tokens for pixels the model discards. A phone
  /// screenshot is typically a 2–4 MB PNG; this usually lands under 300 KB.
  /// Falls back to the original bytes if compression fails for any reason.
  Future<(Uint8List, String)> _prepareImage(File file) async {
    try {
      final compressed = await FlutterImageCompress.compressWithFile(
        file.absolute.path,
        minWidth: _kMaxUploadEdge,
        minHeight: _kMaxUploadEdge,
        quality: 80,
        format: CompressFormat.jpeg,
      );
      if (compressed != null && compressed.isNotEmpty) {
        return (compressed, 'image/jpeg');
      }
      debugPrint('LLMService: compression returned empty — using original.');
    } catch (e) {
      debugPrint('LLMService: compression failed ($e) — using original.');
    }
    return (await file.readAsBytes(), _mimeFromPath(file.path));
  }

  static String _mimeFromPath(String path) {
    switch (path.split('.').last.toLowerCase()) {
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      case 'gif':
        return 'image/gif';
      case 'heic':
      case 'heif':
        return 'image/heif';
      default:
        return 'image/jpeg';
    }
  }

  /// The schema makes well-formed JSON the norm, but a truncated or
  /// safety-blocked response still has to fail softly rather than throw.
  Map<String, dynamic> _decodeObject(String? responseText) {
    if (responseText == null || responseText.trim().isEmpty) return {};
    try {
      final decoded = jsonDecode(responseText.trim());
      if (decoded is Map<String, dynamic>) return decoded;
      debugPrint('LLMService: response was not an object: $decoded');
    } catch (e) {
      debugPrint('LLMService: JSON parse error: $e\nRaw: $responseText');
    }
    return {};
  }
}

// ── Prompts ────────────────────────────────────────────────────────────────────

// The output shape is enforced by responseSchema, so the prompt only has to
// describe judgement — not formatting, not the tag list, not "return valid
// JSON". Tags are constrained to the closed vocabulary by the schema enum.
const String _kPromptBase = '''
You are analysing a screenshot from a user's phone to help them find it later.

Choose 1-3 tags that describe what the screenshot actually is. Prefer fewer,
accurate tags over many loose ones. Use Junk only when the image is blank,
corrupted, or has no recognisable content — not merely because it is low
quality.

Set "topic" to a short specific description a person would recognise months
later, for example "Uber receipt, 12 Mar" rather than "a receipt".

Extract URLs, emails, phone numbers, dates and crypto addresses only when they
are genuinely present. Do not guess or invent them.
''';

const String _kPromptBatch = '''
You are analysing several screenshots from a user's phone. Each is delimited by
a "--- SCREENSHOT id=N ---" marker, and only its extracted text is given.

Return one result per screenshot, echoing that screenshot's id. Analyse each
independently — do not let one screenshot's subject influence another's.

Choose 1-3 tags that describe what each screenshot actually is. Prefer fewer,
accurate tags over many loose ones. Use Junk only when the text indicates no
recognisable content.

Set "topic" to a short specific description a person would recognise months
later, for example "Uber receipt, 12 Mar" rather than "a receipt".

Extract URLs, emails, phone numbers, dates and crypto addresses only when they
are genuinely present. Do not guess or invent them.
''';
