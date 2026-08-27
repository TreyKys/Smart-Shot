import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:sift/core/config/shared_key_service.dart';
import 'package:sift/core/diagnostics/diagnostic_log.dart';

const String _kAssistantModel = 'gemini-2.5-flash';

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

  static const empty = AssistantPlan(
    intent: AssistantIntent.unclear,
    tags: [],
    keywords: [],
    collectionName: null,
    dateFrom: null,
    dateTo: null,
    reply: "I didn't quite catch that — try asking to find, delete, or "
        'collect screenshots by what they contain.',
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
    final apiKey = hasByok ? byokApiKey : SharedKeyService.geminiApiKey;
    if (apiKey.isEmpty) {
      DiagnosticLog.warn('AssistantService: no API key available — skipping.');
      return AssistantPlan.unavailable;
    }

    final schema = Schema.object(
      properties: {
        'intent': Schema.enumString(enumValues: [
          'search',
          'count',
          'delete',
          'add_to_collection',
          'create_collection',
          'unclear',
        ]),
        'tags': Schema.array(
          items: Schema.string(),
          nullable: true,
          description: 'Subset of the tags list below that match the '
              'request. Never invent a tag not already in that list.',
        ),
        'keywords': Schema.array(
          items: Schema.string(),
          nullable: true,
          description: 'Free-text words to match against a screenshot\'s '
              'topic or extracted text — names, places, receipts, anything '
              'not covered by an existing tag.',
        ),
        'collectionName': Schema.string(nullable: true),
        'dateFrom': Schema.string(
            nullable: true,
            description: 'ISO 8601 date (YYYY-MM-DD), if a time range was '
                'mentioned ("last week", "in March").'),
        'dateTo': Schema.string(nullable: true, description: 'ISO 8601 date.'),
        'reply': Schema.string(
            description: 'A short, friendly reply to show the user — refer '
                'to what was matched in plain language, not the raw '
                'criteria.'),
      },
      requiredProperties: ['intent', 'reply'],
    );

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
''';

    try {
      final model = GenerativeModel(
        model: _kAssistantModel,
        apiKey: apiKey,
        generationConfig: GenerationConfig(
          responseMimeType: 'application/json',
          responseSchema: schema,
        ),
      );
      final response =
          await model.generateContent([Content.text('$prompt\nUser: $message')]);
      final text = response.text;
      if (text == null || text.trim().isEmpty) {
        DiagnosticLog.warn('AssistantService: empty response.');
        return AssistantPlan.empty;
      }
      final decoded = jsonDecode(text.trim());
      if (decoded is! Map) return AssistantPlan.empty;
      final map = Map<String, dynamic>.from(decoded);
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
        reply: (replyText?.isNotEmpty ?? false) ? replyText! : "Here's what I found.",
      );
    } catch (e) {
      debugPrint('AssistantService: call failed: $e');
      DiagnosticLog.error('AssistantService: call failed — $e');
      return AssistantPlan.failed;
    }
  }
}
