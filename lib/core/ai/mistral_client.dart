import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:sift/core/ai/mistral_rate_limits.dart';
import 'package:sift/core/ai/rate_limited_queue.dart';
import 'package:sift/core/diagnostics/diagnostic_log.dart';

/// Shared low-level transport for Mistral AI's OpenAI-compatible chat
/// completions API — used by both LLMService (screenshot tagging) and
/// AssistantService (chat), so auth/retry/rate-limiting/JSON-parsing logic
/// lives in one place rather than being duplicated per caller.
///
/// Third provider this project has run on: Gemini (google_generative_ai,
/// schema-enforced) → Qwen (Alibaba Cloud DashScope) → Mistral (this one).
/// Qwen and Mistral share the same OpenAI-compatible request/response shape,
/// so this is mostly the Qwen transport with the endpoint and model names
/// swapped — the JSON-shape discipline the move away from Gemini required
/// (spelling the exact response shape out in the prompt, since neither
/// DashScope's nor Mistral's json_object mode enforces a schema server-side)
/// carries over unchanged.
///
/// Every call is paced through a [RateLimitedQueue] keyed by model, built
/// from [kMistralRateLimits] — real numbers pulled from the account's own
/// Mistral console, not guessed. Several of those limits are fractional
/// requests-per-second (mistral-large-2512 allows roughly one request per 14
/// seconds), which a naive fire-and-hope client blows through immediately;
/// queueing admission instead of just retrying after a 429 is what actually
/// keeps a real screenshot-tagging workload from failing outright.
class MistralClient {
  MistralClient._();

  static const String _endpoint = 'https://api.mistral.ai/v1/chat/completions';

  static final Map<String, RateLimitedQueue> _queues = {};

  static RateLimitedQueue _queueFor(String model) {
    return _queues.putIfAbsent(model, () {
      final limit = kMistralRateLimits[model] ?? kMistralFallbackLimit;
      return RateLimitedQueue(
        requestsPerSecond: limit.rps,
        tokensPerMinute: limit.tpm,
      );
    });
  }

  /// ~4 characters per token for English-ish text, plus a fixed allowance
  /// for image tokens. Both are approximations pending a real call to see
  /// actual usage in the response — overestimating just makes the queue
  /// wait a touch longer than strictly necessary, which is the safe
  /// direction; underestimating risks a real 429 slipping through.
  static int _estimateTokens(String prompt, {required bool hasImage}) {
    final textTokens = (prompt.length / 4).ceil();
    const imageTokenAllowance = 1100;
    return textTokens + (hasImage ? imageTokenAllowance : 0);
  }

  /// Sends one chat-completion request expecting a JSON object back —
  /// queued against the model's real rate limit first (see class doc), then
  /// retried with backoff if a 429 gets through anyway.
  ///
  /// [imageBytes]/[imageMime] attach one image as a base64 data URI, in the
  /// same vision message shape OpenAI-compatible APIs use.
  static Future<Map<String, dynamic>> completeJson({
    required String apiKey,
    required String model,
    required String prompt,
    Uint8List? imageBytes,
    String? imageMime,
  }) {
    final estimatedTokens =
        _estimateTokens(prompt, hasImage: imageBytes != null);
    return _queueFor(model).run(estimatedTokens, () => _completeJsonNow(
          apiKey: apiKey,
          model: model,
          prompt: prompt,
          imageBytes: imageBytes,
          imageMime: imageMime,
        ));
  }

  static Future<Map<String, dynamic>> _completeJsonNow({
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

        // The queue should mean this rarely fires — a genuine safety net
        // (clock drift, a second isolate's queue running independently,
        // the token estimate above being wrong) rather than the primary
        // defence.
        if (response.statusCode == 429 && attempt < maxAttempts) {
          final wait = Duration(seconds: 5 * attempt);
          debugPrint('MistralClient: rate-limited (attempt $attempt/'
              '$maxAttempts) — retrying in ${wait.inSeconds}s.');
          DiagnosticLog.warn(
              'MistralClient: rate-limited despite queueing — retrying in '
              '${wait.inSeconds}s (attempt $attempt/$maxAttempts).');
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
  /// safety net rather than the expected path.
  static String _stripFences(String text) {
    final fenced = RegExp(r'^```(?:json)?\s*([\s\S]*?)\s*```$');
    final match = fenced.firstMatch(text);
    return match != null ? match.group(1)!.trim() : text;
  }
}
