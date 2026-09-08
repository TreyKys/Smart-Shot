import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

class _ChatMessage {
  final bool isUser;
  final String text;
  final List<Screenshot> matches;
  final List<String> matchedTags;
  final PendingAction? pendingAction;
  bool actionResolved = false;
  _ChatMessage({
    required this.isUser,
    required this.text,
    this.matches = const [],
    this.matchedTags = const [],
    this.pendingAction,
  });
}

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
  // with the interactive queue priority fix in mistral_client.dart. These
  // escalate what's shown the longer a single request actually runs, so a
  // slow reply reads as "still working" instead of "stuck."
  Timer? _busyMessageTimer;
  String? _busyMessage;

  @override
  void dispose() {
    _busyMessageTimer?.cancel();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _startBusyMessages() {
    _busyMessageTimer?.cancel();
    setState(() => _busyMessage = null);
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
    if (mounted) setState(() => _busyMessage = null);
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

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _busy) return;
    _controller.clear();
    setState(() {
      _messages.add(_ChatMessage(isUser: true, text: text));
      _busy = true;
    });
    _scrollToEnd();
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
      // resolves. 90s allows for a multi-round tool loop (up to 5 rounds).
      final result = await _service
          .chat(
            text,
            allScreenshots: all,
            availableTags: tags,
            availableCollections: collections.map((c) => c.name).toList(),
            byokApiKey: byokKey,
            findDuplicates: () => repo.findDuplicateClusters(),
          )
          .timeout(
        const Duration(seconds: 90),
        onTimeout: () {
          DiagnosticLog.error(
              'AssistantScreen: AssistantService.chat() did not return '
              'within 90s.');
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

    switch (action.type) {
      case PendingActionType.delete:
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
      case PendingActionType.addToCollection:
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
      case PendingActionType.createCollection:
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

  void _cancel(_ChatMessage msg) {
    if (msg.actionResolved) return;
    setState(() {
      msg.actionResolved = true;
      _messages.add(_ChatMessage(isUser: false, text: 'Cancelled.'));
    });
    _scrollToEnd();
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
                  if (_busyMessage != null) ...[
                    const SizedBox(width: 8),
                    Text(_busyMessage!, style: SiftPillowyText.bodySm),
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
