import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:sift/core/diagnostics/diagnostic_log.dart';

/// Shared low-level transport for Alibaba Cloud DashScope's OpenAI-compatible
/// chat completions API — used by both LLMService (screenshot tagging) and
/// AssistantService (chat), so auth/retry/JSON-parsing logic lives in one
/// place rather than being duplicated per caller.
///
/// Replaces the previous google_generative_ai-based transport (Gemini). The
/// two providers differ in one structurally important way: Gemini's
/// `responseSchema` enforced the JSON shape and tag enum server-side, so a
/// malformed or off-vocabulary response literally couldn't come back.
/// DashScope's `response_format: json_object` only guarantees valid JSON
/// syntax, not a specific shape — callers now carry that responsibility via
/// their prompt text (spelling out the exact required keys and the closed
/// tag vocabulary) and defensive parsing downstream
/// (TagVocabulary.canonicalize() already drops anything off-vocabulary).
///
/// NOT YET VERIFIED AGAINST A LIVE KEY — there was no DashScope API key
/// available while writing this. The endpoint, auth header shape, and
/// request/response JSON shape all follow Alibaba's own documented
/// OpenAI-compatibility layer, but the model name and exact response
/// envelope should be double-checked against a real call once a key exists.
class QwenClient {
  QwenClient._();

  /// International (Singapore) endpoint — the default for API access granted
  /// outside mainland China, which is the assumption here given no region
  /// was confirmed. If access turns out to be mainland-only, this is the one
  /// line to change: swap to
  /// 'https://dashscope.aliyuncs.com/compatible-mode/v1/chat/completions'.
  static const String _endpoint =
      'https://dashscope-intl.aliyuncs.com/compatible-mode/v1/chat/completions';

  /// Sends one chat-completion request expecting a JSON object back.
  ///
  /// [imageBytes]/[imageMime] attach one image as a base64 data URI, in the
  /// same vision message shape OpenAI-compatible APIs use. Retries with
  /// backoff on HTTP 429 (rate limit) up to 3 attempts, same policy the
  /// Gemini transport used.
  static Future<Map<String, dynamic>> completeJson({
    required String apiKey,
    required String model,
    required String prompt,
    Uint8List? imageBytes,
    String? imageMime,
  }) async {
    const maxAttempts = 3;
    for (var attempt = 1; attempt <= maxAttempts; attempt++) {
      try {
        final content = <Map<String, dynamic>>[
          {'type': 'text', 'text': prompt},
        ];
        if (imageBytes != null && imageMime != null) {
          content.add({
            'type': 'image_url',
            'image_url': {
              'url': 'data:$imageMime;base64,${base64Encode(imageBytes)}',
            },
          });
        }

        final response = await http
            .post(
              Uri.parse(_endpoint),
              headers: {
                'Authorization': 'Bearer $apiKey',
                'Content-Type': 'application/json',
              },
              body: jsonEncode({
                'model': model,
                'messages': [
                  {'role': 'user', 'content': content},
                ],
                'response_format': {'type': 'json_object'},
              }),
            )
            .timeout(const Duration(seconds: 45));

        if (response.statusCode == 429 && attempt < maxAttempts) {
          final wait = Duration(seconds: 3 * attempt);
          debugPrint('QwenClient: rate-limited (attempt $attempt/'
              '$maxAttempts) — retrying in ${wait.inSeconds}s.');
          DiagnosticLog.warn(
              'QwenClient: rate-limited — retrying in ${wait.inSeconds}s '
              '(attempt $attempt/$maxAttempts).');
          await Future.delayed(wait);
          continue;
        }

        if (response.statusCode != 200) {
          final bodySnippet = response.body.length > 300
              ? '${response.body.substring(0, 300)}…'
              : response.body;
          debugPrint('QwenClient: HTTP ${response.statusCode}: $bodySnippet');
          DiagnosticLog.error(
              'QwenClient: HTTP ${response.statusCode} — $bodySnippet');
          return {};
        }

        return _extractJson(response.body);
      } catch (e) {
        debugPrint('QwenClient: call failed: $e');
        DiagnosticLog.error('QwenClient: call failed — $e');
        return {};
      }
    }
    return {};
  }

  static Map<String, dynamic> _extractJson(String responseBody) {
    try {
      final decoded = jsonDecode(responseBody);
      if (decoded is! Map) {
        DiagnosticLog.warn('QwenClient: top-level response was not an object.');
        return {};
      }
      final choices = decoded['choices'];
      if (choices is! List || choices.isEmpty) {
        DiagnosticLog.warn('QwenClient: response had no choices.');
        return {};
      }
      final firstChoice = choices.first;
      final message = firstChoice is Map ? firstChoice['message'] : null;
      final text = message is Map ? message['content'] as String? : null;
      if (text == null || text.trim().isEmpty) {
        DiagnosticLog.warn('QwenClient: empty message content.');
        return {};
      }
      final parsed = jsonDecode(_stripFences(text.trim()));
      if (parsed is Map<String, dynamic>) return parsed;
      debugPrint('QwenClient: model content was not a JSON object: $parsed');
      DiagnosticLog.warn('QwenClient: model content was not a JSON object.');
      return {};
    } catch (e) {
      debugPrint('QwenClient: JSON parse error: $e\nRaw: $responseBody');
      DiagnosticLog.error('QwenClient: could not parse response: $e');
      return {};
    }
  }

  /// Some models wrap JSON in ```json fences even when told not to — Gemini's
  /// schema enforcement made this a non-issue; DashScope's json_object mode
  /// doesn't guarantee fence-free output the same way, so this is a safety
  /// net rather than the expected path.
  static String _stripFences(String text) {
    final fenced = RegExp(r'^```(?:json)?\s*([\s\S]*?)\s*```$');
    final match = fenced.firstMatch(text);
    return match != null ? match.group(1)!.trim() : text;
  }
}
