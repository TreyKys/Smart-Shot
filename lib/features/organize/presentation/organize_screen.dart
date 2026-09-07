import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sift/core/theme/app_theme.dart';
import 'package:sift/features/gallery/presentation/gallery_provider.dart';
import 'package:sift/features/gallery/presentation/gallery_screen.dart';
import 'package:sift/features/gallery/presentation/widgets/screenshot_thumbnail.dart';

/// Real tag clusters — [tagClustersProvider]'s count and cover thumbnail per
/// tag, the same aggregation the drawer's plain list already computes, laid
/// out as cards instead of rows. Tapping a card opens the existing
/// (unmodified) GalleryScreen pre-filtered to that tag, rather than
/// reimplementing browsing/selection/delete a second time for this screen.
class OrganizeScreen extends ConsumerWidget {
  const OrganizeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
            padding: const EdgeInsets.only(right: 12),
            child: Center(
              child: _AllGalleryButton(
                onTap: () {
                  ref.read(selectedTagProvider.notifier).select(null);
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const GalleryScreen()),
                  );
                },
              ),
            ),
          ),
        ],
      ),
      body: clustersAsync.when(
        data: (clusters) {
          if (clusters.isEmpty) {
            return _EmptyState(total: totalAsync.maybeWhen(
                data: (n) => n, orElse: () => null));
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
                onTap: () {
                  ref.read(selectedTagProvider.notifier).select(cluster.tag);
                  Navigator.of(context).push(
                    MaterialPageRoute(
                        builder: (_) => const GalleryScreen()),
                  );
                },
              );
            },
          );
        },
        loading: () => const Center(
            child: CircularProgressIndicator(color: SiftPillowyColors.primary)),
        error: (err, _) => Center(
          child: Text('Error: $err',
              style: SiftPillowyText.bodyMd
                  .copyWith(color: SiftPillowyColors.error)),
        ),
      ),
    );
  }
}

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
                        fontFamily: 'Plus Jakarta Sans',
                        fontWeight: FontWeight.w700,
                        fontSize: 14),
                  ),
                  Text(
                    '${cluster.count} screenshot${cluster.count == 1 ? '' : 's'}',
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.85),
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 11),
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

class _EmptyState extends StatelessWidget {
  final int? total;
  const _EmptyState({required this.total});

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
