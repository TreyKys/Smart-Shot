import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sift/core/theme/app_theme.dart';
import 'package:sift/features/assistant/assistant_service.dart';
import 'package:sift/features/collections/collections_service.dart';
import 'package:sift/features/economy/economy_service.dart';
import 'package:sift/features/gallery/data/gallery_repository.dart';
import 'package:sift/features/gallery/domain/screenshot.dart';
import 'package:sift/features/gallery/presentation/gallery_provider.dart';
import 'package:sift/features/gallery/presentation/image_detail_screen.dart';
import 'package:sift/features/gallery/presentation/widgets/screenshot_thumbnail.dart';

enum _PendingActionType { delete, addToCollection, createCollection }

class _PendingAction {
  final _PendingActionType type;
  final List<Screenshot> targets;
  final String? collectionName;
  bool resolved = false;
  _PendingAction(
      {required this.type, required this.targets, this.collectionName});
}

class _ChatMessage {
  final bool isUser;
  final String text;
  final List<Screenshot> matches;
  final _PendingAction? pendingAction;
  _ChatMessage({
    required this.isUser,
    required this.text,
    this.matches = const [],
    this.pendingAction,
  });
}

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

  @override
  void initState() {
    super.initState();
    _messages.add(_ChatMessage(
      isUser: false,
      text: 'Ask me to find, count, delete, or collect screenshots — '
          '"show me my receipts from March", "delete the junk from this '
          'week", "put these travel shots in a Trip 2026 collection."',
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
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

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _busy) return;
    _controller.clear();
    setState(() {
      _messages.add(_ChatMessage(isUser: true, text: text));
      _busy = true;
    });
    _scrollToEnd();

    try {
      final repo = ref.read(galleryRepositoryProvider);
      final collections = ref.read(collectionsServiceProvider).value ?? [];
      final tags = await ref.read(uniqueTagsProvider.future);
      final byokKey = ref.read(economyServiceProvider.notifier).getByokKey();

      final plan = await _service.plan(
        text,
        availableTags: tags,
        availableCollections: collections.map((c) => c.name).toList(),
        byokApiKey: byokKey,
      );

      final all = await repo.allScreenshots();
      final matched = _match(all, plan);
      _respond(plan, matched);
    } finally {
      if (mounted) setState(() => _busy = false);
      _scrollToEnd();
    }
  }

  void _respond(AssistantPlan plan, List<Screenshot> matched) {
    if (!mounted) return;
    switch (plan.intent) {
      case AssistantIntent.search:
        setState(() => _messages.add(_ChatMessage(
              isUser: false,
              text: matched.isEmpty
                  ? "${plan.reply}\n\nNothing actually matched, though."
                  : plan.reply,
              matches: matched,
            )));
        break;
      case AssistantIntent.count:
        setState(() => _messages.add(_ChatMessage(
              isUser: false,
              text: 'Found ${matched.length} screenshot'
                  '${matched.length == 1 ? '' : 's'}. ${plan.reply}',
              matches: matched.take(8).toList(),
            )));
        break;
      case AssistantIntent.delete:
        if (matched.isEmpty) {
          setState(() => _messages.add(_ChatMessage(
                isUser: false,
                text: "I couldn't find anything matching that to delete.",
              )));
        } else {
          setState(() => _messages.add(_ChatMessage(
                isUser: false,
                text: 'Found ${matched.length} screenshot'
                    '${matched.length == 1 ? '' : 's'} matching that. '
                    'Delete ${matched.length == 1 ? 'it' : 'them all'}? '
                    "This can't be undone.",
                matches: matched,
                pendingAction: _PendingAction(
                    type: _PendingActionType.delete, targets: matched),
              )));
        }
        break;
      case AssistantIntent.addToCollection:
        final name = plan.collectionName?.trim();
        if (matched.isEmpty) {
          setState(() => _messages.add(_ChatMessage(
                isUser: false,
                text: "I couldn't find anything matching that to add.",
              )));
        } else if (name == null || name.isEmpty) {
          setState(() => _messages.add(_ChatMessage(
                isUser: false,
                text: 'Found ${matched.length} screenshot'
                    '${matched.length == 1 ? '' : 's'}, but which '
                    'collection? Try naming one, e.g. "put these in Taxes."',
                matches: matched,
              )));
        } else {
          setState(() => _messages.add(_ChatMessage(
                isUser: false,
                text: 'Add ${matched.length} screenshot'
                    '${matched.length == 1 ? '' : 's'} to "$name"?',
                matches: matched,
                pendingAction: _PendingAction(
                  type: _PendingActionType.addToCollection,
                  targets: matched,
                  collectionName: name,
                ),
              )));
        }
        break;
      case AssistantIntent.createCollection:
        final name = plan.collectionName?.trim();
        if (name == null || name.isEmpty) {
          setState(() => _messages.add(_ChatMessage(
                isUser: false,
                text: 'What should the new collection be called?',
              )));
        } else {
          setState(() => _messages.add(_ChatMessage(
                isUser: false,
                text: 'Create an empty collection called "$name"?',
                pendingAction: _PendingAction(
                  type: _PendingActionType.createCollection,
                  targets: const [],
                  collectionName: name,
                ),
              )));
        }
        break;
      case AssistantIntent.unclear:
        setState(
            () => _messages.add(_ChatMessage(isUser: false, text: plan.reply)));
        break;
    }
  }

  /// Runs entirely on-device against fields every screenshot already has —
  /// the same tags/topic/cleanText/ocrText/timestamp the normal tagging
  /// pipeline populates. Mirrors search_provider.dart's in-memory filtering
  /// approach rather than inventing a new matching strategy.
  List<Screenshot> _match(List<Screenshot> all, AssistantPlan plan) {
    Iterable<Screenshot> pool = all;
    if (plan.tags.isNotEmpty) {
      final wanted =
          plan.tags.map((t) => t.toLowerCase().replaceFirst('#', '')).toSet();
      pool = pool.where((s) => (s.tags ?? const []).any(
          (t) => wanted.contains(t.toLowerCase().replaceFirst('#', ''))));
    }
    if (plan.keywords.isNotEmpty) {
      pool = pool.where((s) {
        final combined = [
          s.topic ?? '',
          s.cleanText ?? '',
          s.ocrText ?? '',
          ...(s.tags ?? const []),
        ].join(' ').toLowerCase();
        return plan.keywords.any((k) => combined.contains(k.toLowerCase()));
      });
    }
    if (plan.dateFrom != null) {
      final from = plan.dateFrom!;
      pool = pool.where((s) => !s.timestamp.isBefore(from));
    }
    if (plan.dateTo != null) {
      final to = plan.dateTo!.add(const Duration(days: 1));
      pool = pool.where((s) => s.timestamp.isBefore(to));
    }
    return pool.toList();
  }

  Future<void> _confirm(_PendingAction action) async {
    if (action.resolved) return;
    setState(() => action.resolved = true);

    switch (action.type) {
      case _PendingActionType.delete:
        final repo = ref.read(galleryRepositoryProvider);
        for (final s in action.targets) {
          await repo.deleteScreenshot(s.id);
        }
        if (!mounted) return;
        setState(() => _messages.add(_ChatMessage(
              isUser: false,
              text: 'Deleted ${action.targets.length} screenshot'
                  '${action.targets.length == 1 ? '' : 's'}.',
            )));
        break;
      case _PendingActionType.addToCollection:
        final service = ref.read(collectionsServiceProvider.notifier);
        var collection = service.findByName(action.collectionName!);
        collection ??= await service.create(action.collectionName!);
        await service.addScreenshots(
            collection.id, action.targets.map((s) => s.id));
        if (!mounted) return;
        setState(() => _messages.add(_ChatMessage(
              isUser: false,
              text: 'Added ${action.targets.length} to '
                  '"${action.collectionName}".',
            )));
        break;
      case _PendingActionType.createCollection:
        await ref
            .read(collectionsServiceProvider.notifier)
            .create(action.collectionName!);
        if (!mounted) return;
        setState(() => _messages.add(
            _ChatMessage(isUser: false, text: 'Created "${action.collectionName}".')));
        break;
    }
    _scrollToEnd();
  }

  void _cancel(_PendingAction action) {
    if (action.resolved) return;
    setState(() {
      action.resolved = true;
      _messages.add(_ChatMessage(isUser: false, text: 'Cancelled.'));
    });
    _scrollToEnd();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SiftColors.background,
      appBar: AppBar(
        backgroundColor: SiftColors.background,
        title: const Text('Ask Sift'),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                return _MessageBubble(
                  message: message,
                  onConfirm: message.pendingAction == null
                      ? null
                      : () => _confirm(message.pendingAction!),
                  onCancel: message.pendingAction == null
                      ? null
                      : () => _cancel(message.pendingAction!),
                );
              },
            ),
          ),
          if (_busy)
            const Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: SiftColors.accent),
              ),
            ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      enabled: !_busy,
                      style: const TextStyle(color: SiftColors.textPrimary),
                      decoration: const InputDecoration(
                        hintText: 'Ask about your screenshots…',
                        filled: true,
                        fillColor: SiftColors.surfaceElevated,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(24)),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      ),
                      onSubmitted: (_) => _send(),
                      textInputAction: TextInputAction.send,
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: _busy ? null : _send,
                    icon: const Icon(Icons.send, color: SiftColors.accent),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final _ChatMessage message;
  final VoidCallback? onConfirm;
  final VoidCallback? onCancel;

  const _MessageBubble(
      {required this.message, required this.onConfirm, required this.onCancel});

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    final action = message.pendingAction;
    final showActions = action != null && !action.resolved;
    // Captured as a plain bool rather than reading action.type directly
    // below — action stays nullable to the analyzer inside the conditional
    // widget tree even though showActions already ruled that out.
    final isDelete = action?.type == _PendingActionType.delete;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        constraints:
            BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.82),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isUser
              ? SiftColors.accent.withOpacity(0.15)
              : SiftColors.surfaceElevated,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isUser
                ? SiftColors.accent.withOpacity(0.4)
                : SiftColors.border,
            width: 0.8,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message.text,
              style: const TextStyle(
                  color: SiftColors.textPrimary, fontSize: 14, height: 1.4),
            ),
            if (message.matches.isNotEmpty) ...[
              const SizedBox(height: 10),
              SizedBox(
                height: 76,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: message.matches.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 6),
                  itemBuilder: (context, i) {
                    final shot = message.matches[i];
                    return GestureDetector(
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (_) =>
                                ImageDetailScreen(screenshot: shot)),
                      ),
                      child: SizedBox(
                        width: 76,
                        height: 76,
                        child: ScreenshotThumbnail(filePath: shot.filePath),
                      ),
                    );
                  },
                ),
              ),
            ],
            if (showActions) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          isDelete ? SiftColors.danger : SiftColors.accent,
                      foregroundColor:
                          isDelete ? Colors.white : Colors.black,
                    ),
                    onPressed: onConfirm,
                    child: Text(isDelete ? 'Delete' : 'Confirm'),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: onCancel,
                    child: const Text('Cancel',
                        style: TextStyle(color: SiftColors.textSecondary)),
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
