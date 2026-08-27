import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sift/core/ai/qwen_client.dart';
import 'package:sift/core/config/shared_key_service.dart';
import 'package:sift/core/diagnostics/diagnostic_log.dart';
import 'package:sift/features/ingestion/domain/tag_vocabulary.dart';
import 'package:sift/features/ingestion/services/ocr_service.dart';

part 'llm_service.g.dart';

@Riverpod(keepAlive: true)
LLMService llmService(LlmServiceRef ref) {
  return LLMService();
}

// Picked as the default vision-capable Qwen model — fast/cheap tier,
// mirroring gemini-2.5-flash's role before the provider switch. NOT verified
// against a live call (no DashScope key was available while writing this);
// confirm the exact model id once real access exists — Alibaba's naming has
// shifted before (qwen-vl-plus vs qwen2.5-vl-*) and may again.
const String _kQwenModel = 'qwen-vl-plus';

/// Long-edge cap for uploaded images — vision models generally gain nothing
/// past this regardless of provider.
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

/// Two keys reach the model, chosen per call — the transport is the same
/// either way:
///
/// - A user-supplied BYOK key (Settings). Their key, their cost, their choice.
/// - Everyone else uses the shared key from [SharedKeyService], delivered by
///   Firebase Remote Config once App Check has vouched for the build. It is
///   never compiled into the app, so there's nothing for `strings` on the APK
///   to find, and it can be rotated from the console without an update.
///
/// Calls Alibaba Cloud DashScope (Qwen) via [QwenClient] — previously Gemini,
/// via google_generative_ai. That package enforced this class's JSON shape
/// and tag enum server-side (`responseSchema`); DashScope's json_object mode
/// only guarantees valid JSON syntax, not a specific shape, so the shape is
/// now spelled out in the prompt text instead (see [_jsonShapeInstructions])
/// and TagVocabulary.canonicalize() downstream is the safety net for any tag
/// that slips through anyway.
class LLMService {
  LLMService();

  // ── Single-screenshot analysis ──────────────────────────────────────────────

  /// Analyses one screenshot, sending only what the [route] calls for.
  ///
  /// [byokApiKey]: pass the user's own key to use it (BYOK). Leave null/empty
  /// to fall back to the shared Remote Config key.
  Future<Map<String, dynamic>> analyze(
    File file, {
    String? byokApiKey,
    required OcrResult ocr,
    AnalysisRoute? route,
  }) async {
    if (!_usable(byokApiKey)) return {};
    final effective = route ?? ocr.route;

    final prompt =
        '${_promptFor(effective, ocr.text)}\n\n${_jsonShapeInstructions()}';

    Uint8List? imageBytes;
    String? imageMime;
    if (effective != AnalysisRoute.textOnly) {
      final (bytes, mime) = await _prepareImage(file);
      imageBytes = bytes;
      imageMime = mime;
      debugPrint('LLM: ${effective.name} route, ${bytes.length} image bytes '
          '— ${file.path}');
    } else {
      debugPrint('LLM: textOnly route, no image — ${file.path}');
    }

    return _generate(prompt,
        imageBytes: imageBytes, imageMime: imageMime, byokApiKey: byokApiKey);
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
    buffer
      ..writeln()
      ..writeln(_jsonShapeInstructionsBatch());

    final decoded =
        await _generate(buffer.toString(), byokApiKey: byokApiKey);

    final raw = decoded['results'];
    if (raw is! List) {
      debugPrint('LLM batch: no results array — falling back to singles.');
      DiagnosticLog.warn(
          'LLMService: batch call of ${items.length} screenshot(s) returned '
          'no results array — retrying each one individually.');
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
    if (out.length < items.length) {
      DiagnosticLog.warn(
          'LLMService: batch call returned ${out.length}/${items.length} — '
          'the rest will be retried individually.');
    } else {
      DiagnosticLog.info(
          'LLMService: batch call ok — ${out.length}/${items.length} '
          'screenshots classified.');
    }
    return out;
  }

  // ── Transport ───────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> _generate(
    String prompt, {
    Uint8List? imageBytes,
    String? imageMime,
    String? byokApiKey,
  }) {
    if (_hasByok(byokApiKey)) {
      return QwenClient.completeJson(
        apiKey: byokApiKey!,
        model: _kQwenModel,
        prompt: prompt,
        imageBytes: imageBytes,
        imageMime: imageMime,
      );
    }

    final sharedKey = SharedKeyService.apiKey;
    if (sharedKey.isEmpty) {
      debugPrint('LLMService: no BYOK key and no shared key — skipping.');
      DiagnosticLog.warn(
          'LLMService: skipped an AI call — no shared key available at the '
          'transport layer.');
      return Future.value({});
    }
    return QwenClient.completeJson(
      apiKey: sharedKey,
      model: _kQwenModel,
      prompt: prompt,
      imageBytes: imageBytes,
      imageMime: imageMime,
    );
  }

  static bool _hasByok(String? byokApiKey) =>
      byokApiKey != null &&
      byokApiKey.isNotEmpty &&
      byokApiKey != 'INSERT_API_KEY_HERE';

  bool _usable(String? byokApiKey) {
    if (_hasByok(byokApiKey)) return true;
    if (!SharedKeyService.isConfigured) {
      debugPrint(
          'LLMService: no BYOK key and Remote Config supplied no shared key '
          '— skipping.');
      DiagnosticLog.warn(
          'LLMService: skipped an AI call — no BYOK key set and no shared '
          'key available. This screenshot will fall back to local '
          'keyword-only tagging.');
      return false;
    }
    return true;
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
  /// Vision models generally tile/downsample input around this resolution
  /// anyway, so anything beyond ~1568px on the long edge costs upload time
  /// and tokens for pixels the model would discard. A phone screenshot is
  /// typically a 2–4 MB PNG; this usually lands under 300 KB. Falls back to
  /// the original bytes if compression fails for any reason.
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
}

// ── Prompts ────────────────────────────────────────────────────────────────────

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

// Gemini enforced this JSON shape and the tag enum server-side via
// `responseSchema`; DashScope's json_object mode only guarantees valid JSON
// syntax, not this specific shape — so it's spelled out in the prompt
// instead. Any tag outside the given list is dropped downstream by
// TagVocabulary.canonicalize() as a second line of defence, but a tighter
// prompt means that rarely has to fire.

const String _kResponseFormatNote =
    'Respond with ONLY a single JSON object — no markdown, no code fences, '
    'no text before or after it. Use exactly this shape:';

const String _kTagRule =
    '"tags" must use only values from the list given — never invent a new one.';

/// The object shape one screenshot's analysis must have.
String _analysisShape({bool withId = false}) {
  final tagList = TagVocabulary.bareNames.join(', ');
  return '{\n'
      '${withId ? '  "id": <integer — echo the screenshot id given above>,\n' : ''}'
      '  "tags": [<1 to 3 values, each exactly one of: $tagList>],\n'
      '  "topic": <short specific string, or null>,\n'
      '  "cleanText": <string, or null>,\n'
      '  "urls": [<strings>] or null,\n'
      '  "emails": [<strings>] or null,\n'
      '  "phoneNumbers": [<strings>] or null,\n'
      '  "dates": [<"YYYY-MM-DD" strings>] or null,\n'
      '  "cryptoAddresses": [<strings>] or null,\n'
      '  "suggested_actions": [{"label": <string>, "payload": <string>, '
      '"intent_type": "url" or "copy" or "dial"}] or null,\n'
      '  "suggested_app": "pulse" or "context" or "magnum_opus" or "none", '
      'or null\n'
      '}';
}

/// Full response-format instructions for a single-screenshot call.
String _jsonShapeInstructions() =>
    '$_kResponseFormatNote\n${_analysisShape()}\n$_kTagRule';

/// Full response-format instructions for a batched call — one shape nested
/// inside a "results" array, one entry per screenshot in the batch.
String _jsonShapeInstructionsBatch() {
  final indented =
      _analysisShape(withId: true).split('\n').map((l) => '    $l').join('\n');
  return '$_kResponseFormatNote\n'
      '{\n'
      '  "results": [\n'
      '    <one object per screenshot above, each shaped exactly like:\n'
      '$indented\n'
      '    >\n'
      '  ]\n'
      '}\n'
      '$_kTagRule';
}
