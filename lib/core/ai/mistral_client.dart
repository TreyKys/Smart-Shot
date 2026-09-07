import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:sift/core/ai/mistral_rate_limits.dart';
import 'package:sift/core/ai/rate_limited_queue.dart';
import 'package:sift/core/diagnostics/diagnostic_log.dart';

/// One tool execution the model requested and the caller fulfilled.
@immutable
class ToolExecution {
  final String name;
  final Map<String, dynamic> arguments;
  final String result;
  const ToolExecution({
    required this.name,
    required this.arguments,
    required this.result,
  });
}

/// Result of a multi-round tool-calling conversation — carries the model's
/// final text reply plus every tool it called along the way.
@immutable
class ChatResult {
  /// The model's final text reply after all tool calls are resolved.
  final String reply;

  /// Every tool the model called during this conversation, in order.
  final List<ToolExecution> executions;

  /// True if the conversation failed (network, parse error, max rounds).
  final bool failed;

  const ChatResult({
    required this.reply,
    this.executions = const [],
    this.failed = false,
  });

  static const empty = ChatResult(reply: '', failed: true);
}

/// Callback that executes a tool call and returns the result string the
/// model will see on the next round.
typedef ToolExecutor = Future<String> Function(
    String name, Map<String, dynamic> arguments);

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
  ///
  /// [history] carries previous conversation turns as
  /// `[{'role': 'user'|'assistant', 'content': '...'}]` maps — the Mistral
  /// chat-completions API sends them as-is ahead of the current turn, giving
  /// the model multi-turn memory. Each entry is a plain {role, content}
  /// object; system messages use `systemPrompt` instead.
  ///
  /// [systemPrompt] becomes a `role: 'system'` message prepended to the
  /// conversation — separate from user/assistant turns, which is how the
  /// OpenAI-compatible API expects persistent instructions.
  static Future<Map<String, dynamic>> completeJson({
    required String apiKey,
    required String model,
    required String prompt,
    Uint8List? imageBytes,
    String? imageMime,
    List<Map<String, String>>? history,
    String? systemPrompt,
    // Defaults to background (bulk screenshot tagging) — callers waiting on
    // a person in the UI, like the chat assistant, should pass interactive
    // so they don't queue behind a big tagging backlog. See
    // RequestPriority's doc for why this doesn't risk the real rate limit.
    RequestPriority priority = RequestPriority.background,
  }) {
    final historyTokens = history
            ?.fold<int>(0, (sum, m) => sum + (m['content']?.length ?? 0)) ??
        0;
    final systemTokens = systemPrompt?.length ?? 0;
    final estimatedTokens = _estimateTokens(prompt,
            hasImage: imageBytes != null) +
        (historyTokens / 4).ceil() +
        (systemTokens / 4).ceil();
    return _queueFor(model).run(
      estimatedTokens,
      () => _completeJsonNow(
        apiKey: apiKey,
        model: model,
        prompt: prompt,
        imageBytes: imageBytes,
        imageMime: imageMime,
        history: history,
        systemPrompt: systemPrompt,
      ),
      priority: priority,
    );
  }

  static Future<Map<String, dynamic>> _completeJsonNow({
    required String apiKey,
    required String model,
    required String prompt,
    Uint8List? imageBytes,
    String? imageMime,
    List<Map<String, String>>? history,
    String? systemPrompt,
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

        final messages = <Map<String, dynamic>>[];
        if (systemPrompt != null && systemPrompt.isNotEmpty) {
          messages.add({'role': 'system', 'content': systemPrompt});
        }
        if (history != null) {
          messages.addAll(history);
        }
        messages.add({'role': 'user', 'content': content});

        final response = await http
            .post(
              Uri.parse(_endpoint),
              headers: {
                'Authorization': 'Bearer $apiKey',
                'Content-Type': 'application/json',
              },
              body: jsonEncode({
                'model': model,
                'messages': messages,
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

  // ── Tool-calling conversation loop ──

  /// Multi-round tool-calling conversation — sends messages with tool
  /// definitions, executes tool calls the model requests via [executor],
  /// feeds results back, and loops until the model responds with text or
  /// [maxRounds] is hit. Each round is independently rate-limited.
  ///
  /// Unlike [completeJson], this does NOT force JSON output mode — the model
  /// replies in free-form text when it's done calling tools, which is what a
  /// conversational assistant needs.
  static Future<ChatResult> chatWithTools({
    required String apiKey,
    required String model,
    required List<Map<String, dynamic>> messages,
    required List<Map<String, dynamic>> tools,
    required ToolExecutor executor,
    RequestPriority priority = RequestPriority.interactive,
    int maxRounds = 5,
  }) async {
    final executions = <ToolExecution>[];
    final conversation = List<Map<String, dynamic>>.from(messages);

    for (var round = 0; round < maxRounds; round++) {
      final estimatedTokens =
          _estimateMessagesTokens(conversation, tools);
      final rawResponse = await _queueFor(model).run(
        estimatedTokens,
        () => _chatRoundNow(
          apiKey: apiKey,
          model: model,
          messages: conversation,
          tools: tools,
        ),
        priority: priority,
      );

      if (rawResponse == null) {
        return ChatResult(
          reply: 'Something went wrong reaching the AI — try again in '
              'a moment.',
          executions: executions,
          failed: true,
        );
      }

      final message = _extractAssistantMessage(rawResponse);
      if (message == null) {
        return ChatResult(
          reply: 'Got an unexpected response from the AI.',
          executions: executions,
          failed: true,
        );
      }

      final toolCalls = message['tool_calls'] as List?;
      if (toolCalls == null || toolCalls.isEmpty) {
        // Model responded with text — conversation is done.
        final content = (message['content'] as String?)?.trim() ?? '';
        return ChatResult(
          reply: content.isEmpty ? "Here's what I found." : content,
          executions: executions,
        );
      }

      // Append the assistant's tool-calling message to the conversation
      conversation.add(Map<String, dynamic>.from(message));

      // Execute each tool call and feed results back
      for (final call in toolCalls) {
        final callMap = call as Map<String, dynamic>;
        final id = callMap['id'] as String? ?? '';
        final function =
            callMap['function'] as Map<String, dynamic>? ?? {};
        final name = function['name'] as String? ?? '';
        final argsStr = function['arguments'] as String? ?? '{}';

        Map<String, dynamic> args;
        try {
          args = jsonDecode(argsStr) as Map<String, dynamic>;
        } catch (_) {
          args = {};
        }

        String result;
        try {
          result = await executor(name, args);
        } catch (e) {
          debugPrint('MistralClient: tool executor failed for $name: $e');
          DiagnosticLog.error(
              'MistralClient: tool "$name" execution failed — $e');
          result = jsonEncode({'error': 'Tool execution failed: $e'});
        }

        executions.add(
            ToolExecution(name: name, arguments: args, result: result));
        conversation.add({
          'role': 'tool',
          'tool_call_id': id,
          'name': name,
          'content': result,
        });
      }
    }

    // Exhausted maxRounds — model kept calling tools without a final reply.
    return ChatResult(
      reply: 'I took too many steps trying to answer that — here\'s '
          'what I found so far.',
      executions: executions,
      failed: true,
    );
  }

  /// One HTTP round-trip for tool calling — no response_format constraint,
  /// tools included in the payload. Returns the raw parsed response body,
  /// or null on failure.
  static Future<Map<String, dynamic>?> _chatRoundNow({
    required String apiKey,
    required String model,
    required List<Map<String, dynamic>> messages,
    required List<Map<String, dynamic>> tools,
  }) async {
    const maxAttempts = 3;
    for (var attempt = 1; attempt <= maxAttempts; attempt++) {
      try {
        final body = <String, dynamic>{
          'model': model,
          'messages': messages,
        };
        if (tools.isNotEmpty) {
          body['tools'] = tools;
          body['tool_choice'] = 'auto';
        }

        final response = await http
            .post(
              Uri.parse(_endpoint),
              headers: {
                'Authorization': 'Bearer $apiKey',
                'Content-Type': 'application/json',
              },
              body: jsonEncode(body),
            )
            .timeout(const Duration(seconds: 45));

        if (response.statusCode == 429 && attempt < maxAttempts) {
          final wait = Duration(seconds: 5 * attempt);
          debugPrint('MistralClient: rate-limited (attempt $attempt/'
              '$maxAttempts) — retrying in ${wait.inSeconds}s.');
          DiagnosticLog.warn(
              'MistralClient: rate-limited despite queueing — retrying '
              'in ${wait.inSeconds}s (attempt $attempt/$maxAttempts).');
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
          return null;
        }

        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) return decoded;
        DiagnosticLog.warn(
            'MistralClient: chat round response was not an object.');
        return null;
      } catch (e) {
        debugPrint('MistralClient: chat round failed: $e');
        DiagnosticLog.error('MistralClient: chat round failed — $e');
        return null;
      }
    }
    return null;
  }

  /// Extracts the assistant message from a raw chat-completions response.
  static Map<String, dynamic>? _extractAssistantMessage(
      Map<String, dynamic> response) {
    final choices = response['choices'];
    if (choices is! List || choices.isEmpty) return null;
    final firstChoice = choices.first;
    if (firstChoice is! Map) return null;
    final message = firstChoice['message'];
    if (message is! Map) return null;
    return Map<String, dynamic>.from(message);
  }

  /// Rough token estimate for a full message list + tool definitions —
  /// used to gate admission through the rate-limiting queue.
  static int _estimateMessagesTokens(
    List<Map<String, dynamic>> messages,
    List<Map<String, dynamic>> tools,
  ) {
    var chars = 0;
    for (final m in messages) {
      final content = m['content'];
      if (content is String) {
        chars += content.length;
      } else if (content is List) {
        for (final part in content) {
          if (part is Map && part['type'] == 'text') {
            chars += (part['text'] as String? ?? '').length;
          }
        }
      }
    }
    // Tool definitions add ~200 tokens worth of schema overhead each.
    chars += tools.length * 800;
    return (chars / 4).ceil();
  }
}
