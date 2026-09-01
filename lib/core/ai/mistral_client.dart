import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:sift/core/diagnostics/diagnostic_log.dart';

/// Shared low-level transport for Mistral AI's OpenAI-compatible chat
/// completions API — used by both LLMService (screenshot tagging) and
/// AssistantService (chat), so auth/retry/JSON-parsing logic lives in one
/// place rather than being duplicated per caller.
///
/// Second provider swap this project has been through: Gemini
/// (google_generative_ai, schema-enforced) → Qwen (Alibaba Cloud DashScope,
/// OpenAI-compatible) → Mistral (this one, also OpenAI-compatible). Since
/// Qwen and Mistral share the same request/response shape, this is mostly
/// QwenClient with the endpoint and model names swapped — the JSON-shape
/// discipline that move away from Gemini required (spelling the exact
/// response shape out in the prompt, since neither DashScope's nor Mistral's
/// json_object mode enforces a specific schema server-side) carries over
/// unchanged.
///
/// NOT YET VERIFIED AGAINST A LIVE KEY — there was no Mistral API key
/// available while writing this. The endpoint, auth header shape, and
/// request/response JSON envelope follow Mistral's own documented API
/// (which is intentionally OpenAI-compatible), but the exact model name and
/// response envelope should be double-checked against a real call once a key
/// exists — see the model constants in llm_service.dart and
/// assistant_service.dart, both one-line changes if the model id is wrong.
class MistralClient {
  MistralClient._();

  static const String _endpoint = 'https://api.mistral.ai/v1/chat/completions';

  /// Sends one chat-completion request expecting a JSON object back.
  ///
  /// [imageBytes]/[imageMime] attach one image as a base64 data URI, in the
  /// same vision message shape OpenAI-compatible APIs use. Retries with
  /// backoff on HTTP 429 (rate limit) up to 3 attempts — Mistral's free tier
  /// is reported to be rate-limited quite tightly (a couple of requests per
  /// minute on some accounts, per its own docs' "for evaluation, not
  /// production" framing), so this matters more here than it did on Qwen.
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
          final wait = Duration(seconds: 5 * attempt);
          debugPrint('MistralClient: rate-limited (attempt $attempt/'
              '$maxAttempts) — retrying in ${wait.inSeconds}s.');
          DiagnosticLog.warn(
              'MistralClient: rate-limited — retrying in ${wait.inSeconds}s '
              '(attempt $attempt/$maxAttempts). If this fires constantly, '
              'the free-tier RPM limit is the bottleneck, not the monthly '
              'token cap — check Mistral\'s console for your real limit.');
          await Future.delayed(wait);
          continue;
        }

        if (response.statusCode != 200) {
          final bodySnippet = response.body.length > 300
              ? '${response.body.substring(0, 300)}…'
              : response.body;
          debugPrint(
              'MistralClient: HTTP ${response.statusCode}: $bodySnippet');
          DiagnosticLog.error(
              'MistralClient: HTTP ${response.statusCode} — $bodySnippet');
          return {};
        }

        return _extractJson(response.body);
      } catch (e) {
        debugPrint('MistralClient: call failed: $e');
        DiagnosticLog.error('MistralClient: call failed — $e');
        return {};
      }
    }
    return {};
  }

  static Map<String, dynamic> _extractJson(String responseBody) {
    try {
      final decoded = jsonDecode(responseBody);
      if (decoded is! Map) {
        DiagnosticLog.warn(
            'MistralClient: top-level response was not an object.');
        return {};
      }
      final choices = decoded['choices'];
      if (choices is! List || choices.isEmpty) {
        DiagnosticLog.warn('MistralClient: response had no choices.');
        return {};
      }
      final firstChoice = choices.first;
      final message = firstChoice is Map ? firstChoice['message'] : null;
      final text = message is Map ? message['content'] as String? : null;
      if (text == null || text.trim().isEmpty) {
        DiagnosticLog.warn('MistralClient: empty message content.');
        return {};
      }
      final parsed = jsonDecode(_stripFences(text.trim()));
      if (parsed is Map<String, dynamic>) return parsed;
      debugPrint(
          'MistralClient: model content was not a JSON object: $parsed');
      DiagnosticLog.warn(
          'MistralClient: model content was not a JSON object.');
      return {};
    } catch (e) {
      debugPrint('MistralClient: JSON parse error: $e\nRaw: $responseBody');
      DiagnosticLog.error('MistralClient: could not parse response: $e');
      return {};
    }
  }

  /// Some models wrap JSON in ```json fences even when told not to — a
  /// safety net rather than the expected path, same as the Qwen transport.
  static String _stripFences(String text) {
    final fenced = RegExp(r'^```(?:json)?\s*([\s\S]*?)\s*```$');
    final match = fenced.firstMatch(text);
    return match != null ? match.group(1)!.trim() : text;
  }
}
