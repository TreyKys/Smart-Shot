import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sift/core/theme/app_theme.dart';
import 'package:sift/features/discover/presentation/memory_grid_screen.dart';
import 'package:sift/features/duplicates/duplicate_service.dart';
import 'package:sift/features/duplicates/presentation/duplicate_review_screen.dart';
import 'package:sift/features/junk_review/junk_review_service.dart';
import 'package:sift/features/junk_review/presentation/junk_review_screen.dart';
import 'package:sift/features/memories/memories_service.dart';

/// Home tab — real, already-computed signals surfaced in one place instead
/// of requiring the drawer or a notification to find them: today's "on this
/// day" memories (real timestamps), duplicate clusters (the dHash index
/// this app already maintains), and unreviewed junk (the existing Junk
/// Review pipeline). No streaks, no XP, no fabricated "curator level" — see
/// the design conversation this screen came out of for why.
class DiscoverScreen extends ConsumerWidget {
  const DiscoverScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final memoriesAsync = ref.watch(memoriesProvider);
    final duplicatesAsync = ref.watch(duplicateClustersProvider);
    final junkCount = ref.watch(unreviewedJunkCountProvider).maybeWhen(
          data: (n) => n,
          orElse: () => 0,
        );

    final hasMemories =
        memoriesAsync.maybeWhen(data: (m) => m.isNotEmpty, orElse: () => false);
    final duplicateCount = duplicatesAsync.maybeWhen(
        data: (clusters) => clusters.length, orElse: () => 0);
    final isLoading = memoriesAsync.isLoading || duplicatesAsync.isLoading;
    final hasNothingToShow =
        !isLoading && !hasMemories && duplicateCount == 0 && junkCount == 0;

    return Scaffold(
      backgroundColor: SiftPillowyColors.surface,
      appBar: AppBar(
        backgroundColor: SiftPillowyColors.surfaceContainerLowest,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text('Discover', style: SiftPillowyText.headlineSm),
      ),
      body: SafeArea(
        child: hasNothingToShow
            ? const _EmptyState()
            : ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                children: [
                  if (duplicateCount > 0)
                    _ActionCard(
                      icon: Icons.content_copy_rounded,
                      accent: SiftPillowyColors.secondary,
                      accentSoft: SiftPillowyColors.secondaryContainer,
                      title: '$duplicateCount duplicate group'
                          '${duplicateCount == 1 ? '' : 's'} found',
                      subtitle:
                          'Screenshots that look like the same shot — review '
                          'and free up space.',
                      cta: 'Review duplicates',
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (_) => const DuplicateReviewScreen()),
                      ),
                    ),
                  if (junkCount > 0)
                    _ActionCard(
                      icon: Icons.auto_delete_outlined,
                      accent: SiftPillowyColors.primary,
                      accentSoft: SiftPillowyColors.primaryContainer,
                      title: '$junkCount junk screenshot'
                          '${junkCount == 1 ? '' : 's'} to clear out',
                      subtitle: 'Swipe through and keep or delete each one.',
                      cta: 'Review junk',
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (_) => const JunkReviewScreen()),
                      ),
                    ),
                  memoriesAsync.when(
                    data: (memories) => memories.isEmpty
                        ? const SizedBox.shrink()
                        : _MemoriesSection(memories: memories),
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                  ),
                ],
              ),
      ),
    );
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
        const Padding(
          padding: EdgeInsets.only(top: 8, bottom: 10, left: 2),
          child: Text('On This Day', style: SiftPillowyText.headlineMd),
        ),
        ...memories.map((memory) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _MemoryCard(memory: memory),
            )),
      ],
    );
  }
}

class _MemoryCard extends StatelessWidget {
  final Memory memory;
  const _MemoryCard({required this.memory});

  @override
  Widget build(BuildContext context) {
    final label = '${memory.yearsAgo} year${memory.yearsAgo == 1 ? '' : 's'} ago';
    final cover = memory.shots.first;
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => MemoryGridScreen(
            title: label,
            shots: memory.shots,
          ),
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
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      label,
                      style: SiftPillowyText.labelSm
                          .copyWith(color: SiftPillowyColors.primary),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${memory.shots.length} screenshot'
                    '${memory.shots.length == 1 ? '' : 's'} from '
                    '${_formatDate(cover.timestamp)}',
                    style: const TextStyle(
                        color: Colors.white,
                        fontFamily: 'Plus Jakarta Sans',
                        fontWeight: FontWeight.w600,
                        fontSize: 13),
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
                        Text(cta,
                            style: SiftPillowyText.labelLg
                                .copyWith(color: accent)),
                        const SizedBox(width: 4),
                        Icon(Icons.arrow_forward_rounded,
                            size: 16, color: accent),
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
              decoration: const BoxDecoration(
                gradient: SiftPillowyColors.assistantAvatarGradient,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.auto_awesome_rounded,
                  size: 36, color: Colors.white),
            ),
            const SizedBox(height: 20),
            const Text('All caught up!', style: SiftPillowyText.headlineMd),
            const SizedBox(height: 8),
            Text(
              'No duplicates, no junk to review, and no memories from '
              'today in past years — check back another day.',
              textAlign: TextAlign.center,
              style: SiftPillowyText.bodyMd
                  .copyWith(color: SiftPillowyColors.onSurfaceVariant),
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
String _formatDate(DateTime d) => '${_monthNames[d.month - 1]} ${d.day}, ${d.year}';
