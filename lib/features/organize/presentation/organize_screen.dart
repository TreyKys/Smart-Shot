import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:sift/core/config/shared_key_service.dart';
import 'package:sift/core/database/isar_service.dart';
import 'package:sift/core/theme/app_theme.dart';
import 'package:sift/features/collections/presentation/collection_picker_sheet.dart';
import 'package:sift/features/economy/economy_service.dart';
import 'package:sift/features/gallery/data/gallery_repository.dart';
import 'package:sift/features/gallery/domain/screenshot.dart';
import 'package:sift/features/gallery/presentation/gallery_provider.dart';
import 'package:sift/features/gallery/presentation/image_detail_screen.dart';
import 'package:sift/features/gallery/presentation/providers/processing_progress_provider.dart';
import 'package:sift/features/gallery/presentation/widgets/screenshot_thumbnail.dart';
import 'package:sift/features/ingestion/services/tag_engine.dart';
import 'package:sift/features/learning/tag_correction_service.dart';
import 'package:sift/features/monetization/quota_bar.dart';
import 'package:sift/features/purge/presentation/purge_banner.dart';
import 'package:sift/features/search/search_provider.dart';
import 'package:sift/features/settings/settings_screen.dart';

/// Which of Organize's two views is showing — browse-by-tag cards, or the
/// full flat grid one tag (or "All Gallery") drills into.
///
/// This used to be two separate screens: a card grid here, and a full
/// GalleryScreen pushed as its own route (its own AppBar, its own drawer)
/// when you tapped a card. That read as two different apps stitched
/// together rather than one screen with a browse mode and a grid mode —
/// this enum is what replaced the route push, so "going into" a tag is now
/// just this screen changing what it shows, not navigating away from it.
enum _OrganizeView { clusters, grid }

/// Organize tab — browse-by-tag cards by default; drilling into a tag (or
/// "All Gallery") switches this same screen into the full screenshot grid
/// with search, batch select, and sync, rather than pushing a separate
/// screen. Tapping a card opens the existing (unmodified) ImageDetailScreen
/// for a single screenshot — that's still a real drill-down, not a
/// duplicate of this screen's own browsing.
class OrganizeScreen extends ConsumerStatefulWidget {
  const OrganizeScreen({super.key});

  @override
  ConsumerState<OrganizeScreen> createState() => _OrganizeScreenState();
}

class _OrganizeScreenState extends ConsumerState<OrganizeScreen> {
  _OrganizeView _view = _OrganizeView.clusters;
  bool _selectMode = false;
  final Set<int> _selectedIds = {};

  void _openGrid({String? tag}) {
    ref.read(selectedTagProvider.notifier).select(tag);
    setState(() => _view = _OrganizeView.grid);
  }

  void _backToClusters() {
    setState(() {
      _view = _OrganizeView.clusters;
      _selectMode = false;
      _selectedIds.clear();
    });
  }

  void _enterSelectMode(int id) {
    setState(() {
      _selectMode = true;
      _selectedIds.add(id);
    });
  }

  void _exitSelectMode() {
    setState(() {
      _selectMode = false;
      _selectedIds.clear();
    });
  }

  void _toggleSelect(int id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
        if (_selectedIds.isEmpty) _selectMode = false;
      } else {
        _selectedIds.add(id);
      }
    });
  }

  Future<void> _deleteSelected() async {
    final count = _selectedIds.length;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: SiftColors.surfaceElevated,
        title: const Text('Delete screenshots?',
            style: TextStyle(color: SiftColors.textPrimary)),
        content: Text(
          'This will permanently delete $count screenshot${count == 1 ? '' : 's'}.',
          style: const TextStyle(color: SiftColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete',
                style: TextStyle(color: SiftColors.danger)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final ids = List<int>.from(_selectedIds);
    _exitSelectMode();
    final repo = ref.read(galleryRepositoryProvider);
    for (final id in ids) {
      await repo.deleteScreenshot(id);
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Deleted ${ids.length} screenshot${ids.length == 1 ? '' : 's'}'),
        ),
      );
    }
  }

  void _tagSelected() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _BulkTagSheet(
        onApply: (tag) async {
          final ids = List<int>.from(_selectedIds);
          _exitSelectMode();
          final repo = ref.read(galleryRepositoryProvider);
          final correctionService = ref.read(tagCorrectionServiceProvider);
          int updated = 0;
          int rewardEnergy = 0;
          for (final id in ids) {
            final isar = await ref.read(isarProvider.future);
            final shot = await isar.screenshots.get(id);
            if (shot != null) {
              final oldTags = List<String>.from(shot.tags ?? []);
              if (!oldTags.contains(tag)) {
                final newTags = [...oldTags, tag];
                await repo.updateTags(id, newTags);
                updated++;
                final rewarded = await correctionService.recordCorrection(
                  textForKeywords: shot.cleanText ?? shot.ocrText ?? '',
                  fromTags: oldTags,
                  toTags: newTags,
                );
                if (rewarded) rewardEnergy += kCorrectionRewardEnergy;
              }
            }
          }
          if (mounted) {
            final label = tag.startsWith('#') ? tag.substring(1) : tag;
            final base =
                'Tagged $updated screenshot${updated == 1 ? '' : 's'} with $label';
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                    rewardEnergy > 0 ? '$base (+$rewardEnergy energy)' : base),
              ),
            );
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _view == _OrganizeView.grid
        ? _buildGrid(context)
        : _buildClusters(context);
  }

  // ── Clusters view — browse by tag ─────────────────────────────────────────

  Widget _buildClusters(BuildContext context) {
    final clustersAsync = ref.watch(tagClustersProvider);
    final totalAsync = ref.watch(totalScreenshotCountProvider);

    return Scaffold(
      backgroundColor: SiftPillowyColors.surface,
      appBar: AppBar(
        backgroundColor: SiftPillowyColors.surfaceContainerLowest,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text('Organize', style: SiftPillowyText.headlineSm),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: Center(
              child: _AllGalleryButton(onTap: () => _openGrid()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined,
                color: SiftPillowyColors.onSurfaceVariant),
            tooltip: 'Settings',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
        ],
      ),
      body: clustersAsync.when(
        data: (clusters) {
          if (clusters.isEmpty) {
            return _ClustersEmptyState(
                total: totalAsync.maybeWhen(data: (n) => n, orElse: () => null));
          }
          return GridView.builder(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.92,
            ),
            itemCount: clusters.length,
            itemBuilder: (context, i) {
              final cluster = clusters[i];
              return _ClusterCard(
                cluster: cluster,
                onTap: () => _openGrid(tag: cluster.tag),
              );
            },
          );
        },
        loading: () => const Center(
            child: CircularProgressIndicator(color: SiftPillowyColors.primary)),
        error: (err, _) => Center(
          child: Text('Error: $err',
              style:
                  SiftPillowyText.bodyMd.copyWith(color: SiftPillowyColors.error)),
        ),
      ),
    );
  }

  // ── Grid view — the real screenshot grid, search, and batch select ───────

  Widget _buildGrid(BuildContext context) {
    final searchQuery = ref.watch(searchQueryProvider);
    final isSearching = searchQuery.isNotEmpty;
    final selectedTag = ref.watch(selectedTagProvider);

    final AsyncValue<List<Screenshot>> content = isSearching
        ? ref.watch(searchResultsProvider)
        : ref.watch(galleryStreamProvider);

    return Scaffold(
      backgroundColor: SiftColors.background,
      floatingActionButton: _selectMode
          ? _BulkActionsFab(
              count: _selectedIds.length,
              onDelete: _deleteSelected,
              onTag: _tagSelected,
              onAddToCollection: () => showCollectionPickerSheet(
                context,
                screenshotIds: _selectedIds.toList(),
              ),
              onCancel: _exitSelectMode,
            )
          : null,
      appBar: AppBar(
        backgroundColor: SiftColors.background,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: SiftColors.textSecondary),
          onPressed: _backToClusters,
        ),
        title: selectedTag != null
            ? Text(
                selectedTag.startsWith('#')
                    ? selectedTag.substring(1)
                    : selectedTag,
                style: const TextStyle(
                  color: SiftColors.accent,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              )
            : const Text('All Screenshots',
                style: TextStyle(
                    color: SiftColors.textPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.w700)),
        actions: [
          if (_selectMode) ...[
            TextButton(
              onPressed: () {
                final currentContent = ref.read(
                  ref.read(searchQueryProvider).isNotEmpty
                      ? searchResultsProvider
                      : galleryStreamProvider,
                );
                currentContent.whenData((screenshots) {
                  setState(() {
                    if (_selectedIds.length == screenshots.length) {
                      _selectedIds.clear();
                      _selectMode = false;
                    } else {
                      _selectedIds
                        ..clear()
                        ..addAll(screenshots.map((s) => s.id));
                    }
                  });
                });
              },
              child: const Text('Select All',
                  style:
                      TextStyle(color: SiftColors.textSecondary, fontSize: 13)),
            ),
            TextButton(
              onPressed: _exitSelectMode,
              child: const Text('Cancel',
                  style: TextStyle(color: SiftColors.accent)),
            ),
          ] else ...[
            IconButton(
              icon: const Icon(Icons.sync, color: SiftColors.textSecondary),
              tooltip: 'Sync gallery',
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Syncing… check Settings → '
                          'Diagnostics Log for details.'),
                      duration: Duration(seconds: 2)),
                );
                ref.read(galleryRepositoryProvider).syncGallery();
              },
              onLongPress: () {
                ref.read(galleryRepositoryProvider).reprocessAll();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Re-scanning all screenshots…')),
                );
              },
            ),
          ],
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
            child: SearchBar(
              hintText: 'Search screenshots…',
              onChanged: (v) =>
                  ref.read(searchQueryProvider.notifier).setQuery(v),
              leading: const Icon(Icons.search,
                  color: SiftColors.textTertiary, size: 18),
              trailing: searchQuery.isNotEmpty
                  ? [
                      IconButton(
                        icon: const Icon(Icons.clear,
                            color: SiftColors.textSecondary, size: 18),
                        onPressed: () =>
                            ref.read(searchQueryProvider.notifier).setQuery(''),
                      )
                    ]
                  : null,
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          _ApiKeyWarningBanner(),
          const PurgeBanner(),
          _ProcessingBanner(),
          const QuotaBar(),
          _GridFilterChipBar(),
          const SizedBox(height: 4),
          Expanded(
            child: content.when(
              data: (screenshots) {
                if (screenshots.isEmpty) {
                  return _GridEmptyState(isSearching: isSearching);
                }
                final pinnedIds = ref.watch(pinnedIdsProvider);
                final sorted = List<Screenshot>.from(screenshots)
                  ..sort((a, b) {
                    final aPin = pinnedIds.contains(a.id) ? 0 : 1;
                    final bPin = pinnedIds.contains(b.id) ? 0 : 1;
                    return aPin.compareTo(bPin);
                  });
                return MasonryGridView.count(
                  crossAxisCount: 2,
                  mainAxisSpacing: 6,
                  crossAxisSpacing: 6,
                  padding: const EdgeInsets.fromLTRB(12, 4, 12, 80),
                  itemCount: sorted.length,
                  itemBuilder: (context, index) {
                    final shot = sorted[index];
                    return _ScreenshotCard(
                      screenshot: shot,
                      isSelectMode: _selectMode,
                      isSelected: _selectedIds.contains(shot.id),
                      onLongPress: () => _enterSelectMode(shot.id),
                      onSelect: () => _toggleSelect(shot.id),
                    );
                  },
                );
              },
              error: (err, _) => Center(
                child: Text('Error: $err',
                    style: const TextStyle(color: SiftColors.danger)),
              ),
              loading: () => const Center(
                  child: CircularProgressIndicator(color: SiftColors.accent)),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Cluster card ───────────────────────────────────────────────────────────

class _ClusterCard extends StatelessWidget {
  final TagCluster cluster;
  final VoidCallback onTap;
  const _ClusterCard({required this.cluster, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final label =
        cluster.tag.startsWith('#') ? cluster.tag.substring(1) : cluster.tag;
    final accent = SiftColors.forTag(cluster.tag);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          color: SiftPillowyColors.surfaceContainerLowest,
          boxShadow: [
            BoxShadow(
              color: SiftPillowyColors.primaryContainer.withOpacity(0.10),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            ScreenshotThumbnail(filePath: cluster.cover.filePath),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: const [0.4, 1.0],
                  colors: [
                    Colors.black.withOpacity(0.0),
                    Colors.black.withOpacity(0.65),
                  ],
                ),
              ),
            ),
            Positioned(
              top: 10,
              left: 10,
              child: Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  shape: BoxShape.circle,
                ),
                child: Icon(iconForTag(cluster.tag), size: 15, color: accent),
              ),
            ),
            Positioned(
              left: 12,
              right: 12,
              bottom: 10,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 14),
                  ),
                  Text(
                    '${cluster.count} screenshot${cluster.count == 1 ? '' : 's'}',
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.85), fontSize: 11),
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

class _AllGalleryButton extends StatelessWidget {
  final VoidCallback onTap;
  const _AllGalleryButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: SiftPillowyColors.surfaceContainerLow,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.grid_view_rounded,
                  size: 15, color: SiftPillowyColors.onSurfaceVariant),
              const SizedBox(width: 6),
              Text('All Gallery',
                  style: SiftPillowyText.labelMd
                      .copyWith(color: SiftPillowyColors.onSurfaceVariant)),
            ],
          ),
        ),
      ),
    );
  }
}

class _ClustersEmptyState extends StatelessWidget {
  final int? total;
  const _ClustersEmptyState({required this.total});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.style_outlined,
                size: 48, color: SiftPillowyColors.onSurfaceVariant),
            const SizedBox(height: 16),
            const Text('No tags yet', style: SiftPillowyText.headlineMd),
            const SizedBox(height: 8),
            Text(
              total == null || total == 0
                  ? 'Screenshots will be tagged automatically as they come in.'
                  : 'Your $total screenshot${total == 1 ? '' : 's'} '
                      "haven't been tagged yet — check back soon.",
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

// ── Grid-mode filter chip bar ─────────────────────────────────────────────

class _GridFilterChipBar extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tagsAsync = ref.watch(tagCountsProvider);
    final selectedTag = ref.watch(selectedTagProvider);

    return tagsAsync.when(
      data: (tags) {
        if (tags.isEmpty) return const SizedBox.shrink();
        return SizedBox(
          height: 40,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: tags.length,
            separatorBuilder: (_, __) => const SizedBox(width: 6),
            itemBuilder: (context, index) {
              final entry = tags[index];
              final tag = entry.tag;
              final isSelected = selectedTag == tag;
              final color = SiftColors.forTag(tag);
              final label = tag.startsWith('#') ? tag.substring(1) : tag;
              return GestureDetector(
                onTap: () => ref
                    .read(selectedTagProvider.notifier)
                    .select(isSelected ? null : tag),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? color.withOpacity(0.2)
                        : SiftColors.surfaceElevated,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected ? color : SiftColors.border,
                      width: isSelected ? 1.2 : 0.5,
                    ),
                  ),
                  child: Text(
                    label,
                    style: TextStyle(
                      color: isSelected ? color : SiftColors.textSecondary,
                      fontSize: 12,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

// ── Screenshot card (grid mode) ───────────────────────────────────────────

class _ScreenshotCard extends ConsumerWidget {
  final Screenshot screenshot;
  final bool isSelectMode;
  final bool isSelected;
  final VoidCallback? onLongPress;
  final VoidCallback? onSelect;

  const _ScreenshotCard({
    required this.screenshot,
    this.isSelectMode = false,
    this.isSelected = false,
    this.onLongPress,
    this.onSelect,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pinnedIds = ref.watch(pinnedIdsProvider);
    final isPinned = pinnedIds.contains(screenshot.id);

    return Dismissible(
      key: ValueKey(screenshot.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: SiftColors.danger.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete_outline,
            color: SiftColors.danger, size: 24),
      ),
      onDismissed: (_) {
        ref.read(galleryRepositoryProvider).deleteScreenshot(screenshot.id);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Screenshot deleted'),
            duration: Duration(seconds: 2),
          ),
        );
      },
      child: GestureDetector(
        onTap: () {
          if (isSelectMode) {
            onSelect?.call();
          } else {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ImageDetailScreen(screenshot: screenshot),
              ),
            );
          }
        },
        onLongPress: isSelectMode ? null : onLongPress,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Container(
            decoration: BoxDecoration(
              color: SiftColors.surface,
              border: Border.all(
                color: isSelected ? SiftColors.accent : SiftColors.border,
                width: isSelected ? 2 : 0.5,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Stack(
              children: [
                AspectRatio(
                  aspectRatio: 0.75,
                  child: Image.file(
                    File(screenshot.filePath),
                    cacheWidth: 300,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Center(
                      child: Icon(Icons.broken_image,
                          color: SiftColors.textTertiary, size: 32),
                    ),
                  ),
                ),
                if (!screenshot.isProcessed)
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: LinearProgressIndicator(
                      value: null,
                      backgroundColor: SiftColors.border,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                          SiftColors.accent),
                      minHeight: 2,
                    ),
                  ),
                if (screenshot.isProcessed && !isSelectMode)
                  const Positioned(
                    top: 6,
                    right: 6,
                    child: _StatusDot(color: SiftColors.success),
                  ),
                if (isPinned && !isSelectMode)
                  Positioned(
                    top: 6,
                    left: 6,
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: SiftColors.background.withOpacity(0.8),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.push_pin,
                          size: 12, color: SiftColors.accent),
                    ),
                  ),
                if (isSelectMode)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSelected
                            ? SiftColors.accent.withOpacity(0.2)
                            : Colors.black.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Align(
                        alignment: Alignment.topRight,
                        child: Padding(
                          padding: const EdgeInsets.all(6),
                          child: Container(
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? SiftColors.accent
                                  : Colors.transparent,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected
                                    ? SiftColors.accent
                                    : Colors.white,
                                width: 2,
                              ),
                            ),
                            child: isSelected
                                ? const Icon(Icons.check,
                                    size: 14, color: Colors.black)
                                : null,
                          ),
                        ),
                      ),
                    ),
                  ),
                if (!isSelectMode &&
                    screenshot.tags != null &&
                    screenshot.tags!.isNotEmpty)
                  Positioned(
                    left: 6,
                    right: 6,
                    bottom: 6,
                    child: Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: screenshot.tags!.take(2).map((tag) {
                        final color = SiftColors.forTag(tag);
                        return Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.85),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            tag.startsWith('#') ? tag.substring(1) : tag,
                            style: const TextStyle(
                              fontSize: 9,
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        );
                      }).toList(),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Bulk actions FAB ──────────────────────────────────────────────────────

class _BulkActionsFab extends StatelessWidget {
  final int count;
  final VoidCallback onDelete;
  final VoidCallback onTag;
  final VoidCallback onAddToCollection;
  final VoidCallback onCancel;

  const _BulkActionsFab({
    required this.count,
    required this.onDelete,
    required this.onTag,
    required this.onAddToCollection,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        FloatingActionButton.extended(
          heroTag: 'bulk_delete',
          onPressed: onDelete,
          backgroundColor: SiftColors.danger,
          icon: const Icon(Icons.delete_outline, color: Colors.white),
          label: Text(
            'Delete $count',
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.w600),
          ),
        ),
        const SizedBox(height: 10),
        FloatingActionButton.extended(
          heroTag: 'bulk_tag',
          onPressed: onTag,
          backgroundColor: SiftColors.surfaceElevated,
          icon: const Icon(Icons.label_outline, color: SiftColors.accent),
          label: const Text(
            'Tag Selected',
            style: TextStyle(
                color: SiftColors.textPrimary, fontWeight: FontWeight.w600),
          ),
        ),
        const SizedBox(height: 10),
        FloatingActionButton.extended(
          heroTag: 'bulk_collection',
          onPressed: onAddToCollection,
          backgroundColor: SiftColors.surfaceElevated,
          icon: const Icon(Icons.folder_outlined, color: SiftColors.accent),
          label: const Text(
            'Add to Collection',
            style: TextStyle(
                color: SiftColors.textPrimary, fontWeight: FontWeight.w600),
          ),
        ),
        const SizedBox(height: 10),
        FloatingActionButton.small(
          heroTag: 'bulk_cancel',
          onPressed: onCancel,
          backgroundColor: SiftColors.surfaceElevated,
          child: const Icon(Icons.close, color: SiftColors.textSecondary),
        ),
      ],
    );
  }
}

// ── Status dot ────────────────────────────────────────────────────────────

class _StatusDot extends StatelessWidget {
  final Color color;
  const _StatusDot({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: color.withOpacity(0.6), blurRadius: 4)],
      ),
    );
  }
}

// ── Processing progress banner ────────────────────────────────────────────

class _ProcessingBanner extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = ref.watch(processingProgressProvider);
    if (!p.active) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: SiftColors.surfaceElevated,
      child: Row(
        children: [
          const SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(
                strokeWidth: 2, color: SiftColors.accent),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Sifting ${p.current} of ${p.total} screenshots…',
              style: const TextStyle(
                  color: SiftColors.textSecondary, fontSize: 12),
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 80,
            child: LinearProgressIndicator(
              value: p.fraction,
              backgroundColor: SiftColors.border,
              color: SiftColors.accent,
              minHeight: 3,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ),
    );
  }
}

// ── API key warning banner ─────────────────────────────────────────────────

class _ApiKeyWarningBanner extends ConsumerStatefulWidget {
  @override
  ConsumerState<_ApiKeyWarningBanner> createState() =>
      _ApiKeyWarningBannerState();
}

class _ApiKeyWarningBannerState extends ConsumerState<_ApiKeyWarningBanner> {
  bool _dismissed = false;

  bool _noKey() {
    if (SharedKeyService.isConfigured) return false;
    final byokKey =
        ref.read(economyServiceProvider.notifier).getByokKey() ?? '';
    return byokKey.isEmpty;
  }

  @override
  Widget build(BuildContext context) {
    if (_dismissed || !_noKey()) return const SizedBox.shrink();
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const SettingsScreen()),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        color: SiftColors.warning.withOpacity(0.12),
        child: Row(
          children: [
            const Icon(Icons.warning_amber_rounded,
                color: SiftColors.warning, size: 16),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'No Mistral API key — AI tagging disabled. Tap to add one in Settings.',
                style: TextStyle(color: SiftColors.warning, fontSize: 12),
              ),
            ),
            GestureDetector(
              onTap: () => setState(() => _dismissed = true),
              child: const Icon(Icons.close,
                  color: SiftColors.textTertiary, size: 16),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Grid-mode empty state ──────────────────────────────────────────────────

class _GridEmptyState extends StatelessWidget {
  final bool isSearching;
  const _GridEmptyState({required this.isSearching});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isSearching ? Icons.search_off : Icons.photo_library_outlined,
            size: 52,
            color: SiftColors.textTertiary,
          ),
          const SizedBox(height: 12),
          Text(
            isSearching ? 'No results found.' : 'No screenshots yet.',
            style: const TextStyle(
                color: SiftColors.textSecondary, fontSize: 15),
          ),
          if (!isSearching) ...[
            const SizedBox(height: 6),
            const Text(
              'Tap the sync button to scan your gallery.',
              style: TextStyle(color: SiftColors.textTertiary, fontSize: 13),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Bulk tag bottom sheet ────────────────────────────────────────────────

class _BulkTagSheet extends ConsumerWidget {
  final Future<void> Function(String tag) onApply;

  const _BulkTagSheet({required this.onApply});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tagsAsync = ref.watch(uniqueTagsProvider);
    return Container(
      decoration: const BoxDecoration(
        color: SiftColors.surfaceElevated,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: SiftColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const Text('Add Tag to Selected',
              style: TextStyle(
                  color: SiftColors.textPrimary,
                  fontSize: 17,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          _BulkTagInput(onApply: onApply),
          const SizedBox(height: 16),
          const Text('Or pick an existing tag:',
              style: TextStyle(color: SiftColors.textTertiary, fontSize: 12)),
          const SizedBox(height: 8),
          tagsAsync.when(
            data: (tags) {
              if (tags.isEmpty) {
                return const Text('No tags yet.',
                    style: TextStyle(
                        color: SiftColors.textTertiary, fontSize: 13));
              }
              return Wrap(
                spacing: 8,
                runSpacing: 8,
                children: tags.map((tag) {
                  final color = SiftColors.forTag(tag);
                  return GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      onApply(tag);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: color.withOpacity(0.4), width: 0.8),
                      ),
                      child: Text(
                        tag.startsWith('#') ? tag.substring(1) : tag,
                        style: TextStyle(
                            color: color,
                            fontSize: 13,
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                  );
                }).toList(),
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

class _BulkTagInput extends StatefulWidget {
  final Future<void> Function(String tag) onApply;
  const _BulkTagInput({required this.onApply});

  @override
  State<_BulkTagInput> createState() => _BulkTagInputState();
}

class _BulkTagInputState extends State<_BulkTagInput> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final raw = _controller.text.trim();
    if (raw.isEmpty) return;
    final tag = TagEngine.normalize(raw);
    if (tag.isEmpty) return;
    Navigator.pop(context);
    widget.onApply(tag);
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _controller,
            style:
                const TextStyle(color: SiftColors.textPrimary, fontSize: 14),
            decoration: const InputDecoration(
              hintText: 'New tag (e.g. Finance)',
              prefixText: '# ',
              prefixStyle: TextStyle(color: SiftColors.accent),
            ),
            onSubmitted: (_) => _submit(),
            textInputAction: TextInputAction.done,
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          onPressed: _submit,
          icon: const Icon(Icons.check_circle, color: SiftColors.accent),
        ),
      ],
    );
  }
}
