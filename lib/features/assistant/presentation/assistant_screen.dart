import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sift/core/diagnostics/diagnostic_log.dart';
import 'package:sift/core/theme/app_theme.dart';
import 'package:sift/features/assistant/assistant_service.dart';
import 'package:sift/features/collections/collections_service.dart';
import 'package:sift/features/economy/economy_service.dart';
import 'package:sift/features/gallery/data/gallery_repository.dart';
import 'package:sift/features/gallery/domain/screenshot.dart';
import 'package:sift/features/gallery/presentation/gallery_provider.dart';
import 'package:sift/features/gallery/presentation/image_detail_screen.dart';
import 'package:sift/features/gallery/presentation/widgets/screenshot_thumbnail.dart';
import 'package:sift/features/settings/settings_screen.dart';

/// SharedPreferences keys — bumped with a version suffix rather than a
/// migration when the message shape changes, since chat history is a
/// convenience surface, not durable user data (see [_loadPersisted]'s
/// silent-drop-on-decode-failure handling for the same principle).
const _kMessagesKey = 'assistant_chat_messages_v1';
const _kHistoryKey = 'assistant_chat_history_v1';

/// Upper bound on how many messages persist across restarts. Older messages
/// get trimmed silently. The AI-side history in [AssistantService] has its
/// own smaller cap; this is just for the rendered UI list.
const _kMaxPersistedMessages = 200;

class _ChatMessage {
  final bool isUser;
  final String text;
  final List<Screenshot> matches;
  final List<String> matchedTags;
  /// A pending destructive/filing action the AI proposed on this turn.
  /// Deliberately NOT persisted across restarts: the tool state that
  /// PRODUCED this proposal (the AI's per-turn scratch state, its own tool
  /// call context) is gone the moment the app dies, so re-hydrating just the
  /// UI-side [PendingAction] and letting the user tap Confirm days later
  /// would silently delete screenshots based on stale intent. If the user
  /// still wants that action after a restart, they re-ask.
  final PendingAction? pendingAction;
  bool actionResolved = false;
  _ChatMessage({
    required this.isUser,
    required this.text,
    this.matches = const [],
    this.matchedTags = const [],
    this.pendingAction,
  });

  /// Persistable subset — pendingAction is intentionally dropped (see the
  /// field's doc), and matches are stored as IDs re-hydrated on load
  /// against the live gallery so a screenshot that was deleted in the
  /// meantime just quietly disappears from the referenced list instead of
  /// coming back as a stale placeholder.
  Map<String, dynamic> toJson() => {
        'isUser': isUser,
        'text': text,
        'matchIds': matches.map((s) => s.id).toList(),
        'matchedTags': matchedTags,
        'actionResolved': actionResolved,
      };

  static _ChatMessage fromJson(
      Map<String, dynamic> json, Map<int, Screenshot> byId) {
    final ids = (json['matchIds'] as List?)?.whereType<int>().toList() ??
        const <int>[];
    final rehydrated = <Screenshot>[
      for (final id in ids)
        if (byId[id] != null) byId[id]!,
    ];
    final msg = _ChatMessage(
      isUser: json['isUser'] as bool? ?? false,
      text: json['text'] as String? ?? '',
      matches: rehydrated,
      matchedTags: (json['matchedTags'] as List?)?.whereType<String>().toList() ??
          const <String>[],
    );
    if (json['actionResolved'] as bool? ?? false) {
      msg.actionResolved = true;
    }
    return msg;
  }
}

/// Matchers for a user's next chat message when there's still a pending
/// action from the AI's previous turn — see the auto-confirm/cancel path
/// in [_AssistantScreenState._send]. If it's not obvious yes/no the message
/// goes to the AI, which is safer than false-triggering a destructive
/// action on some ambiguous phrase.
///
/// [_isExplicitYes] checks obvious affirmatives at the start ("yes",
/// "yes please", "sure", "ok", "go ahead"). For a pending DELETE, the
/// verb "delete" anywhere in a short reply also counts ("I SAID DELETE
/// THEM" from the frustrated flow that motivated this whole change), as
/// long as the message doesn't also contain a hesitation ("wait", "no
/// actually") — since a delete-word contains-check would otherwise
/// false-match on "delete? no wait".
final _kExplicitYesRegex = RegExp(
  r'^(y|yes|yeah|yep|yup|sure|ok|okay|confirm|confirmed|go|do it|proceed|go ahead|please do|please|yes please|do)\b',
  caseSensitive: false,
);

final _kExplicitNoRegex = RegExp(
  "^(n|no|nope|cancel|cancelled|nvm|nevermind|never\\s?mind|don'?t|dont|stop|abort|not now|no thanks?|no thank you)\\b",
  caseSensitive: false,
);

final _kHesitationRegex = RegExp(
  r'\b(wait|hold on|actually|not yet|not now|hmm|hm|nvm|nevermind|cancel|stop|no)\b',
  caseSensitive: false,
);

final _kDeleteVerbRegex = RegExp(r'\bdelete\b', caseSensitive: false);

/// Returns true when [text] clearly asks to go ahead with a pending
/// [actionType]. For non-destructive actions (add-to-collection, create
/// collection), the affirmative bar is strict. For delete, "delete them"
/// / "I said delete them" also count — provided the message doesn't
/// carry a hesitation word alongside.
bool _looksLikeYes(String text, PendingActionType actionType) {
  final norm = text.trim();
  if (_kExplicitYesRegex.hasMatch(norm)) return true;
  if (actionType == PendingActionType.delete &&
      _kDeleteVerbRegex.hasMatch(norm) &&
      !_kHesitationRegex.hasMatch(norm)) {
    return true;
  }
  return false;
}

bool _looksLikeNo(String text) =>
    _kExplicitNoRegex.hasMatch(text.trim());

/// One of the honest, currently-working things to suggest from the empty
/// state — every entry here must map to an intent AssistantService can
/// actually resolve today. Add to this list only alongside the capability
/// that backs it; a chip that doesn't do anything is worse than no chip.
class _Suggestion {
  final IconData icon;
  final String label;
  final String query;
  const _Suggestion(
      {required this.icon, required this.label, required this.query});
}

const _suggestions = [
  _Suggestion(
      icon: Icons.receipt_long_rounded,
      label: 'Show my receipts',
      query: 'show me my receipts'),
  _Suggestion(
      icon: Icons.auto_delete_outlined,
      label: 'Find junk to review',
      query: 'find junk screenshots'),
  _Suggestion(
      icon: Icons.content_copy_rounded,
      label: 'Find duplicates',
      query: 'find duplicate screenshots'),
  _Suggestion(
      icon: Icons.bar_chart_rounded,
      label: 'Library overview',
      query: 'give me an overview of my library'),
  _Suggestion(
      icon: Icons.label_off_outlined,
      label: 'Find untagged',
      query: 'find screenshots that still need tagging'),
  _Suggestion(
      icon: Icons.help_outline_rounded,
      label: 'What can you do?',
      query: 'what can you do?'),
];

/// Conversational entry point into the gallery — search, count, delete, and
/// collection actions all go through one chat, so navigating a big library
/// doesn't require knowing which tag or collection something landed in.
///
/// Deletion and collection changes are never applied straight from a
/// message: every destructive or filing action shows what actually matched
/// (real thumbnails, not just a count) and waits for an explicit Confirm tap
/// — swipe-to-delete already has no undo, so chat must not make that easier
/// to trigger by accident.
class AssistantScreen extends ConsumerStatefulWidget {
  const AssistantScreen({super.key});

  @override
  ConsumerState<AssistantScreen> createState() => _AssistantScreenState();
}

class _AssistantScreenState extends ConsumerState<AssistantScreen> {
  final _service = AssistantService();
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final List<_ChatMessage> _messages = [];
  bool _busy = false;
  // Bare spinner with no text reads as "broken" the moment a reply takes more
  // than a second or two — which happens for real reasons (the shared AI key
  // is momentarily rate-limited, a cold network call, a slow device) even
  // with the interactive queue priority fix in mistral_client.dart. The
  // fallback timers below escalate what's shown the longer a single request
  // actually runs, so a slow reply reads as "still working" instead of
  // "stuck." Once the AI actually starts calling a tool, [_stage] wins over
  // the generic escalation (see [_send]) — a real "Scanning for duplicates…"
  // beats a generic "Still working…" every time.
  Timer? _busyMessageTimer;
  String? _busyMessage;
  /// The most recent per-tool label from AssistantService's onStage callback
  /// — takes precedence over [_busyMessage] whenever it's set, since it
  /// describes what's actually happening rather than a fallback guess.
  String? _stage;

  /// Progress state for a client-side execution the user just confirmed
  /// (currently only bulk delete — one screenshot at a time in a loop, and
  /// large deletions can take a real number of seconds on a slow device).
  /// Null when nothing is running.
  ({int done, int total, String verb})? _bulkProgress;

  @override
  void initState() {
    super.initState();
    // Fire-and-forget: the UI renders with an empty list first, then fills
    // in from SharedPreferences the moment the load resolves. Blocking the
    // first frame on a disk read to show an empty chat is worse than
    // showing empty for one frame and then filling in.
    unawaited(_loadPersisted());
  }

  @override
  void dispose() {
    _busyMessageTimer?.cancel();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // ── Persistence ──────────────────────────────────────────────────────────

  /// Load the previous session's chat off disk, rehydrating screenshot
  /// references against the CURRENT gallery — anything that was deleted
  /// between sessions just quietly drops out of a message's thumbnail
  /// strip rather than appearing as a broken tile. Failures are swallowed:
  /// a corrupt saved chat should never block the assistant from being
  /// usable, and there's no user-facing recovery worth surfacing.
  Future<void> _loadPersisted() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final rawMessages = prefs.getString(_kMessagesKey);
      final rawHistory = prefs.getString(_kHistoryKey);
      if (rawMessages == null && rawHistory == null) return;

      // Rehydrate matches against the live gallery, indexed once for O(1)
      // lookup rather than a nested scan per stored ID.
      final all = await ref.read(galleryRepositoryProvider).allScreenshots();
      final byId = <int, Screenshot>{for (final s in all) s.id: s};

      final loaded = <_ChatMessage>[];
      if (rawMessages != null) {
        final decoded = jsonDecode(rawMessages) as List;
        for (final entry in decoded) {
          try {
            loaded.add(_ChatMessage.fromJson(
                Map<String, dynamic>.from(entry as Map), byId));
          } catch (_) {
            // Skip any individual entry that can't decode rather than
            // dropping the whole chat.
          }
        }
      }

      if (rawHistory != null) {
        try {
          final decoded = jsonDecode(rawHistory) as List;
          _service.restoreHistory([
            for (final h in decoded)
              Map<String, String>.from(h as Map),
          ]);
        } catch (_) {
          // History decode failure doesn't invalidate the UI-side messages
          // — the AI just starts a fresh reasoning context, worst case.
        }
      }

      if (!mounted) return;
      setState(() {
        _messages
          ..clear()
          ..addAll(loaded);
      });
      _scrollToEnd();
    } catch (e) {
      DiagnosticLog.warn('AssistantScreen: failed to restore chat: $e');
    }
  }

  /// Serialize the current chat (both the rendered UI list and the AI's
  /// internal history) to SharedPreferences. Called after every mutation —
  /// send, confirm, cancel, new-chat. Bounded to [_kMaxPersistedMessages]
  /// so a marathon session doesn't grow unboundedly.
  Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final trimmed = _messages.length > _kMaxPersistedMessages
          ? _messages.sublist(_messages.length - _kMaxPersistedMessages)
          : _messages;
      await prefs.setString(
          _kMessagesKey, jsonEncode(trimmed.map((m) => m.toJson()).toList()));
      await prefs.setString(
          _kHistoryKey, jsonEncode(_service.exportHistory()));
    } catch (e) {
      DiagnosticLog.warn('AssistantScreen: failed to persist chat: $e');
    }
  }

  /// Clear the entire conversation — messages, AI history, and disk. Used
  /// by the "New chat" AppBar action.
  Future<void> _startNewChat() async {
    _service.clearHistory();
    setState(() {
      _messages.clear();
      _stage = null;
      _bulkProgress = null;
    });
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_kMessagesKey);
      await prefs.remove(_kHistoryKey);
    } catch (_) {
      // Chat's already cleared in memory; disk cleanup failing is not worth
      // surfacing.
    }
  }

  // ── Busy state ───────────────────────────────────────────────────────────

  /// Effective label to show next to the spinner — a real per-tool stage
  /// wins over the escalating fallback whenever the AI has actually started
  /// running a tool. Reading from a single getter here keeps the UI's
  /// display simple and both signals cooperating.
  String? get _effectiveBusyLabel => _stage ?? _busyMessage;

  void _startBusyMessages() {
    _busyMessageTimer?.cancel();
    setState(() {
      _busyMessage = null;
      _stage = null;
    });
    _busyMessageTimer = Timer(const Duration(seconds: 3), () {
      if (!mounted || !_busy) return;
      setState(() => _busyMessage = 'Thinking…');
      _busyMessageTimer = Timer(const Duration(seconds: 8), () {
        if (!mounted || !_busy) return;
        setState(() =>
            _busyMessage = 'Still working — the AI is a little busy right now.');
      });
    });
  }

  void _stopBusyMessages() {
    _busyMessageTimer?.cancel();
    _busyMessageTimer = null;
    if (mounted) {
      setState(() {
        _busyMessage = null;
        _stage = null;
      });
    }
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  /// Runs a suggestion chip's preset query through the exact same path a
  /// typed-and-sent message takes — a chip is a shortcut into `_send()`,
  /// never a separate, thinner code path that could drift from it.
  void _sendPreset(String query) {
    _controller.text = query;
    _send();
  }

  /// The most recent assistant message that STILL has an unresolved
  /// pending action, or null if there isn't one. Used by [_send] to route
  /// obvious "yes"/"no" replies straight to confirm/cancel instead of
  /// bouncing them back through the AI, which was the root of the "I said
  /// delete them" runaround: the model can only PROPOSE deletions, never
  /// execute them, so every affirmative reply just triggered another
  /// propose_delete or a hallucinated "already deleted."
  _ChatMessage? _lastPendingMessage() {
    for (var i = _messages.length - 1; i >= 0; i--) {
      final m = _messages[i];
      if (!m.isUser && m.pendingAction != null && !m.actionResolved) return m;
    }
    return null;
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _busy) return;

    // ── Auto-confirm / auto-cancel a pending action ────────────────────
    // If the previous assistant turn is still waiting on a Confirm/Cancel
    // tap and the user's reply is a clear yes-or-no, execute the same
    // path the button would have — the AI never sees this turn. Fixes the
    // "yes / I SAID DELETE THEM / delete them" loop where the model kept
    // re-proposing because the propose_delete tool doesn't actually
    // delete anything, only records a pending action awaiting UI confirm.
    final pending = _lastPendingMessage();
    if (pending != null && pending.pendingAction != null) {
      final actionType = pending.pendingAction!.type;
      if (_looksLikeYes(text, actionType)) {
        _controller.clear();
        setState(() {
          _messages.add(_ChatMessage(isUser: true, text: text));
        });
        _scrollToEnd();
        await _confirm(pending);
        return;
      }
      if (_looksLikeNo(text)) {
        _controller.clear();
        setState(() {
          _messages.add(_ChatMessage(isUser: true, text: text));
        });
        _scrollToEnd();
        _cancel(pending);
        return;
      }
    }

    _controller.clear();
    setState(() {
      _messages.add(_ChatMessage(isUser: true, text: text));
      _busy = true;
    });
    _scrollToEnd();
    unawaited(_persist());
    _startBusyMessages();

    try {
      final repo = ref.read(galleryRepositoryProvider);
      final collections = ref.read(collectionsServiceProvider).value ?? [];
      // Bounded — the previous version of this screen had no visibility at
      // all into a hang here, so a stuck Isar/Riverpod stream (not the AI
      // call at all) would look identical to the AI itself being slow, with
      // an empty diagnostic log either way. If this ever actually times out,
      // the log line proves the AI call was never the problem.
      final tags = await ref.read(uniqueTagsProvider.future).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          DiagnosticLog.error(
              'AssistantScreen: uniqueTagsProvider did not emit within 10s '
              '— falling back to no tags rather than hanging.');
          return const <String>[];
        },
      );
      final byokKey = ref.read(economyServiceProvider.notifier).getByokKey();
      final all = await repo.allScreenshots();

      DiagnosticLog.info('AssistantScreen: calling AssistantService.chat()…');
      // A real ceiling so a genuine hang — anywhere in chat(), not just a
      // slow AI response (each round has its own 45s HTTP timeout) —
      // surfaces as "something went wrong" instead of a spinner that never
      // resolves. Bumped 90s → 180s: find_duplicates on a large library is
      // O(n²) and can eat a solid chunk of a single round, and a
      // multi-tool turn ("search these, then propose delete on the old
      // ones") can chain a few of those before the final reply. 180s
      // still catches a real hang without falsely tripping on legitimate
      // long operations the earlier ceiling misclassified.
      final result = await _service
          .chat(
            text,
            allScreenshots: all,
            availableTags: tags,
            availableCollections: collections.map((c) => c.name).toList(),
            byokApiKey: byokKey,
            findDuplicates: () => repo.findDuplicateClusters(),
            onStage: (label) {
              if (mounted) setState(() => _stage = label);
            },
          )
          .timeout(
        const Duration(seconds: 180),
        onTimeout: () {
          DiagnosticLog.error(
              'AssistantScreen: AssistantService.chat() did not return '
              'within 180s.');
          return AssistantResult.failedResult;
        },
      );

      if (!mounted) return;
      setState(() => _messages.add(_ChatMessage(
            isUser: false,
            text: result.reply,
            matches: result.screenshots,
            matchedTags: result.highlightTags,
            pendingAction: result.pendingAction,
          )));
      unawaited(_persist());
    } finally {
      _stopBusyMessages();
      if (mounted) setState(() => _busy = false);
      _scrollToEnd();
    }
  }

  Future<void> _confirm(_ChatMessage msg) async {
    if (msg.actionResolved || msg.pendingAction == null) return;
    final action = msg.pendingAction!;
    setState(() => msg.actionResolved = true);

    String outcomeReply;
    String aiNote;
    try {
      switch (action.type) {
        case PendingActionType.delete:
          final repo = ref.read(galleryRepositoryProvider);
          final total = action.targets.length;
          // Per-item live progress: a bulk delete of 50-100 screenshots is a
          // real chunk of user-visible time on a slow device, and a plain
          // spinner reads as "did anything happen?" — this replaces it with
          // a live "Deleting 12 of 47…" so slow deletes look like progress
          // instead of a hang.
          setState(() =>
              _bulkProgress = (done: 0, total: total, verb: 'Deleting'));
          for (var i = 0; i < action.targets.length; i++) {
            await repo.deleteScreenshot(action.targets[i].id);
            if (!mounted) return;
            setState(() => _bulkProgress =
                (done: i + 1, total: total, verb: 'Deleting'));
          }
          outcomeReply = 'Deleted $total screenshot${total == 1 ? '' : 's'}.';
          aiNote = 'The user confirmed and $total screenshot'
              '${total == 1 ? ' was' : 's were'} deleted from the library.';
          break;
        case PendingActionType.addToCollection:
          final service = ref.read(collectionsServiceProvider.notifier);
          var collection = service.findByName(action.collectionName!);
          collection ??= await service.create(action.collectionName!);
          final total = action.targets.length;
          setState(() =>
              _bulkProgress = (done: 0, total: total, verb: 'Adding'));
          await service.addScreenshots(
              collection.id, action.targets.map((s) => s.id));
          if (!mounted) return;
          setState(
              () => _bulkProgress = (done: total, total: total, verb: 'Adding'));
          outcomeReply = 'Added $total to "${action.collectionName}".';
          aiNote = 'The user confirmed and $total screenshot'
              '${total == 1 ? '' : 's'} added to collection '
              '"${action.collectionName}".';
          break;
        case PendingActionType.createCollection:
          await ref
              .read(collectionsServiceProvider.notifier)
              .create(action.collectionName!);
          outcomeReply = 'Created "${action.collectionName}".';
          aiNote =
              'The user confirmed and collection "${action.collectionName}" was created.';
          break;
      }
    } finally {
      if (mounted) setState(() => _bulkProgress = null);
    }
    if (!mounted) return;
    setState(() =>
        _messages.add(_ChatMessage(isUser: false, text: outcomeReply)));
    // Feed the outcome back into the AI's history — without this, the model
    // has no memory of what happened between turns and will hallucinate
    // ("nothing was deleted", "already deleted") if the user asks about the
    // action later.
    _service.recordActionOutcome(aiNote);
    unawaited(_persist());
    _scrollToEnd();
  }

  void _cancel(_ChatMessage msg) {
    if (msg.actionResolved) return;
    setState(() {
      msg.actionResolved = true;
      _messages.add(_ChatMessage(isUser: false, text: 'Cancelled.'));
    });
    _service.recordActionOutcome(
        'The user cancelled the pending action; nothing was changed.');
    unawaited(_persist());
    _scrollToEnd();
  }

  /// Confirmation dialog before wiping the chat — cheap safety net so the
  /// AppBar button isn't a one-tap way to erase a long thread by accident.
  /// Uses the default (theme-aware) dialog styling, same reason
  /// _confirmPurge in Discover does — a hardcoded background here would
  /// reintroduce the paywall-sheet contrast bug in Light mode.
  Future<void> _confirmNewChat() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Start a new chat?'),
        content: const Text(
            'This clears your conversation history. Screenshots in your '
            'library aren\'t affected — just the chat messages.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('New chat'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await _startNewChat();
    }
  }

  @override
  Widget build(BuildContext context) {
    final showIntro = _messages.isEmpty;
    return Scaffold(
      backgroundColor: SiftPillowyColors.surface,
      appBar: AppBar(
        backgroundColor: SiftPillowyColors.surfaceContainerLowest,
        elevation: 0,
        iconTheme: IconThemeData(color: SiftPillowyColors.onSurface),
        title: Text('Ask Sift', style: SiftPillowyText.headlineSm),
        actions: [
          if (_messages.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.add_comment_outlined),
              tooltip: 'New chat',
              onPressed: _busy ? null : _confirmNewChat,
            ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Settings',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              itemCount: (showIntro ? 1 : 0) + _messages.length,
              itemBuilder: (context, index) {
                if (showIntro && index == 0) {
                  return _IntroCard(onSuggestionTap: _sendPreset);
                }
                final message = _messages[index - (showIntro ? 1 : 0)];
                return _MessageBubble(
                  message: message,
                  onConfirm: message.pendingAction != null
                      ? () => _confirm(message)
                      : null,
                  onCancel: message.pendingAction != null
                      ? () => _cancel(message)
                      : null,
                );
              },
            ),
          ),
          if (_bulkProgress != null) _BulkProgressBar(state: _bulkProgress!),
          if (_busy)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: SiftPillowyColors.primary),
                  ),
                  if (_effectiveBusyLabel != null) ...[
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(_effectiveBusyLabel!,
                          style: SiftPillowyText.bodySm,
                          overflow: TextOverflow.ellipsis),
                    ),
                  ],
                ],
              ),
            ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: SiftPillowyColors.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(999),
                  boxShadow: [
                    BoxShadow(
                      color: SiftPillowyColors.onSurface.withOpacity(0.08),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const SizedBox(width: 6),
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        enabled: !_busy,
                        style: SiftPillowyText.bodyMd,
                        decoration: InputDecoration(
                          hintText: "Ask Sift: 'Find receipts from March'…",
                          hintStyle: SiftPillowyText.bodyMd.copyWith(
                              color: SiftPillowyColors.onSurfaceVariant
                                  .withOpacity(0.6)),
                          border: InputBorder.none,
                          isDense: true,
                        ),
                        onSubmitted: (_) => _send(),
                        textInputAction: TextInputAction.send,
                      ),
                    ),
                    _SendButton(busy: _busy, onTap: _busy ? null : _send),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SendButton extends StatelessWidget {
  final bool busy;
  final VoidCallback? onTap;
  const _SendButton({required this.busy, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            gradient: busy ? null : SiftPillowyColors.primaryGradient,
            color: busy ? SiftPillowyColors.surfaceContainerHigh : null,
            shape: BoxShape.circle,
            boxShadow: busy
                ? null
                : [
                    BoxShadow(
                      color: SiftPillowyColors.primaryContainer
                          .withOpacity(0.45),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
          ),
          child: Icon(Icons.arrow_upward_rounded,
              color: busy
                  ? SiftPillowyColors.onSurfaceVariant
                  : SiftPillowyColors.onPrimary,
              size: 20),
        ),
      ),
    );
  }
}

/// Shown only until the first message is sent — real library stats and a
/// row of suggestion chips that each run an intent AssistantService
/// genuinely supports today, replacing a static wall of instructional text
/// nobody reads twice.
class _IntroCard extends ConsumerWidget {
  final void Function(String query) onSuggestionTap;
  const _IntroCard({required this.onSuggestionTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final totalShots = ref.watch(totalScreenshotCountProvider).maybeWhen(
          data: (n) => n,
          orElse: () => null,
        );
    final tagCount = ref.watch(uniqueTagsProvider).maybeWhen(
          data: (tags) => tags.length,
          orElse: () => null,
        );
    final collectionCount = ref.watch(collectionsServiceProvider).maybeWhen(
          data: (list) => list.length,
          orElse: () => null,
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: SiftPillowyColors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(
                color: SiftPillowyColors.primaryContainer.withOpacity(0.12),
                blurRadius: 32,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      gradient: SiftPillowyColors.assistantAvatarGradient,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.auto_awesome_rounded,
                        color: Colors.white, size: 26),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Ask Sift', style: SiftPillowyText.headlineMd),
                        const SizedBox(height: 2),
                        Text(
                          'Find, count, delete, or collect screenshots — '
                          'just describe what you need.',
                          style: SiftPillowyText.bodySm,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _StatPill(label: 'Screenshots', value: totalShots),
                  const SizedBox(width: 8),
                  _StatPill(label: 'Tags', value: tagCount),
                  const SizedBox(width: 8),
                  _StatPill(label: 'Collections', value: collectionCount),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 44,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _suggestions.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, i) {
              final s = _suggestions[i];
              return _SuggestionChip(
                icon: s.icon,
                label: s.label,
                onTap: () => onSuggestionTap(s.query),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _StatPill extends StatelessWidget {
  final String label;
  final int? value;
  const _StatPill({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: SiftPillowyColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Text(label,
                style: SiftPillowyText.labelSm
                    .copyWith(color: SiftPillowyColors.onSurfaceVariant)),
            const SizedBox(height: 2),
            Text(
              value == null ? '—' : '$value',
              style: SiftPillowyText.headlineSm
                  .copyWith(color: SiftPillowyColors.primary, fontSize: 17),
            ),
          ],
        ),
      ),
    );
  }
}

class _SuggestionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _SuggestionChip(
      {required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: SiftPillowyColors.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
                color: SiftPillowyColors.outlineVariant.withOpacity(0.6)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: SiftPillowyColors.primary),
              const SizedBox(width: 6),
              Text(label,
                  style: SiftPillowyText.labelMd
                      .copyWith(color: SiftPillowyColors.onSurface)),
            ],
          ),
        ),
      ),
    );
  }
}

class _MessageBubble extends ConsumerWidget {
  final _ChatMessage message;
  final VoidCallback? onConfirm;
  final VoidCallback? onCancel;

  const _MessageBubble(
      {required this.message, required this.onConfirm, required this.onCancel});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isUser = message.isUser;
    final action = message.pendingAction;
    final showActions = action != null && !message.actionResolved;
    // Captured as a plain bool rather than reading action.type directly
    // below — action stays nullable to the analyzer inside the conditional
    // widget tree even though showActions already ruled that out.
    final isDelete = action?.type == PendingActionType.delete;
    final pinnedIds = ref.watch(pinnedIdsProvider);

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        constraints:
            BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.82),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          gradient: isUser ? SiftPillowyColors.primaryGradient : null,
          color: isUser ? null : SiftPillowyColors.surfaceContainerLowest,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: Radius.circular(isUser ? 20 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 20),
          ),
          boxShadow: [
            BoxShadow(
              color: (isUser
                      ? SiftPillowyColors.primaryContainer
                      : SiftPillowyColors.onSurface)
                  .withOpacity(isUser ? 0.25 : 0.06),
              blurRadius: isUser ? 16 : 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message.text,
              style: SiftPillowyText.bodyMd.copyWith(
                color: isUser
                    ? SiftPillowyColors.onPrimary
                    : SiftPillowyColors.onSurface,
              ),
            ),
            if (message.matchedTags.isNotEmpty) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: message.matchedTags
                    .map((t) => _TagChip(
                        label: t.startsWith('#') ? t.substring(1) : t))
                    .toList(),
              ),
            ],
            if (message.matches.isNotEmpty) ...[
              const SizedBox(height: 10),
              SizedBox(
                height: 84,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: message.matches.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, i) {
                    final shot = message.matches[i];
                    final isPinned = pinnedIds.contains(shot.id);
                    return GestureDetector(
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (_) =>
                                ImageDetailScreen(screenshot: shot)),
                      ),
                      child: SizedBox(
                        width: 84,
                        height: 84,
                        child: Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(14),
                              child: ScreenshotThumbnail(
                                  filePath: shot.filePath),
                            ),
                            Positioned(
                              top: 4,
                              right: 4,
                              child: GestureDetector(
                                onTap: () => togglePinned(ref, shot.id),
                                child: Container(
                                  width: 22,
                                  height: 22,
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.35),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    isPinned
                                        ? Icons.favorite_rounded
                                        : Icons.favorite_border_rounded,
                                    size: 13,
                                    color: isPinned
                                        ? SiftPillowyColors.primaryContainer
                                        : Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
            if (showActions) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  _PillButton(
                    label: isDelete ? 'Delete' : 'Confirm',
                    color: isDelete
                        ? SiftPillowyColors.error
                        : SiftPillowyColors.primary,
                    onTap: onConfirm,
                  ),
                  const SizedBox(width: 8),
                  _PillButton(
                    label: 'Cancel',
                    color: SiftPillowyColors.onSurfaceVariant,
                    filled: false,
                    onTap: onCancel,
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  final String label;
  const _TagChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: SiftPillowyColors.secondaryFixed,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '#$label',
        style: SiftPillowyText.labelSm
            .copyWith(color: SiftPillowyColors.onSecondaryFixed, fontSize: 11),
      ),
    );
  }
}

class _PillButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback? onTap;
  final bool filled;
  const _PillButton(
      {required this.label,
      required this.color,
      required this.onTap,
      this.filled = true});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: filled ? color : Colors.transparent,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
          decoration: filled
              ? null
              : BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: color.withOpacity(0.4)),
                ),
          child: Text(
            label,
            style: SiftPillowyText.labelLg
                .copyWith(color: filled ? Colors.white : color),
          ),
        ),
      ),
    );
  }
}

/// Progress strip shown during a bulk client-side action the user
/// confirmed — currently only bulk delete, which is the only place a large
/// enough action runs on the UI isolate to be user-visible. A large enough
/// deletion (dozens of screenshots) on a slow device takes real time and
/// the plain "Cancelled." / "Deleted N." final message alone reads as a
/// hang while it's still running. Distinct from [_effectiveBusyLabel]
/// (which is about the AI's own tool calls); shown together when both
/// apply, though in practice they don't overlap.
class _BulkProgressBar extends StatelessWidget {
  final ({int done, int total, String verb}) state;
  const _BulkProgressBar({required this.state});

  @override
  Widget build(BuildContext context) {
    final fraction = state.total == 0 ? 0.0 : state.done / state.total;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: SiftPillowyColors.surfaceContainerLow,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${state.verb} ${state.done} of ${state.total}…',
                  style: SiftPillowyText.labelMd,
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: fraction,
                    minHeight: 4,
                    backgroundColor: SiftPillowyColors.surfaceContainerHigh,
                    color: SiftPillowyColors.primary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
