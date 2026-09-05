import 'package:flutter/foundation.dart';
import 'package:sift/core/ai/mistral_client.dart';
import 'package:sift/core/ai/rate_limited_queue.dart';
import 'package:sift/core/config/shared_key_service.dart';
import 'package:sift/core/diagnostics/diagnostic_log.dart';

// Same model as LLMService's screenshot tagging — one fewer thing to keep in
// sync if Mistral changes naming, and this call is small (a sentence plus a
// short tag/collection list) so the vision-capable tier costs nothing extra
// here even though no image is ever sent.
const String _kAssistantModel = 'ministral-8b-2512';

enum AssistantIntent {
  search,
  count,
  delete,
  addToCollection,
  createCollection,
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

/// Turns one chat message into a structured [AssistantPlan].
///
/// Deliberately never sees screenshot images or full OCR text — only the
/// message plus the tag/collection names already in use — so this call stays
/// small and cheap. Matching against actual screenshots happens locally,
/// against fields every screenshot already has from the normal tagging
/// pipeline (tags, topic, cleanText, dates); this service's only job is
/// mapping a sentence onto that filter shape.
class AssistantService {
  Future<AssistantPlan> plan(
    String message, {
    required List<String> availableTags,
    required List<String> availableCollections,
    String? byokApiKey,
  }) async {
    final hasByok = byokApiKey != null &&
        byokApiKey.isNotEmpty &&
        byokApiKey != 'INSERT_API_KEY_HERE';
    // Dart's flow analysis promotes byokApiKey to String here — hasByok was
    // assigned directly from a `byokApiKey != null && ...` expression, which
    // it tracks through the ternary condition below.
    final apiKey = hasByok ? byokApiKey : SharedKeyService.apiKey;
    if (apiKey.isEmpty) {
      DiagnosticLog.warn('AssistantService: no API key available — skipping.');
      return AssistantPlan.unavailable;
    }

    final prompt = '''
You are Sift's gallery assistant. The user is talking to you about
screenshots already organised in their phone gallery app. Turn their message
into ONE structured action.

Tags already in use: ${availableTags.isEmpty ? '(none yet)' : availableTags.join(', ')}
Collections already created: ${availableCollections.isEmpty ? '(none yet)' : availableCollections.join(', ')}

Pick "search" to find screenshots, "count" to just report how many match,
"delete" to remove matching screenshots, "add_to_collection" to file matching
screenshots into a named collection, "create_collection" to make a new empty
collection with no screenshots yet, or "unclear" if the request doesn't map
to any of these — deleting and adding to a collection are always confirmed by
the app before anything happens, so pick them whenever that is what the user
is asking for.

Only use tag names from the list above in "tags" — never invent one that
isn't already in use. Put anything else the user described (a receipt, a
name, a place, a topic) in "keywords" instead.

Respond with ONLY a single JSON object — no markdown, no code fences, no text
before or after it. Use exactly this shape:
{
  "intent": "search" or "count" or "delete" or "add_to_collection" or "create_collection" or "unclear",
  "tags": [<strings, from the tags list above>] or null,
  "keywords": [<free-text strings>] or null,
  "collectionName": <string, or null>,
  "dateFrom": <"YYYY-MM-DD", or null — only if a time range was mentioned>,
  "dateTo": <"YYYY-MM-DD", or null>,
  "reply": <a short, friendly reply to show the user — plain language, not the raw criteria>
}

User: $message
''';

    final callStarted = DateTime.now();
    final map = await MistralClient.completeJson(
      apiKey: apiKey,
      model: _kAssistantModel,
      prompt: prompt,
      // A person is waiting on this one — it must not queue behind a big
      // background tagging batch on the same model's shared queue.
      priority: RequestPriority.interactive,
    );
    final elapsed = DateTime.now().difference(callStarted);
    if (elapsed > const Duration(seconds: 5)) {
      // Anything past a couple seconds here is worth knowing about even on
      // success — RateLimitedQueue only logs a slow *wait*, so a call that
      // cleared admission quickly but the HTTP round trip itself was slow
      // wouldn't otherwise show up anywhere.
      DiagnosticLog.warn(
          'AssistantService: MistralClient.completeJson took '
          '${elapsed.inSeconds}s (model=$_kAssistantModel).');
    }
    if (map.isEmpty) return AssistantPlan.failed;

    final intent = _parseIntent(map['intent'] as String?);
    DiagnosticLog.info('AssistantService: intent="${map['intent']}"');
    final replyText = (map['reply'] as String?)?.trim();
    return AssistantPlan(
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
  }
}
