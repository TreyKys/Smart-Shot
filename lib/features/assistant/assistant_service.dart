import 'package:flutter/foundation.dart';
import 'package:sift/core/ai/mistral_client.dart';
import 'package:sift/core/ai/rate_limited_queue.dart';
import 'package:sift/core/config/shared_key_service.dart';
import 'package:sift/core/diagnostics/diagnostic_log.dart';

// Upgraded from ministral-8b-2512 to mistral-small-2603: a much more capable
// model that understands compound requests ("find my receipts from March and
// delete the junk ones"), follows up on previous conversation context, and
// produces better replies. At 0.83 rps (1.2s between requests) this is still
// fast enough for interactive chat — the 8B model was faster but couldn't
// reason through anything beyond single-step intent mapping. Tagging stays on
// ministral-8b-2512 (bulk throughput matters there, reasoning doesn't).
const String _kAssistantModel = 'mistral-small-2603';

enum AssistantIntent {
  search,
  count,
  delete,
  addToCollection,
  createCollection,
  help,
  unclear,
}

AssistantIntent _parseIntent(String? raw) {
  switch (raw) {
    case 'search':
      return AssistantIntent.search;
    case 'count':
      return AssistantIntent.count;
    case 'delete':
      return AssistantIntent.delete;
    case 'add_to_collection':
      return AssistantIntent.addToCollection;
    case 'create_collection':
      return AssistantIntent.createCollection;
    case 'help':
      return AssistantIntent.help;
    default:
      return AssistantIntent.unclear;
  }
}

/// One turn's structured plan — what the user's message means to do, and the
/// criteria to match screenshots against. Matching and execution both happen
/// entirely on-device (see AssistantScreen); this class only carries what the
/// model extracted from the sentence.
@immutable
class AssistantPlan {
  final AssistantIntent intent;
  final List<String> tags;
  final List<String> keywords;
  final String? collectionName;
  final DateTime? dateFrom;
  final DateTime? dateTo;
  final String reply;

  const AssistantPlan({
    required this.intent,
    required this.tags,
    required this.keywords,
    required this.collectionName,
    required this.dateFrom,
    required this.dateTo,
    required this.reply,
  });

  static const unavailable = AssistantPlan(
    intent: AssistantIntent.unclear,
    tags: [],
    keywords: [],
    collectionName: null,
    dateFrom: null,
    dateTo: null,
    reply: 'No AI key is available right now — add one in Settings, or try '
        'again once the shared key is reachable.',
  );

  static const failed = AssistantPlan(
    intent: AssistantIntent.unclear,
    tags: [],
    keywords: [],
    collectionName: null,
    dateFrom: null,
    dateTo: null,
    reply: 'Something went wrong reaching the AI — try again in a moment.',
  );
}

/// Turns one chat message into a structured [AssistantPlan], with full
/// conversation history so the model can handle follow-ups ("now delete
/// those", "add them to Taxes").
///
/// Deliberately never sees screenshot images or full OCR text — only the
/// message plus the tag/collection names already in use — so this call stays
/// small and cheap. Matching against actual screenshots happens locally,
/// against fields every screenshot already has from the normal tagging
/// pipeline (tags, topic, cleanText, dates); this service's only job is
/// mapping a sentence onto that filter shape.
class AssistantService {
  /// Conversation history for multi-turn context — each entry is a user or
  /// assistant message from the current chat session. Capped at the most
  /// recent turns to keep the prompt within token limits.
  final List<Map<String, String>> _history = [];

  /// Maximum number of history turns (user + assistant pairs) to keep — each
  /// pair is two entries. 10 pairs = 20 messages, which is plenty of
  /// conversational context without blowing up token costs.
  static const int _maxHistoryPairs = 10;

  void _addToHistory(String role, String content) {
    _history.add({'role': role, 'content': content});
    // Trim to most recent turns, keeping pairs intact
    while (_history.length > _maxHistoryPairs * 2) {
      _history.removeAt(0);
    }
  }

  /// Clears conversation history — call when the chat is reset.
  void clearHistory() => _history.clear();

  Future<AssistantPlan> plan(
    String message, {
    required List<String> availableTags,
    required List<String> availableCollections,
    required int totalScreenshots,
    String? byokApiKey,
  }) async {
    final hasByok = byokApiKey != null &&
        byokApiKey.isNotEmpty &&
        byokApiKey != 'INSERT_API_KEY_HERE';
    final apiKey = hasByok ? byokApiKey : SharedKeyService.apiKey;
    if (apiKey.isEmpty) {
      DiagnosticLog.warn('AssistantService: no API key available — skipping.');
      return AssistantPlan.unavailable;
    }

    // System prompt — persistent instructions separated from the
    // conversation, which the OpenAI-compatible API handles as a
    // role: 'system' message ahead of the user/assistant turns.
    final systemPrompt = '''
You are Sift AI, the smart assistant inside Sift — a screenshot gallery app. You help users find, organise, count, and clean up their screenshot library using natural language.

You're conversational, helpful, and concise. You can reference what was discussed earlier in the conversation to understand follow-up requests like "now delete those" or "put them in a collection called Work."

CAPABILITIES:
- "search" — find screenshots matching a description
- "count" — report how many screenshots match
- "delete" — remove matching screenshots (the app always confirms first)
- "add_to_collection" — file matching screenshots into a named collection
- "create_collection" — make a new empty collection
- "help" — explain what you can do

CONTEXT:
- Library has $totalScreenshots screenshot${totalScreenshots == 1 ? '' : 's'}
- Tags in use: ${availableTags.isEmpty ? '(none yet — screenshots haven\'t been tagged)' : availableTags.join(', ')}
- Collections: ${availableCollections.isEmpty ? '(none yet)' : availableCollections.join(', ')}

RULES:
1. Only use tag names from the tags list above — NEVER invent tags. Put freeform descriptions in "keywords" instead.
2. For follow-ups referencing earlier results ("those", "them", "the ones you found"), use the same tags/keywords from your previous response so the app finds the same screenshots.
3. Think about what the user actually wants. "Show me receipts" → search. "How many memes?" → count. "Get rid of junk" → delete. "Put receipts in Taxes" → add_to_collection.
4. If the user asks something conversational ("thanks", "hello", "what can you do?"), use intent "help" and write a friendly reply.
5. The "reply" field should be natural and conversational — not a restatement of the JSON fields. Be brief but warm.

Respond with ONLY a single JSON object:
{
  "intent": "search" | "count" | "delete" | "add_to_collection" | "create_collection" | "help",
  "tags": ["#Tag1", "#Tag2"] or null,
  "keywords": ["receipt", "uber"] or null,
  "collectionName": "Taxes" or null,
  "dateFrom": "YYYY-MM-DD" or null,
  "dateTo": "YYYY-MM-DD" or null,
  "reply": "Here are your receipts from March!"
}''';

    // Add the user's message to history BEFORE sending, so the model sees
    // its own prior responses leading up to this new message.
    _addToHistory('user', message);

    final callStarted = DateTime.now();
    final map = await MistralClient.completeJson(
      apiKey: apiKey,
      model: _kAssistantModel,
      systemPrompt: systemPrompt,
      prompt: message,
      history: _history.length > 1
          ? _history.sublist(0, _history.length - 1)
          : null,
      priority: RequestPriority.interactive,
    );
    final elapsed = DateTime.now().difference(callStarted);
    if (elapsed > const Duration(seconds: 5)) {
      DiagnosticLog.warn(
          'AssistantService: MistralClient.completeJson took '
          '${elapsed.inSeconds}s (model=$_kAssistantModel).');
    }
    if (map.isEmpty) {
      // Remove the user message from history if the call failed — the model
      // never saw it, so keeping it would create a gap.
      _history.removeLast();
      return AssistantPlan.failed;
    }

    final intent = _parseIntent(map['intent'] as String?);
    DiagnosticLog.info('AssistantService: intent="${map['intent']}"');
    final replyText = (map['reply'] as String?)?.trim();
    final plan = AssistantPlan(
      intent: intent,
      tags: (map['tags'] as List?)?.whereType<String>().toList() ?? const [],
      keywords:
          (map['keywords'] as List?)?.whereType<String>().toList() ?? const [],
      collectionName: (map['collectionName'] as String?)?.trim(),
      dateFrom: DateTime.tryParse(map['dateFrom'] as String? ?? ''),
      dateTo: DateTime.tryParse(map['dateTo'] as String? ?? ''),
      reply: (replyText?.isNotEmpty ?? false)
          ? replyText!
          : "Here's what I found.",
    );

    // Add the assistant's response to history — the reply is the
    // conversational part the model should remember, not the raw JSON.
    _addToHistory('assistant', plan.reply);

    return plan;
  }
}
