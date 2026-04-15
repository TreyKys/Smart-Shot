import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sift/core/theme/app_theme.dart';
import 'package:sift/features/economy/economy_service.dart';
import 'package:sift/features/gallery/data/gallery_repository.dart';
import 'package:sift/features/gallery/domain/screenshot.dart';
import 'package:sift/features/gallery/presentation/gallery_provider.dart';
import 'package:sift/features/gallery/presentation/image_detail_screen.dart';
import 'package:sift/features/gallery/presentation/widgets/sift_bottom_sheet.dart';
import 'package:sift/features/gallery/presentation/widgets/smart_indexing_dialog.dart';
import 'package:sift/features/gallery/services/background_service.dart';
import 'package:sift/features/monetization/quota_bar.dart';
import 'package:sift/features/pro/presentation/paywall_sheet.dart';
import 'package:sift/features/pro/pro_service.dart';
import 'package:sift/features/purge/presentation/purge_banner.dart';
import 'package:sift/features/search/search_provider.dart';

class GalleryScreen extends ConsumerStatefulWidget {
  const GalleryScreen({super.key});

  @override
  ConsumerState<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends ConsumerState<GalleryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkSmartIndexingConsent();
      ref.read(economyServiceProvider.notifier).loadRewardedAd();
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

  @override
  Widget build(BuildContext context) {
    final searchQuery = ref.watch(searchQueryProvider);
    final isSearching = searchQuery.isNotEmpty;
    final selectedTag = ref.watch(selectedTagProvider);
    final isPro = ref.watch(proServiceProvider);
    final energyState = ref.watch(economyServiceProvider);

    final AsyncValue<List<Screenshot>> content = isSearching
        ? ref.watch(searchResultsProvider)
        : ref.watch(galleryStreamProvider);

    final costBadge = energyState.when(
      data: (_) {
        final cost = ref.read(economyServiceProvider.notifier).getTotalCostUsd();
        return '\$${cost.toStringAsFixed(4)}';
      },
      loading: () => '\$0.0000',
      error: (_, __) => '\$0.0000',
    );

    return Scaffold(
      backgroundColor: SiftColors.background,
      appBar: AppBar(
        backgroundColor: SiftColors.background,
        title: Text(
          selectedTag != null ? selectedTag : 'sift',
          style: TextStyle(
            color: selectedTag != null ? SiftColors.accent : SiftColors.textPrimary,
            fontSize: 22,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
        actions: [
          // Cost transparency badge
          if (!isPro)
            GestureDetector(
              onTap: () {},
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 8),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: SiftColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: SiftColors.border, width: 0.5),
                ),
                child: Text(
                  costBadge,
                  style: const TextStyle(
                    color: SiftColors.textTertiary,
                    fontSize: 11,
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.menu, color: SiftColors.textSecondary),
            onPressed: () => showSiftBottomSheet(context),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
            child: SearchBar(
              hintText: 'Search screenshots…',
              onChanged: (v) =>
                  ref.read(searchQueryProvider.notifier).setQuery(v),
              leading: const Icon(Icons.search, color: SiftColors.textTertiary, size: 18),
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
          // Purge banner
          const PurgeBanner(),

          // Quota bar (hidden for Pro)
          if (!isPro) const QuotaBar(),

          const SizedBox(height: 4),

          // Grid
          Expanded(
            child: content.when(
              data: (screenshots) {
                if (screenshots.isEmpty) {
                  return Center(
                    child: Text(
                      isSearching ? 'No results found.' : 'No screenshots yet.',
                      style: const TextStyle(
                          color: SiftColors.textSecondary, fontSize: 15),
                    ),
                  );
                }
                return MasonryGridView.count(
                  crossAxisCount: 2,
                  mainAxisSpacing: 6,
                  crossAxisSpacing: 6,
                  padding: const EdgeInsets.fromLTRB(12, 4, 12, 80),
                  itemCount: screenshots.length,
                  itemBuilder: (context, index) =>
                      _ScreenshotCard(screenshot: screenshots[index]),
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

      // Batch scan FAB
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: isPro ? SiftColors.proGold : SiftColors.accent,
        foregroundColor: Colors.black,
        onPressed: () => _triggerBatchScan(context, isPro),
        icon: const Icon(Icons.bolt, size: 20),
        label: Text(
          isPro ? 'Batch Scan' : 'Batch Scan (${kFreeBatchLimit})',
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
        ),
      ),
    );
  }

  Future<void> _triggerBatchScan(BuildContext context, bool isPro) async {
    if (!isPro) {
      final energy = await ref.read(economyServiceProvider.future);
      final byok = ref.read(economyServiceProvider.notifier).getByokKey();
      if (energy <= 0 && (byok == null || byok.isEmpty)) {
        showPaywallSheet(context, triggerFeature: 'Batch Scan');
        return;
      }
    }
    ref.read(galleryRepositoryProvider).runManualBatchScan(isPro: isPro);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              isPro ? 'Pro batch scan started…' : 'Scanning ${kFreeBatchLimit} screenshots…'),
        ),
      );
    }
  }
}

// ── Screenshot card ────────────────────────────────────────────────────────────

class _ScreenshotCard extends StatelessWidget {
  final Screenshot screenshot;
  const _ScreenshotCard({required this.screenshot});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ImageDetailScreen(screenshot: screenshot),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            color: SiftColors.surface,
            border: Border.all(color: SiftColors.border, width: 0.5),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Stack(
            children: [
              // Image
              AspectRatio(
                aspectRatio: 0.75,
                child: Image.file(
                  File(screenshot.filePath),
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const Center(
                    child: Icon(Icons.broken_image,
                        color: SiftColors.textTertiary, size: 32),
                  ),
                ),
              ),

              // Processing indicator (cyan bar at bottom)
              if (!screenshot.isProcessed)
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: LinearProgressIndicator(
                    value: null,
                    backgroundColor: SiftColors.border,
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(SiftColors.accent),
                    minHeight: 2,
                  ),
                ),

              // Processed checkmark
              if (screenshot.isProcessed)
                const Positioned(
                  top: 6,
                  right: 6,
                  child: _StatusDot(color: SiftColors.success),
                ),

              // Tags overlay
              if (screenshot.tags != null && screenshot.tags!.isNotEmpty)
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
                          color: color.withValues(alpha: 0.85),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          tag,
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
    );
  }
}

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
        boxShadow: [
          BoxShadow(color: color.withValues(alpha: 0.6), blurRadius: 4),
        ],
      ),
    );
  }
}
