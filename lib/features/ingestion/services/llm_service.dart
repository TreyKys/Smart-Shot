import 'dart:convert';
import 'dart:io';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:http/http.dart' as http;
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

/// Two ways this reaches Gemini, chosen per call:
///
/// - A user-supplied BYOK key (Settings) calls Gemini directly. Their key,
///   their cost, their choice to accept the same client-side exposure risk.
/// - Everyone else goes through the App Check-gated Cloudflare Worker at
///   [AppConfig.geminiProxyUrl] (see server/gemini-proxy/). The shared key
///   lives only as a Worker secret — never compiled into this app, never
///   sent to a client, nothing for `strings` on the APK or a MITM proxy to
///   find. The Worker verifies a Firebase App Check token instead.
class LLMService {
  LLMService();

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

  // ── Single-screenshot analysis ──────────────────────────────────────────────

  /// Analyses one screenshot, sending only what the [route] calls for.
  ///
  /// [byokApiKey]: pass the user's own key to call Gemini directly (BYOK).
  /// Leave null/empty to route through the shared proxy instead.
  Future<Map<String, dynamic>> analyze(
    File file, {
    String? byokApiKey,
    required OcrResult ocr,
    AnalysisRoute? route,
  }) async {
    if (!_usable(byokApiKey)) return {};
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

    return _generate([Content.multi(parts)], _analysisSchema(),
        byokApiKey: byokApiKey);
  }

  // ── Batched text-only analysis ──────────────────────────────────────────────

  /// Classifies several text-only screenshots in a single request.
  ///
  /// Returns results keyed by [TextAnalysisItem.id]. Ids missing from the map
  /// were not returned by the model and should be retried individually rather
  /// than silently dropped — one malformed item must not discard the batch.
  Future<Map<int, Map<String, dynamic>>> analyzeTextBatch(
    List<TextAnalysisItem> items, {
    String? byokApiKey,
  }) async {
    if (items.isEmpty || !_usable(byokApiKey)) return {};

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

    final decoded = await _generate([Content.text(buffer.toString())], schema,
        byokApiKey: byokApiKey);

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

  // ── Transport ───────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> _generate(
    List<Content> contents,
    Schema schema, {
    String? byokApiKey,
  }) {
    final generationConfig = GenerationConfig(
      responseMimeType: 'application/json',
      responseSchema: schema,
    );

    if (byokApiKey != null &&
        byokApiKey.isNotEmpty &&
        byokApiKey != 'INSERT_API_KEY_HERE') {
      return _generateDirect(contents, generationConfig, byokApiKey);
    }
    return _generateViaProxy(contents, generationConfig);
  }

  bool _usable(String? byokApiKey) {
    final hasByok = byokApiKey != null &&
        byokApiKey.isNotEmpty &&
        byokApiKey != 'INSERT_API_KEY_HERE';
    if (hasByok) return true;
    if (AppConfig.geminiProxyUrl.isEmpty) {
      debugPrint(
          'LLMService: no BYOK key and GEMINI_PROXY_URL not configured — skipping.');
      return false;
    }
    return true;
  }

  /// BYOK path — calls Gemini directly with the user's own key.
  Future<Map<String, dynamic>> _generateDirect(
    List<Content> contents,
    GenerationConfig generationConfig,
    String apiKey,
  ) async {
    try {
      final model = GenerativeModel(
        model: _kGeminiModel,
        apiKey: apiKey,
        generationConfig: generationConfig,
      );
      final response = await model.generateContent(contents);
      return _decodeObject(response.text);
    } catch (e, st) {
      debugPrint('LLMService: direct call failed: $e\n$st');
      return {};
    }
  }

  /// Default path — routes through the App Check-gated proxy. Builds the
  /// exact REST body Gemini expects (the same shape package:google_generative_ai
  /// sends) using that package's own Content/GenerationConfig/Schema toJson()
  /// builders, so the Worker's schema/prompt logic never has to be
  /// reimplemented server-side or kept in sync with the client by hand.
  Future<Map<String, dynamic>> _generateViaProxy(
    List<Content> contents,
    GenerationConfig generationConfig,
  ) async {
    final proxyUrl = AppConfig.geminiProxyUrl;
    if (proxyUrl.isEmpty) {
      debugPrint('LLMService: GEMINI_PROXY_URL not configured — skipping.');
      return {};
    }

    String? token;
    try {
      token = await FirebaseAppCheck.instance.getToken();
    } catch (e) {
      debugPrint('LLMService: App Check token fetch failed: $e');
    }
    if (token == null || token.isEmpty) {
      debugPrint(
          'LLMService: no App Check token — proxy will reject this, skipping.');
      return {};
    }

    final requestBody = jsonEncode({
      'contents': contents.map((c) => c.toJson()).toList(),
      'generationConfig': generationConfig.toJson(),
    });

    try {
      final response = await http.post(
        Uri.parse(proxyUrl),
        headers: {
          'Content-Type': 'application/json',
          'X-Firebase-AppCheck': token,
        },
        body: requestBody,
      );

      if (response.statusCode != 200) {
        debugPrint(
            'LLMService: proxy returned ${response.statusCode}: ${response.body}');
        return {};
      }

      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) return {};
      return _decodeObject(_extractText(decoded));
    } catch (e, st) {
      debugPrint('LLMService: proxy request failed: $e\n$st');
      return {};
    }
  }

  /// Extracts the model's text output from a raw Gemini REST response.
  ///
  /// Mirrors `GenerateContentResponse.text` from package:google_generative_ai
  /// (candidates[0].content.parts, concatenating text parts) — that class
  /// isn't reusable here since it's built for the package's own client, not
  /// for parsing a response relayed by our own proxy. Returns null rather
  /// than throwing on a blocked/empty response; the caller already treats a
  /// null/empty result as "nothing usable came back".
  String? _extractText(Map<String, dynamic> json) {
    final candidates = json['candidates'];
    if (candidates is! List || candidates.isEmpty) return null;
    final first = candidates.first;
    if (first is! Map) return null;
    final content = first['content'];
    if (content is! Map) return null;
    final parts = content['parts'];
    if (parts is! List) return null;
    final texts =
        parts.whereType<Map>().map((p) => p['text']).whereType<String>();
    return texts.isEmpty ? null : texts.join();
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────

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
