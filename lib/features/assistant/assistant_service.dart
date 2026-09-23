import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:sift/core/ai/mistral_client.dart';
import 'package:sift/core/ai/rate_limited_queue.dart';
import 'package:sift/core/config/shared_key_service.dart';
import 'package:sift/core/diagnostics/diagnostic_log.dart';
import 'package:sift/features/gallery/data/gallery_repository.dart';
import 'package:sift/features/gallery/domain/screenshot.dart';

// Back on ministral-8b-2512 — the same model tagging already uses — after
// mistral-small-2603 turned out to be the actual bottleneck behind the
// assistant's repeated 429s and dropped connections. Look at the two
// models' entries in mistral_rate_limits.dart: mistral-small-2603 allows
// 0.83 requests/sec and 50k tokens/min on the shared key; ministral-8b-2512
// allows 3.13 requests/sec and 625k tokens/min — roughly 4x and 12x more
// headroom on the exact same shared key every install of this app draws
// from. An 8B model is a real, current, tool-calling-capable model, not a
// toy — this isn't a quality downgrade to fix a reliability problem, it's
// the same model this app already trusts for every screenshot's tagging,
// now also handling chat.
const String _kAssistantModel = 'ministral-8b-2512';

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

  /// Snapshot of conversation history for persistence — the UI layer writes
  /// this to SharedPreferences so a restart resumes the same conversation
  /// the model was in the middle of.
  List<Map<String, String>> exportHistory() =>
      _history.map((h) => Map<String, String>.from(h)).toList();

  /// Restore a previously-exported history — inverse of [exportHistory].
  /// Overwrites whatever's currently in memory rather than merging; the UI
  /// only calls this once at startup, and mid-session merging would produce
  /// weirder conversation state than either half alone.
  void restoreHistory(List<Map<String, String>> saved) {
    _history
      ..clear()
      ..addAll(saved);
    _lastSearchResults = null;
    _highlightTags = [];
    _pendingAction = null;
  }

  /// Records the outcome of a pending action into the AI's history so the
  /// model actually knows what happened on its next turn — without this, the
  /// AI proposed a deletion, the user tapped Confirm (or replied "yes"
  /// affirmatively — see the screen's auto-confirm path), the deletion ran,
  /// and the next chat turn's AI had zero record any of that happened. On
  /// "have you deleted the rest" the model would then either say "no" (true
  /// only from its perspective) or hallucinate "already deleted". Either
  /// answer read as broken to the user. Now it sees an assistant-role note
  /// that says exactly what happened and can answer honestly.
  void recordActionOutcome(String note) {
    _addToHistory('assistant', '[$note]');
  }

  /// Labels shown to the user while a specific tool is running — replaces
  /// the generic "Thinking…" with something that describes what's actually
  /// happening (a `find_duplicates` on a large library is O(n²) and can
  /// take real time, and calling that "Thinking…" reads as "stuck").
  static const Map<String, String> _toolLabels = {
    'search_screenshots': 'Searching your library…',
    'count_screenshots': 'Counting matches…',
    'propose_delete': 'Preparing deletion…',
    'propose_add_to_collection': 'Preparing to file…',
    'create_collection': 'Preparing to create the collection…',
    'find_duplicates': 'Scanning for duplicates — this can take a moment…',
    'library_stats': 'Analyzing your library…',
    'find_untagged': 'Finding untagged screenshots…',
  };

  /// Human label for [toolName], or a generic fallback if we ever add a
  /// tool and forget to label it here.
  static String toolLabel(String toolName) =>
      _toolLabels[toolName] ?? 'Working on it…';

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
    {
      'type': 'function',
      'function': {
        'name': 'find_duplicates',
        'description':
            'Find groups of visually similar (near-duplicate) screenshots '
                'using perceptual hashing. Returns clusters of 2+ screenshots '
                'that look alike — useful for cleanup.',
        'parameters': {
          'type': 'object',
          'properties': {},
        },
      },
    },
    {
      'type': 'function',
      'function': {
        'name': 'library_stats',
        'description':
            'Get an overview of the screenshot library — total count, '
                'breakdown by tag, how many are processed vs unprocessed, and '
                'date range. Use for "how big is my library" or overview '
                'questions.',
        'parameters': {
          'type': 'object',
          'properties': {},
        },
      },
    },
    {
      'type': 'function',
      'function': {
        'name': 'find_untagged',
        'description':
            'Find screenshots that have no tags or haven\'t been processed '
                'yet. Useful for "what still needs tagging" questions.',
        'parameters': {
          'type': 'object',
          'properties': {
            'limit': {
              'type': 'integer',
              'description':
                  'Maximum number of untagged screenshots to return '
                      '(default 20).',
            },
          },
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
7. Be natural and conversational in your final reply — brief but warm. Don't narrate what tools you called.
8. NEVER say something was deleted, added, or changed unless a prior turn shows an explicit outcome note in brackets (e.g. "[The user confirmed and N screenshots were deleted]"). The `propose_*` tools only prepare an action — the user has to tap Confirm in the UI for it to actually run. If you already called `propose_delete` and the user is asking whether it happened, tell them honestly that they need to tap the Confirm/Delete button on your previous message, or reply "yes" / "delete them" to confirm. Do NOT re-call `propose_delete` for the same set — the previous proposal is still waiting.''';

  // ── Tool-call argument parsing ──
  //
  // The model's tool call comes back as a `Map<String, dynamic>` decoded from
  // JSON — every accessor is untyped and every entry may be absent. These
  // helpers extract the four filter fields (tags / keywords / date range)
  // once, so each tool case below reads as `tags: _tagsArg(args)` instead of
  // the same `whereType<String>().toList()` incantation six times over.

  static List<String>? _tagsArg(Map<String, dynamic> args) {
    final raw = (args['tags'] as List?)?.whereType<String>().toList();
    return (raw == null || raw.isEmpty) ? null : raw;
  }

  static List<String>? _keywordsArg(Map<String, dynamic> args) {
    final raw = (args['keywords'] as List?)?.whereType<String>().toList();
    return (raw == null || raw.isEmpty) ? null : raw;
  }

  static DateTime? _dateArg(dynamic v) =>
      v is String && v.isNotEmpty ? DateTime.tryParse(v) : null;

  // ── Tool executor ──

  /// Cap on rows any single tool materialises. Prevents "delete every
  /// screenshot with no tag on a 5,000-shot library" from pulling the whole
  /// table into memory just so the model can reason about it. 200 comfortably
  /// covers real requests without blowing the chat bubble's thumbnail strip
  /// up into an unusable wall — anyone wanting a bigger set should browse
  /// the Gallery view directly, which is what it's for.
  static const int _kResultCap = 200;

  /// Executes one tool call from the model, returning the result string
  /// the model will see on the next round. Non-destructive tools (search,
  /// count) execute immediately and return real data. Destructive tools
  /// (propose_delete, propose_add_to_collection, create_collection) record
  /// a [PendingAction] and return "pending_confirmation" so the model can
  /// tell the user what it wants to do without actually doing it.
  ///
  /// Every filter runs against Isar via [GalleryRepository]'s lazy query
  /// methods — the previous version took `List<Screenshot> allScreenshots`
  /// and filtered in Dart, which meant pulling every row (ocrText,
  /// cleanText, urls, phone numbers, dates, all populated) into memory
  /// each turn just so `_filterScreenshots` could throw most of them away.
  /// On a 3,000-shot library that was the assistant's real bottleneck.
  Future<String> _executeTool(
    String name,
    Map<String, dynamic> args,
    GalleryRepository gallery,
  ) async {
    switch (name) {
      case 'search_screenshots':
        final tags = _tagsArg(args);
        final keywords = _keywordsArg(args);
        final dateFrom = _dateArg(args['date_from']);
        final dateTo = _dateArg(args['date_to']);
        if (tags != null) _highlightTags = tags;
        final results = await gallery.queryScreenshots(
          tags: tags,
          keywords: keywords,
          dateFrom: dateFrom,
          dateTo: dateTo,
          limit: _kResultCap,
        );
        // Skip the extra COUNT walk when we already know the exact number
        // from the row list — only ambiguous when the limit clipped it.
        final total = results.length < _kResultCap
            ? results.length
            : await gallery.countScreenshots(
                tags: tags,
                keywords: keywords,
                dateFrom: dateFrom,
                dateTo: dateTo,
              );
        _lastSearchResults = results;
        if (total == 0) {
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
          'count': total,
          'showing': summaries.length,
          'screenshots': summaries,
        });

      case 'count_screenshots':
        final tags = _tagsArg(args);
        final keywords = _keywordsArg(args);
        final dateFrom = _dateArg(args['date_from']);
        final dateTo = _dateArg(args['date_to']);
        if (tags != null) _highlightTags = tags;
        final count = await gallery.countScreenshots(
          tags: tags,
          keywords: keywords,
          dateFrom: dateFrom,
          dateTo: dateTo,
        );
        // COUNT alone doesn't populate the thumbnail strip. If the user
        // follows up with "show me those", the model will call
        // search_screenshots and we'll materialise rows then — no reason to
        // eagerly load them here just because we might be asked next.
        _lastSearchResults = null;
        return jsonEncode({'count': count});

      case 'propose_delete':
        final tags = _tagsArg(args);
        final keywords = _keywordsArg(args);
        final dateFrom = _dateArg(args['date_from']);
        final dateTo = _dateArg(args['date_to']);
        if (tags != null) _highlightTags = tags;
        // Capped like search: if the user really wants to delete >200
        // screenshots in one go the model should propose narrower filters.
        final results = await gallery.queryScreenshots(
          tags: tags,
          keywords: keywords,
          dateFrom: dateFrom,
          dateTo: dateTo,
          limit: _kResultCap,
        );
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
        final tags = _tagsArg(args);
        final keywords = _keywordsArg(args);
        final dateFrom = _dateArg(args['date_from']);
        final dateTo = _dateArg(args['date_to']);
        if (tags != null) _highlightTags = tags;
        final results = await gallery.queryScreenshots(
          tags: tags,
          keywords: keywords,
          dateFrom: dateFrom,
          dateTo: dateTo,
          limit: _kResultCap,
        );
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

      case 'find_duplicates':
        final clusters = await gallery.findDuplicateClusters();
        if (clusters.isEmpty) {
          return jsonEncode({
            'cluster_count': 0,
            'message': 'No duplicate screenshots found — your library is clean!',
          });
        }
        // Flatten for thumbnail strip — show all duplicates
        final allDups = clusters.expand((c) => c).toList();
        _lastSearchResults = allDups;
        final summaries = clusters.take(10).map((group) => {
              'size': group.length,
              'screenshots': group.take(5).map((s) => {
                    'id': s.id,
                    'topic': s.topic ?? 'untitled',
                    'tags': s.tags ?? <String>[],
                    'date': s.timestamp.toIso8601String().substring(0, 10),
                  }).toList(),
            }).toList();
        return jsonEncode({
          'cluster_count': clusters.length,
          'total_duplicates':
              clusters.fold<int>(0, (sum, c) => sum + c.length),
          'showing_clusters': summaries.length,
          'clusters': summaries,
        });

      case 'library_stats':
        final stats = await gallery.libraryStats();
        final sortedTags = stats.tagCounts.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));
        return jsonEncode({
          'total': stats.total,
          'processed': stats.processed,
          'unprocessed': stats.unprocessed,
          'untagged': stats.untagged,
          'date_range': {
            'oldest': stats.oldest?.toIso8601String().substring(0, 10),
            'newest': stats.newest?.toIso8601String().substring(0, 10),
          },
          'tag_breakdown': {
            for (final e in sortedTags.take(20)) e.key: e.value,
          },
          'unique_tag_count': stats.tagCounts.length,
        });

      case 'find_untagged':
        final limit = (args['limit'] as int?) ?? 20;
        final untagged = await gallery.findUntagged(limit: limit);
        _lastSearchResults = untagged;
        if (untagged.isEmpty) {
          return jsonEncode({
            'count': 0,
            'message': 'All screenshots have tags — nothing to tag!',
          });
        }
        // Separate COUNT so the model can say "showing 20 of 143 untagged"
        // instead of pretending the shown page is the whole set.
        final total = await gallery.untaggedCount();
        final summaries = untagged.map((s) => {
              'id': s.id,
              'topic': s.topic ?? 'untitled',
              'date': s.timestamp.toIso8601String().substring(0, 10),
              'processed': s.isProcessed,
            }).toList();
        return jsonEncode({
          'count': total,
          'showing': summaries.length,
          'screenshots': summaries,
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
  ///
  /// [gallery] is queried lazily for every tool call rather than materialised
  /// once up front — see [_executeTool]'s doc for why "load everything, then
  /// filter" was the assistant's real bottleneck on big libraries.
  Future<AssistantResult> chat(
    String message, {
    required GalleryRepository gallery,
    required List<String> availableTags,
    required List<String> availableCollections,
    String? byokApiKey,
    // Fires when the model decides to call a specific tool — the UI uses
    // this to replace the generic "Thinking…" with a live label describing
    // what's actually happening ("Searching your library…", "Scanning for
    // duplicates…"). See [toolLabel] for the current mapping.
    void Function(String label)? onStage,
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

    // One cheap indexed COUNT for the system prompt — beats loading every
    // screenshot just to read `.length` on it.
    final totalScreenshots = await gallery.countScreenshots();

    // Build the full message list: system prompt → history → current message
    final messages = <Map<String, dynamic>>[
      {
        'role': 'system',
        'content': _systemPrompt(
          totalScreenshots: totalScreenshots,
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
      executor: (name, args) async {
        // Fire the stage callback BEFORE the tool actually runs, so the UI
        // updates the moment the model decides to call that tool — not
        // after the tool's result comes back. On a slow tool like
        // find_duplicates, waiting until after the run defeats the whole
        // point of showing progress.
        onStage?.call(toolLabel(name));
        return _executeTool(name, args, gallery);
      },
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
