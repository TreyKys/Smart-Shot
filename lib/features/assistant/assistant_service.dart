import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:sift/core/ai/mistral_client.dart';
import 'package:sift/core/ai/rate_limited_queue.dart';
import 'package:sift/core/config/shared_key_service.dart';
import 'package:sift/core/diagnostics/diagnostic_log.dart';
import 'package:sift/features/gallery/domain/screenshot.dart';

// Upgraded from ministral-8b-2512 to mistral-small-2603: a much more capable
// model that supports function/tool calling, understands compound requests
// ("find my receipts from March and delete the junk ones"), and can reason
// through multi-step plans. Each turn can involve multiple tool calls — the
// model searches, counts, or proposes actions, sees the results, and decides
// what to do next — instead of being limited to single-shot intent mapping.
// Tagging stays on ministral-8b-2512 (bulk throughput matters there, not
// multi-step reasoning).
const String _kAssistantModel = 'mistral-small-2603';

/// Types of actions that require explicit user confirmation before executing.
enum PendingActionType { delete, addToCollection, createCollection }

/// A destructive or filing action the model proposed — held until the user
/// confirms via the chat UI. Never auto-executed: the model calls a
/// `propose_*` tool, which records this and returns "pending_confirmation"
/// so the model's reply can explain what it wants to do without actually
/// doing it.
@immutable
class PendingAction {
  final PendingActionType type;
  final List<Screenshot> targets;
  final String? collectionName;
  const PendingAction({
    required this.type,
    required this.targets,
    this.collectionName,
  });
}

/// The full result of one chat turn — everything the UI needs to render.
@immutable
class AssistantResult {
  /// The model's conversational reply text.
  final String reply;

  /// Screenshots the model found/referenced (search results, deletion
  /// targets, etc.) — for the thumbnail strip in the chat bubble.
  final List<Screenshot> screenshots;

  /// Tags the model matched against, for display as chips.
  final List<String> highlightTags;

  /// If set, the model proposed an action that needs user confirmation.
  final PendingAction? pendingAction;

  /// True if the call failed entirely (no key, network, timeout).
  final bool failed;

  const AssistantResult({
    required this.reply,
    this.screenshots = const [],
    this.highlightTags = const [],
    this.pendingAction,
    this.failed = false,
  });

  static const unavailable = AssistantResult(
    reply: 'No AI key is available right now — add one in Settings, or try '
        'again once the shared key is reachable.',
    failed: true,
  );

  static const failedResult = AssistantResult(
    reply: 'Something went wrong reaching the AI — try again in a moment.',
    failed: true,
  );
}

/// Multi-step tool-calling assistant — the model receives tool definitions
/// for searching, counting, deleting, and organising screenshots, calls them
/// as needed (seeing real results between calls), and then writes a natural
/// conversational reply. This replaces the old single-shot JSON-extraction
/// approach with genuine multi-turn reasoning: "find my receipts from March
/// and add the Uber ones to Taxes" becomes search → filter → propose, all
/// in one user turn.
///
/// Every tool executes entirely on-device against fields each screenshot
/// already has from the normal tagging pipeline (tags, topic, cleanText,
/// ocrText, timestamp). The model never sees screenshot images or full OCR
/// text — only summaries of what matched — so the calls stay small and
/// cheap.
class AssistantService {
  /// Conversation history for multi-turn context — each entry is a user or
  /// assistant message from the current chat session. Capped at the most
  /// recent turns to keep the prompt within token limits.
  final List<Map<String, String>> _history = [];

  /// Maximum number of history turns (user + assistant pairs) to keep — each
  /// pair is two entries. 10 pairs = 20 messages, which is plenty of
  /// conversational context without blowing up token costs.
  static const int _maxHistoryPairs = 10;

  // ── Per-turn state, reset at the start of each chat() call ──

  /// Screenshots from the most recent search/count/propose tool call.
  List<Screenshot>? _lastSearchResults;

  /// Tags the model filtered by, for the highlight-chip strip.
  List<String> _highlightTags = [];

  /// The pending confirmation action, if the model called a propose_* tool.
  PendingAction? _pendingAction;

  void _addToHistory(String role, String content) {
    _history.add({'role': role, 'content': content});
    // Trim to most recent turns, keeping pairs intact
    while (_history.length > _maxHistoryPairs * 2) {
      _history.removeAt(0);
    }
  }

  /// Clears conversation history — call when the chat is reset.
  void clearHistory() {
    _history.clear();
    _lastSearchResults = null;
    _highlightTags = [];
    _pendingAction = null;
  }

  // ── Tool definitions ──

  /// Mistral function-calling tool definitions — each describes one
  /// capability the model can invoke during a conversation turn.
  static final List<Map<String, dynamic>> _toolDefinitions = [
    {
      'type': 'function',
      'function': {
        'name': 'search_screenshots',
        'description':
            'Search the user\'s screenshot library. Returns matching '
                'screenshots with their details (topic, tags, date). Use this '
                'to find screenshots by tags, keywords, or date range.',
        'parameters': {
          'type': 'object',
          'properties': {
            'tags': {
              'type': 'array',
              'items': {'type': 'string'},
              'description':
                  'Tag names to filter by (e.g. ["#Receipt", "#Meme"]). '
                      'Only use tags from the known tags list.',
            },
            'keywords': {
              'type': 'array',
              'items': {'type': 'string'},
              'description':
                  'Freeform search terms matched against topic, text '
                      'content, and OCR (e.g. ["uber", "march"]).',
            },
            'date_from': {
              'type': 'string',
              'description': 'Start date filter in YYYY-MM-DD format.',
            },
            'date_to': {
              'type': 'string',
              'description': 'End date filter in YYYY-MM-DD format.',
            },
          },
        },
      },
    },
    {
      'type': 'function',
      'function': {
        'name': 'count_screenshots',
        'description':
            'Count screenshots matching the given criteria without '
                'returning full details. Faster than search for "how many" '
                'questions.',
        'parameters': {
          'type': 'object',
          'properties': {
            'tags': {
              'type': 'array',
              'items': {'type': 'string'},
              'description': 'Tag names to filter by.',
            },
            'keywords': {
              'type': 'array',
              'items': {'type': 'string'},
              'description': 'Freeform search terms.',
            },
            'date_from': {
              'type': 'string',
              'description': 'Start date in YYYY-MM-DD.',
            },
            'date_to': {
              'type': 'string',
              'description': 'End date in YYYY-MM-DD.',
            },
          },
        },
      },
    },
    {
      'type': 'function',
      'function': {
        'name': 'propose_delete',
        'description':
            'Propose deleting screenshots that match the given criteria. '
                'The user will be asked to confirm before anything is actually '
                'deleted. Always search first to know what will be affected.',
        'parameters': {
          'type': 'object',
          'properties': {
            'tags': {
              'type': 'array',
              'items': {'type': 'string'},
              'description': 'Tag names to filter by.',
            },
            'keywords': {
              'type': 'array',
              'items': {'type': 'string'},
              'description': 'Freeform search terms.',
            },
            'date_from': {
              'type': 'string',
              'description': 'Start date in YYYY-MM-DD.',
            },
            'date_to': {
              'type': 'string',
              'description': 'End date in YYYY-MM-DD.',
            },
          },
        },
      },
    },
    {
      'type': 'function',
      'function': {
        'name': 'propose_add_to_collection',
        'description':
            'Propose adding matching screenshots to a named collection. '
                'The user will confirm before anything happens. The collection '
                'is created automatically if it doesn\'t exist yet.',
        'parameters': {
          'type': 'object',
          'properties': {
            'collection_name': {
              'type': 'string',
              'description':
                  'Name of the collection to add screenshots to.',
            },
            'tags': {
              'type': 'array',
              'items': {'type': 'string'},
              'description': 'Tag names to filter by.',
            },
            'keywords': {
              'type': 'array',
              'items': {'type': 'string'},
              'description': 'Freeform search terms.',
            },
            'date_from': {
              'type': 'string',
              'description': 'Start date in YYYY-MM-DD.',
            },
            'date_to': {
              'type': 'string',
              'description': 'End date in YYYY-MM-DD.',
            },
          },
          'required': ['collection_name'],
        },
      },
    },
    {
      'type': 'function',
      'function': {
        'name': 'create_collection',
        'description':
            'Create a new empty collection. The user will confirm the '
                'name first.',
        'parameters': {
          'type': 'object',
          'properties': {
            'name': {
              'type': 'string',
              'description': 'Name for the new collection.',
            },
          },
          'required': ['name'],
        },
      },
    },
  ];

  // ── System prompt ──

  static String _systemPrompt({
    required int totalScreenshots,
    required List<String> availableTags,
    required List<String> availableCollections,
  }) =>
      '''
You are Sift AI, the smart assistant inside Sift — a screenshot gallery app. You help users find, organise, count, and clean up their screenshot library using natural language.

You're conversational, helpful, and concise. You have tools to search, count, delete, and organise screenshots. Use them to answer the user's request — you can call multiple tools in sequence to handle complex requests like "find my receipts from March and add the Uber ones to Taxes."

CONTEXT:
- Library has $totalScreenshots screenshot${totalScreenshots == 1 ? '' : 's'}
- Tags in use: ${availableTags.isEmpty ? '(none yet — screenshots haven\'t been tagged)' : availableTags.join(', ')}
- Collections: ${availableCollections.isEmpty ? '(none yet)' : availableCollections.join(', ')}

RULES:
1. Only use tag names from the tags list above — NEVER invent tags. Put freeform descriptions in "keywords" instead.
2. For follow-ups referencing earlier results ("those", "them", "the ones you found"), use the same search criteria from your previous tool calls.
3. Think step by step. For "find my receipts and delete the old ones" → first search_screenshots to find receipts, then propose_delete with a date filter for old ones.
4. For compound requests, call the tools you need in order — you'll see results between calls so you can adjust.
5. Always search or count BEFORE proposing delete — never delete blind.
6. If the user asks something conversational ("thanks", "hello", "what can you do?"), just reply directly without calling any tools.
7. Be natural and conversational in your final reply — brief but warm. Don't narrate what tools you called.''';

  // ── Filtering ──

  /// Runs entirely on-device against fields every screenshot already has —
  /// the same tags/topic/cleanText/ocrText/timestamp the normal tagging
  /// pipeline populates. Mirrors search_provider.dart's in-memory filtering
  /// approach rather than inventing a new matching strategy.
  List<Screenshot> _filterScreenshots(
    List<Screenshot> all,
    Map<String, dynamic> args,
  ) {
    Iterable<Screenshot> pool = all;

    final tags = (args['tags'] as List?)?.whereType<String>().toList();
    if (tags != null && tags.isNotEmpty) {
      final wanted =
          tags.map((t) => t.toLowerCase().replaceFirst('#', '')).toSet();
      pool = pool.where((s) => (s.tags ?? const []).any(
          (t) => wanted.contains(t.toLowerCase().replaceFirst('#', ''))));
      // Track which tags were used for highlight chips
      _highlightTags = tags;
    }

    final keywords =
        (args['keywords'] as List?)?.whereType<String>().toList();
    if (keywords != null && keywords.isNotEmpty) {
      pool = pool.where((s) {
        final combined = [
          s.topic ?? '',
          s.cleanText ?? '',
          s.ocrText ?? '',
          ...(s.tags ?? const []),
        ].join(' ').toLowerCase();
        return keywords.any((k) => combined.contains(k.toLowerCase()));
      });
    }

    final dateFrom =
        DateTime.tryParse(args['date_from'] as String? ?? '');
    if (dateFrom != null) {
      pool = pool.where((s) => !s.timestamp.isBefore(dateFrom));
    }

    final dateTo = DateTime.tryParse(args['date_to'] as String? ?? '');
    if (dateTo != null) {
      final toEnd = dateTo.add(const Duration(days: 1));
      pool = pool.where((s) => s.timestamp.isBefore(toEnd));
    }

    return pool.toList();
  }

  // ── Tool executor ──

  /// Executes one tool call from the model, returning the result string
  /// the model will see on the next round. Non-destructive tools (search,
  /// count) execute immediately and return real data. Destructive tools
  /// (propose_delete, propose_add_to_collection, create_collection) record
  /// a [PendingAction] and return "pending_confirmation" so the model can
  /// tell the user what it wants to do without actually doing it.
  Future<String> _executeTool(
    String name,
    Map<String, dynamic> args,
    List<Screenshot> allScreenshots,
  ) async {
    switch (name) {
      case 'search_screenshots':
        final results = _filterScreenshots(allScreenshots, args);
        _lastSearchResults = results;
        if (results.isEmpty) {
          return jsonEncode(
              {'count': 0, 'message': 'No screenshots matched.'});
        }
        // Return a summary the model can reason about — not full data.
        // 20 entries is enough for the model to understand the results
        // without bloating the context.
        final summaries = results.take(20).map((s) => {
              'id': s.id,
              'topic': s.topic ?? 'untitled',
              'tags': s.tags ?? <String>[],
              'date': s.timestamp.toIso8601String().substring(0, 10),
            }).toList();
        return jsonEncode({
          'count': results.length,
          'showing': summaries.length,
          'screenshots': summaries,
        });

      case 'count_screenshots':
        final results = _filterScreenshots(allScreenshots, args);
        _lastSearchResults = results;
        return jsonEncode({'count': results.length});

      case 'propose_delete':
        final results = _filterScreenshots(allScreenshots, args);
        if (results.isEmpty) {
          return jsonEncode({
            'status': 'no_matches',
            'message': 'Nothing matched the criteria to delete.',
          });
        }
        _lastSearchResults = results;
        _pendingAction = PendingAction(
          type: PendingActionType.delete,
          targets: results,
        );
        return jsonEncode({
          'status': 'pending_confirmation',
          'count': results.length,
          'message': 'The user will be asked to confirm deletion of '
              '${results.length} screenshot(s). Tell them what you found '
              'and that they\'ll need to confirm.',
        });

      case 'propose_add_to_collection':
        final collectionName =
            (args['collection_name'] as String?)?.trim();
        if (collectionName == null || collectionName.isEmpty) {
          return jsonEncode({
            'status': 'error',
            'message': 'No collection name provided.',
          });
        }
        final results = _filterScreenshots(allScreenshots, args);
        if (results.isEmpty) {
          return jsonEncode({
            'status': 'no_matches',
            'message': 'Nothing matched the criteria to add.',
          });
        }
        _lastSearchResults = results;
        _pendingAction = PendingAction(
          type: PendingActionType.addToCollection,
          targets: results,
          collectionName: collectionName,
        );
        return jsonEncode({
          'status': 'pending_confirmation',
          'count': results.length,
          'collection': collectionName,
          'message': 'The user will be asked to confirm adding '
              '${results.length} screenshot(s) to "$collectionName".',
        });

      case 'create_collection':
        final collectionName = (args['name'] as String?)?.trim();
        if (collectionName == null || collectionName.isEmpty) {
          return jsonEncode({
            'status': 'error',
            'message': 'No collection name provided.',
          });
        }
        _pendingAction = PendingAction(
          type: PendingActionType.createCollection,
          targets: const [],
          collectionName: collectionName,
        );
        return jsonEncode({
          'status': 'pending_confirmation',
          'collection': collectionName,
          'message': 'The user will be asked to confirm creating '
              'collection "$collectionName".',
        });

      default:
        return jsonEncode({'error': 'Unknown tool: $name'});
    }
  }

  // ── Main entry point ──

  /// Runs one chat turn — sends the user's message plus conversation history
  /// to the model with tool definitions, lets the model call tools as needed
  /// (seeing real results between calls), and returns the model's final
  /// conversational reply along with any screenshots it found and any
  /// pending action it proposed.
  Future<AssistantResult> chat(
    String message, {
    required List<Screenshot> allScreenshots,
    required List<String> availableTags,
    required List<String> availableCollections,
    String? byokApiKey,
  }) async {
    final hasByok = byokApiKey != null &&
        byokApiKey.isNotEmpty &&
        byokApiKey != 'INSERT_API_KEY_HERE';
    final apiKey = hasByok ? byokApiKey : SharedKeyService.apiKey;
    if (apiKey.isEmpty) {
      DiagnosticLog.warn('AssistantService: no API key available — skipping.');
      return AssistantResult.unavailable;
    }

    // Reset per-turn state
    _lastSearchResults = null;
    _highlightTags = [];
    _pendingAction = null;

    // Add the user's message to history BEFORE sending, so the model sees
    // its own prior responses leading up to this new message.
    _addToHistory('user', message);

    // Build the full message list: system prompt → history → current message
    final messages = <Map<String, dynamic>>[
      {
        'role': 'system',
        'content': _systemPrompt(
          totalScreenshots: allScreenshots.length,
          availableTags: availableTags,
          availableCollections: availableCollections,
        ),
      },
    ];
    // History — everything except the current message (which is last)
    if (_history.length > 1) {
      for (final h in _history.sublist(0, _history.length - 1)) {
        messages.add(Map<String, dynamic>.from(h));
      }
    }
    messages.add({'role': 'user', 'content': message});

    final callStarted = DateTime.now();
    final result = await MistralClient.chatWithTools(
      apiKey: apiKey,
      model: _kAssistantModel,
      messages: messages,
      tools: _toolDefinitions,
      executor: (name, args) => _executeTool(name, args, allScreenshots),
      priority: RequestPriority.interactive,
    );
    final elapsed = DateTime.now().difference(callStarted);
    DiagnosticLog.info(
        'AssistantService: chat completed in ${elapsed.inSeconds}s, '
        '${result.executions.length} tool call(s), failed=${result.failed}');
    if (elapsed > const Duration(seconds: 8)) {
      DiagnosticLog.warn(
          'AssistantService: chat took ${elapsed.inSeconds}s '
          '(model=$_kAssistantModel, rounds=${result.executions.length}).');
    }

    if (result.failed && result.reply.isEmpty) {
      // Remove the user message from history if the call failed — the model
      // never saw it, so keeping it would create a gap.
      _history.removeLast();
      return AssistantResult.failedResult;
    }

    // Store the assistant's reply in history — with a brief summary of what
    // tools were called, so the model can handle follow-ups like "now delete
    // those" by reusing the same search criteria it used last time.
    String historyEntry = result.reply;
    if (result.executions.isNotEmpty) {
      final toolSummary = result.executions
          .map((e) => '${e.name}(${jsonEncode(e.arguments)})')
          .join(', ');
      historyEntry = '[Tools used: $toolSummary]\n$historyEntry';
    }
    _addToHistory('assistant', historyEntry);

    return AssistantResult(
      reply: result.reply,
      screenshots: _lastSearchResults ?? [],
      highlightTags: List<String>.from(_highlightTags),
      pendingAction: _pendingAction,
    );
  }
}
