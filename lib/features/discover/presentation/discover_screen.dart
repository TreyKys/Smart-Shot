import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sift/core/theme/app_theme.dart';
import 'package:sift/features/discover/presentation/memory_grid_screen.dart';
import 'package:sift/features/duplicates/duplicate_service.dart';
import 'package:sift/features/duplicates/presentation/duplicate_review_screen.dart';
import 'package:sift/features/economy/economy_service.dart';
import 'package:sift/features/gallery/presentation/providers/processing_progress_provider.dart';
import 'package:sift/features/gallery/presentation/providers/unprocessed_count_provider.dart';
import 'package:sift/features/junk_review/junk_review_service.dart';
import 'package:sift/features/junk_review/presentation/junk_review_screen.dart';
import 'package:sift/features/learning/tag_correction_service.dart';
import 'package:sift/features/memories/memories_service.dart';
import 'package:sift/features/purge/purge_service.dart';
import 'package:sift/features/settings/settings_screen.dart';

/// Home tab — real, already-computed signals surfaced in one place instead
/// of requiring the drawer or a notification to find them: today's "on this
/// day" memories (real timestamps), duplicate clusters (the dHash index
/// this app already maintains), unreviewed junk (the existing Junk Review
/// pipeline), whether the library still has a processing backlog (so an
/// otherwise-empty screen explains itself instead of just looking broken),
/// reclaimable storage (the same query PurgeService already runs), and
/// how many tag corrections the learning system has actually recorded
/// recently. No streaks, no XP, no fabricated "curator level" — every card
/// here reads a real, already-computed number, never one invented for the
/// screen. See the design conversation this screen came out of for why.
class DiscoverScreen extends ConsumerWidget {
  const DiscoverScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final memoriesAsync = ref.watch(memoriesProvider);
    final duplicatesAsync = ref.watch(duplicateClustersProvider);
    final junkCount = ref
        .watch(unreviewedJunkCountProvider)
        .maybeWhen(data: (n) => n, orElse: () => 0);
    final processing = ref.watch(processingProgressProvider);
    final unprocessedCount = ref
        .watch(unprocessedCountProvider)
        .maybeWhen(data: (n) => n, orElse: () => 0);
    final purgeResult = ref
        .watch(purgeServiceProvider)
        .maybeWhen(data: (r) => r, orElse: () => null);
    final recentCorrections = ref
        .watch(recentCorrectionCountProvider)
        .maybeWhen(data: (n) => n, orElse: () => 0);

    final hasMemories = memoriesAsync.maybeWhen(
      data: (m) => m.isNotEmpty,
      orElse: () => false,
    );
    final duplicateCount = duplicatesAsync.maybeWhen(
      data: (clusters) => clusters.length,
      orElse: () => 0,
    );
    final hasBacklog = processing.active || unprocessedCount > 0;
    final hasPurgeable = purgeResult != null && purgeResult.count > 0;
    final isLoading = memoriesAsync.isLoading || duplicatesAsync.isLoading;
    final hasNothingToShow =
        !isLoading &&
        !hasMemories &&
        duplicateCount == 0 &&
        junkCount == 0 &&
        !hasBacklog &&
        !hasPurgeable &&
        recentCorrections == 0;

    return Scaffold(
      backgroundColor: SiftPillowyColors.surface,
      appBar: AppBar(
        backgroundColor: SiftPillowyColors.surfaceContainerLowest,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text('Discover', style: SiftPillowyText.headlineSm),
        actions: [
          IconButton(
            icon: Icon(
              Icons.settings_outlined,
              color: SiftPillowyColors.onSurfaceVariant,
            ),
            tooltip: 'Settings',
            onPressed: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const SettingsScreen())),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: _CorrectionTipBanner(),
            ),
            Expanded(
              child: hasNothingToShow
                  ? const _EmptyState()
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                      children: [
                        if (processing.active)
                          _ProcessingCard(progress: processing)
                        else if (unprocessedCount > 0)
                          _ActionCard(
                            icon: Icons.hourglass_top_rounded,
                            // Amber, not the same green _ProcessingCard uses above
                            // — this branch only shows when nothing is actually
                            // running, which is the "needs attention" case, not
                            // the "in progress, all fine" one.
                            accent: SiftColors.warning,
                            accentSoft: SiftColors.warning,
                            title:
                                '$unprocessedCount screenshot'
                                '${unprocessedCount == 1 ? '' : 's'} waiting to '
                                'be analyzed',
                            subtitle:
                                'Tagging is stuck — usually a used-up AI '
                                'quota or no key set up yet. Add your own key in '
                                'Settings to unblock it.',
                            cta: 'Open Settings',
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const SettingsScreen(),
                              ),
                            ),
                          ),
                        if (duplicateCount > 0)
                          _ActionCard(
                            icon: Icons.content_copy_rounded,
                            accent: SiftPillowyColors.secondary,
                            accentSoft: SiftPillowyColors.secondaryContainer,
                            title:
                                '$duplicateCount duplicate group'
                                '${duplicateCount == 1 ? '' : 's'} found',
                            subtitle:
                                'Screenshots that look like the same shot — review '
                                'and free up space.',
                            cta: 'Review duplicates',
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const DuplicateReviewScreen(),
                              ),
                            ),
                          ),
                        if (junkCount > 0)
                          _ActionCard(
                            icon: Icons.auto_delete_outlined,
                            accent: SiftPillowyColors.primary,
                            accentSoft: SiftPillowyColors.primaryContainer,
                            title:
                                '$junkCount junk screenshot'
                                '${junkCount == 1 ? '' : 's'} to clear out',
                            subtitle:
                                'Swipe through and keep or delete each one.',
                            cta: 'Review junk',
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const JunkReviewScreen(),
                              ),
                            ),
                          ),
                        if (hasPurgeable)
                          _ActionCard(
                            icon: Icons.delete_sweep_outlined,
                            accent: SiftPillowyColors.error,
                            accentSoft: SiftPillowyColors.error,
                            title: '${purgeResult.formattedSize} reclaimable',
                            subtitle:
                                '${purgeResult.count} old junk/meme/to-do '
                                'screenshot${purgeResult.count == 1 ? '' : 's'}, '
                                'over 30 days old, nobody has acted on.',
                            cta: 'Review & delete',
                            onTap: () =>
                                _confirmPurge(context, ref, purgeResult),
                          ),
                        memoriesAsync.when(
                          data: (memories) => memories.isEmpty
                              ? const SizedBox.shrink()
                              : _MemoriesSection(memories: memories),
                          loading: () => const SizedBox.shrink(),
                          error: (_, __) => const SizedBox.shrink(),
                        ),
                        if (recentCorrections > 0)
                          _LearningCard(correctionCount: recentCorrections),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Same confirm-then-delete flow as PurgeBanner (Organize's version of this
/// same PurgeService), reused here rather than re-derived — the risk of a
/// destructive action needing its own logic twice is a mismatch, not a
/// styling difference. Deliberately doesn't hardcode a dialog background or
/// text color the way the old banner's AlertDialog did — the app's default
/// dialog theme already resolves from SiftColors' current brightness, so
/// leaving it unstyled is what keeps this correct in both Light and Dark
/// instead of risking the exact hardcoded-color mismatch the paywall sheet
/// had.
Future<void> _confirmPurge(
  BuildContext context,
  WidgetRef ref,
  PurgeResult result,
) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Delete these screenshots?'),
      content: Text(
        'This permanently deletes ${result.count} screenshot'
        '${result.count == 1 ? '' : 's'} tagged as junk, memes, or to-do '
        'items that are over 30 days old (${result.formattedSize} freed). '
        'This can\'t be undone.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: SiftPillowyColors.error,
            foregroundColor: Colors.white,
          ),
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('Delete'),
        ),
      ],
    ),
  );

  if (confirmed == true && context.mounted) {
    final deleted = await ref
        .read(purgeServiceProvider.notifier)
        .executePurge();
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Deleted $deleted screenshots.')));
    }
  }
}

class _MemoriesSection extends StatelessWidget {
  final List<Memory> memories;
  const _MemoriesSection({required this.memories});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 10, left: 2),
          child: Text('On This Day', style: SiftPillowyText.headlineMd),
        ),
        ...memories.map(
          (memory) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _MemoryCard(memory: memory),
          ),
        ),
      ],
    );
  }
}

class _MemoryCard extends StatelessWidget {
  final Memory memory;
  const _MemoryCard({required this.memory});

  @override
  Widget build(BuildContext context) {
    final label =
        '${memory.yearsAgo} year${memory.yearsAgo == 1 ? '' : 's'} ago';
    final cover = memory.shots.first;
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => MemoryGridScreen(title: label, shots: memory.shots),
        ),
      ),
      child: Container(
        clipBehavior: Clip.antiAlias,
        height: 140,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          color: SiftPillowyColors.surfaceContainerLowest,
          boxShadow: [
            BoxShadow(
              color: SiftPillowyColors.primaryContainer.withOpacity(0.12),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.file(
              _safeFile(cover.filePath),
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) =>
                  Container(color: SiftPillowyColors.surfaceContainerHigh),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.0),
                    Colors.black.withOpacity(0.55),
                  ],
                ),
              ),
            ),
            Positioned(
              left: 16,
              right: 16,
              bottom: 14,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      label,
                      style: SiftPillowyText.labelSm.copyWith(
                        color: SiftPillowyColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${memory.shots.length} screenshot'
                    '${memory.shots.length == 1 ? '' : 's'} from '
                    '${_formatDate(cover.timestamp)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final Color accent;
  final Color accentSoft;
  final String title;
  final String subtitle;
  final String cta;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.accent,
    required this.accentSoft,
    required this.title,
    required this.subtitle,
    required this.cta,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: SiftPillowyColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: accentSoft.withOpacity(0.18),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: accentSoft.withOpacity(0.18),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: accent, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: SiftPillowyText.headlineSm),
                const SizedBox(height: 4),
                Text(subtitle, style: SiftPillowyText.bodySm),
                const SizedBox(height: 10),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(999),
                    onTap: onTap,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          cta,
                          style: SiftPillowyText.labelLg.copyWith(
                            color: accent,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.arrow_forward_rounded,
                          size: 16,
                          color: accent,
                        ),
                      ],
                    ),
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

/// Live progress, not a static count — [_ActionCard] above covers the
/// "stuck with a backlog" case with a tappable diagnostics link, but there's
/// nothing to tap while a batch is actually running (see
/// ProcessingProgressNotifier — the same live current/total Organize's own
/// processing banner already shows, adapted into a Discover-shaped card
/// instead of that banner's compact strip).
class _ProcessingCard extends StatelessWidget {
  final ProcessingProgressState progress;
  const _ProcessingCard({required this.progress});

  @override
  Widget build(BuildContext context) {
    const accent = SiftPillowyColors.tertiary;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: SiftPillowyColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: accent.withOpacity(0.18),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color: accent.withOpacity(0.18),
              shape: BoxShape.circle,
            ),
            child: const CircularProgressIndicator(
              strokeWidth: 2.5,
              color: accent,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Analyzing ${progress.current} of ${progress.total} '
                  'screenshots',
                  style: SiftPillowyText.headlineSm,
                ),
                const SizedBox(height: 4),
                Text(
                  'Tags, duplicates, and junk review will fill in as each '
                  'one finishes.',
                  style: SiftPillowyText.bodySm,
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: progress.fraction,
                    minHeight: 4,
                    backgroundColor: SiftPillowyColors.surfaceContainerHigh,
                    color: accent,
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

/// A small "did you know" fact, not an action card — nothing to tap, since
/// the point is just making the previously-invisible correction-learning
/// system (TagCorrectionService) visible somewhere for the first time.
/// Real count, no invented streak or running total: exactly what
/// [TagCorrectionService.recentCorrectionCount] found in the local log.
class _LearningCard extends StatelessWidget {
  final int correctionCount;
  const _LearningCard({required this.correctionCount});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: SiftPillowyColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Icon(
            Icons.psychology_outlined,
            color: SiftPillowyColors.onSurfaceVariant,
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Sift learned from $correctionCount tag correction'
              '${correctionCount == 1 ? '' : 's'} you made this week.',
              style: SiftPillowyText.bodySm,
            ),
          ),
        ],
      ),
    );
  }
}

/// Promotional/educational nudge for the tag-correction reward — pinned
/// above the scrolling content (see build()) so it stays visible even on
/// the true empty state, unlike [_LearningCard] below which only appears
/// once someone has actually earned something. Dismissal is session-local
/// (setState, not persisted) — the same pattern Organize's own
/// _ApiKeyWarningBanner already uses for "seen it, go away for now".
class _CorrectionTipBanner extends StatefulWidget {
  const _CorrectionTipBanner();

  @override
  State<_CorrectionTipBanner> createState() => _CorrectionTipBannerState();
}

class _CorrectionTipBannerState extends State<_CorrectionTipBanner> {
  bool _dismissed = false;

  @override
  Widget build(BuildContext context) {
    if (_dismissed) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: SiftPillowyColors.primaryContainer.withOpacity(0.14),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: SiftPillowyColors.primary.withOpacity(0.25),
          width: 0.8,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: SiftPillowyColors.primary.withOpacity(0.18),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.bolt_rounded,
              color: SiftPillowyColors.primary,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        'Earn scans by correcting tags',
                        style: SiftPillowyText.headlineSm,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => setState(() => _dismissed = true),
                      child: Padding(
                        padding: const EdgeInsets.only(left: 8, top: 2),
                        child: Icon(
                          Icons.close_rounded,
                          size: 18,
                          color: SiftPillowyColors.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Fix a tag Sift got wrong and earn +$kCorrectionRewardEnergy '
                  'AI energy — up to $kMaxCorrectionRewardPerDay a day.',
                  style: SiftPillowyText.bodySm,
                ),
                const SizedBox(height: 10),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(999),
                    onTap: () => _showCorrectionInfoSheet(context),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'How it works',
                          style: SiftPillowyText.labelLg.copyWith(
                            color: SiftPillowyColors.primary,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.arrow_forward_rounded,
                          size: 16,
                          color: SiftPillowyColors.primary,
                        ),
                      ],
                    ),
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

/// The banner's "How it works" tap target. A plain bottom sheet with its
/// own explicit (theme-aware, not hardcoded) background — the default
/// BottomSheetThemeData is transparent app-wide (see buildSiftTheme), so
/// every sheet in this app supplies its own container color; this one uses
/// SiftPillowyColors.surfaceContainerLowest rather than a fixed hex so it
/// doesn't repeat the paywall sheet's earlier hardcoded-background mistake.
void _showCorrectionInfoSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => Container(
      padding: EdgeInsets.fromLTRB(
        24,
        24,
        24,
        MediaQuery.of(ctx).padding.bottom + 24,
      ),
      decoration: BoxDecoration(
        color: SiftPillowyColors.surfaceContainerLowest,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: SiftPillowyColors.outline,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Row(
            children: [
              Icon(Icons.bolt_rounded, color: SiftPillowyColors.primary),
              const SizedBox(width: 10),
              Text(
                'Earn scans by correcting tags',
                style: SiftPillowyText.headlineMd,
              ),
            ],
          ),
          const SizedBox(height: 16),
          _InfoRow(
            number: '1',
            text:
                'Open any screenshot and edit the tags Sift assigned it — '
                'add one it missed, remove one that\'s wrong, or swap it '
                'for a better fit.',
          ),
          _InfoRow(
            number: '2',
            text:
                'Saving a real change (not just re-saving the same tags) '
                'earns +$kCorrectionRewardEnergy AI energy right away.',
          ),
          _InfoRow(
            number: '3',
            text:
                'Capped at $kMaxCorrectionRewardPerDay energy a day from '
                'corrections, so it rewards genuine fixes rather than '
                'farming the same screenshot on repeat.',
          ),
          _InfoRow(
            number: '4',
            text:
                'Your corrections also help Sift\'s tagging get smarter '
                'over time — for you, and for patterns other Sift users hit '
                'too.',
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Got it'),
            ),
          ),
        ],
      ),
    ),
  );
}

class _InfoRow extends StatelessWidget {
  final String number;
  final String text;
  const _InfoRow({required this.number, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 22,
            height: 22,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: SiftPillowyColors.primary.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Text(
              number,
              style: SiftPillowyText.labelSm.copyWith(
                color: SiftPillowyColors.primary,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: SiftPillowyText.bodyMd)),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                gradient: SiftPillowyColors.assistantAvatarGradient,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.auto_awesome_rounded,
                size: 36,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 20),
            Text('All caught up!', style: SiftPillowyText.headlineMd),
            const SizedBox(height: 8),
            Text(
              'No duplicates, no junk to review, and no memories from '
              'today in past years — check back another day.',
              textAlign: TextAlign.center,
              style: SiftPillowyText.bodyMd.copyWith(
                color: SiftPillowyColors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Thumbnails elsewhere in the app go through ScreenshotThumbnail, which
/// this deliberately doesn't reuse here — the memory card needs a raw
/// Image.file for its own gradient/text overlay treatment, not that
/// widget's own fixed presentation.
File _safeFile(String path) => File(path);

const _monthNames = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', //
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

/// Not pulling in `intl` for one date string — this app doesn't depend on
/// it anywhere else, and "Sep 7, 2024" needs nothing a package brings.
String _formatDate(DateTime d) =>
    '${_monthNames[d.month - 1]} ${d.day}, ${d.year}';
