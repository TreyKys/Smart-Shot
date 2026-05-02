import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sift/core/theme/app_theme.dart';
import 'package:sift/features/economy/economy_service.dart';
import 'package:sift/features/gallery/data/gallery_repository.dart';
import 'package:sift/features/gallery/domain/screenshot.dart';
import 'package:sift/features/gallery/presentation/gallery_provider.dart';
import 'package:sift/features/gallery/presentation/image_detail_screen.dart';
import 'package:sift/features/gallery/presentation/providers/processing_progress_provider.dart';
import 'package:sift/features/gallery/presentation/widgets/gallery_drawer.dart';
import 'package:sift/features/gallery/presentation/widgets/smart_indexing_dialog.dart';
import 'package:sift/features/gallery/services/background_service.dart';
import 'package:sift/features/monetization/quota_bar.dart';
import 'package:sift/features/purge/presentation/purge_banner.dart';
import 'package:sift/features/search/search_provider.dart';
import 'package:sift/features/settings/settings_screen.dart';

class GalleryScreen extends ConsumerStatefulWidget {
  const GalleryScreen({super.key});

  @override
  ConsumerState<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends ConsumerState<GalleryScreen> {
  bool _selectMode = false;
  final Set<int> _selectedIds = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _checkSmartIndexingConsent();
      ref.read(economyServiceProvider.notifier).loadRewardedAd();
      ref.read(galleryRepositoryProvider).reprocessGarbageTags();
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getStringList('pinned_ids') ?? [];
      final ids = raw.map((e) => int.tryParse(e)).whereType<int>().toSet();
      if (mounted) ref.read(pinnedIdsProvider.notifier).state = ids;
    });
  }

  Future<void> _checkSmartIndexingConsent() async {
    final prefs = await SharedPreferences.getInstance();
    final mode = prefs.getString('smart_indexing_mode');

    if (mode == null) {
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => SmartIndexingDialog(
          onLiveMode: () async {
            Navigator.of(context).pop();
            await prefs.setString('smart_indexing_mode', 'live');
            await prefs.setInt(
                'live_mode_timestamp', DateTime.now().millisecondsSinceEpoch);
            ref.read(galleryRepositoryProvider).syncGallery();
          },
          onDeepScan: () async {
            Navigator.of(context).pop();
            await prefs.setString('smart_indexing_mode', 'deep');
            scheduleDeepScan();
            ref.read(galleryRepositoryProvider).syncGallery();
          },
        ),
      );
    } else {
      if (mode == 'deep') scheduleDeepScan();
      ref.read(galleryRepositoryProvider).syncGallery();
    }
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
    final ids = List<int>.from(_selectedIds);
    _exitSelectMode();
    final repo = ref.read(galleryRepositoryProvider);
    for (final id in ids) {
      await repo.deleteScreenshot(id);
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Deleted ${ids.length} screenshot${ids.length == 1 ? '' : 's'}'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final searchQuery = ref.watch(searchQueryProvider);
    final isSearching = searchQuery.isNotEmpty;
    final selectedTag = ref.watch(selectedTagProvider);

    final AsyncValue<List<Screenshot>> content = isSearching
        ? ref.watch(searchResultsProvider)
        : ref.watch(galleryStreamProvider);

    return Scaffold(
      backgroundColor: SiftColors.background,
      drawer: const GalleryDrawer(),
      floatingActionButton: _selectMode
          ? _BulkActionsFab(
              count: _selectedIds.length,
              onDelete: _deleteSelected,
              onCancel: _exitSelectMode,
            )
          : null,
      appBar: AppBar(
        backgroundColor: SiftColors.background,
        title: selectedTag != null
            ? Text(
                selectedTag.startsWith('#') ? selectedTag.substring(1) : selectedTag,
                style: const TextStyle(
                  color: SiftColors.accent,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              )
            : const _SiftIcon(),
        leading: Builder(
          builder: (ctx) => IconButton(
            icon: const Icon(Icons.menu, color: SiftColors.textSecondary),
            onPressed: () => Scaffold.of(ctx).openDrawer(),
          ),
        ),
        actions: [
          if (_selectMode)
            TextButton(
              onPressed: _exitSelectMode,
              child: const Text('Cancel',
                  style: TextStyle(color: SiftColors.accent)),
            )
          else ...[
            IconButton(
              icon: const Icon(Icons.sync, color: SiftColors.textSecondary),
              tooltip: 'Sync gallery',
              onPressed: () =>
                  ref.read(galleryRepositoryProvider).syncGallery(),
              onLongPress: () {
                ref.read(galleryRepositoryProvider).reprocessAll();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Re-scanning all screenshots…')),
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
          _FilterChipBar(),
          const SizedBox(height: 4),
          Expanded(
            child: content.when(
              data: (screenshots) {
                if (screenshots.isEmpty) {
                  return _EmptyState(isSearching: isSearching);
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

// ── Filter chip bar ───────────────────────────────────────────────────────────

class _FilterChipBar extends ConsumerWidget {
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
                      color: isSelected
                          ? color
                          : SiftColors.textSecondary,
                      fontSize: 12,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.w400,
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

// ── Minimalist Sift icon ──────────────────────────────────────────────────────

class _SiftIcon extends StatelessWidget {
  const _SiftIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        color: SiftColors.accent.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
        border:
            Border.all(color: SiftColors.accent.withOpacity(0.5), width: 1),
      ),
      child: const Center(
        child: Icon(Icons.filter_alt, color: SiftColors.accent, size: 18),
      ),
    );
  }
}

// ── Screenshot card ───────────────────────────────────────────────────────────

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

                // Scanning bar
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

                // Processed dot
                if (screenshot.isProcessed && !isSelectMode)
                  const Positioned(
                    top: 6,
                    right: 6,
                    child: _StatusDot(color: SiftColors.success),
                  ),

                // Pin indicator
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

                // Select mode overlay
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

                // Tags overlay
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

// ── Bulk actions FAB ──────────────────────────────────────────────────────────

class _BulkActionsFab extends StatelessWidget {
  final int count;
  final VoidCallback onDelete;
  final VoidCallback onCancel;

  const _BulkActionsFab(
      {required this.count,
      required this.onDelete,
      required this.onCancel});

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
        FloatingActionButton.small(
          heroTag: 'bulk_cancel',
          onPressed: onCancel,
          backgroundColor: SiftColors.surfaceElevated,
          child:
              const Icon(Icons.close, color: SiftColors.textSecondary),
        ),
      ],
    );
  }
}

// ── Status dot ────────────────────────────────────────────────────────────────

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

// ── Processing progress banner ────────────────────────────────────────────────

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

// ── API key warning banner ─────────────────────────────────────────────────────

class _ApiKeyWarningBanner extends ConsumerStatefulWidget {
  @override
  ConsumerState<_ApiKeyWarningBanner> createState() =>
      _ApiKeyWarningBannerState();
}

class _ApiKeyWarningBannerState extends ConsumerState<_ApiKeyWarningBanner> {
  bool _dismissed = false;

  bool _noKey() {
    final envKey = dotenv.env['GEMINI_API_KEY'] ?? '';
    final byokKey =
        ref.read(economyServiceProvider.notifier).getByokKey() ?? '';
    return envKey.isEmpty && byokKey.isEmpty;
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
                'No Gemini API key — AI tagging disabled. Tap to add one in Settings.',
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

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final bool isSearching;
  const _EmptyState({required this.isSearching});

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
              style:
                  TextStyle(color: SiftColors.textTertiary, fontSize: 13),
            ),
          ],
        ],
      ),
    );
  }
}
