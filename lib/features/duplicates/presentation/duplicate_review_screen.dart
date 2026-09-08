import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sift/core/theme/app_theme.dart';
import 'package:sift/features/duplicates/duplicate_service.dart';
import 'package:sift/features/gallery/data/gallery_repository.dart';
import 'package:sift/features/gallery/domain/screenshot.dart';
import 'package:sift/features/gallery/presentation/widgets/screenshot_thumbnail.dart';

/// Works through the library's near-duplicate clusters one at a time —
/// found by [duplicateClustersProvider], which reuses the dHash fingerprint
/// this app already computes for every screenshot at ingest time (see
/// GalleryRepository.findDuplicateClusters). No new AI call, no per-cluster
/// "confidence %" invented for the occasion — a cluster is here because two
/// or more images really did hash within the same distance the app already
/// trusts to mean "these look the same."
///
/// Deletion is immediate with no undo, consistent with every other
/// swipe/delete flow in this app (Junk Review, the assistant's confirmed
/// deletes). The newest copy in each cluster is preselected to KEEP and
/// every older one preselected to DELETE — reversible per-item before
/// confirming, never applied without a look.
class DuplicateReviewScreen extends ConsumerStatefulWidget {
  const DuplicateReviewScreen({super.key});

  @override
  ConsumerState<DuplicateReviewScreen> createState() =>
      _DuplicateReviewScreenState();
}

class _DuplicateReviewScreenState
    extends ConsumerState<DuplicateReviewScreen> {
  List<List<Screenshot>>? _clusters;
  int _index = 0;
  int _deletedCount = 0;
  int _reclaimedBytes = 0;
  // Guards the confirm/skip actions the same way JunkReviewScreen's
  // _processing does — deleteScreenshot does real file I/O, so nothing here
  // should be double-triggered by an impatient extra tap before the first
  // call's setState lands.
  bool _busy = false;

  // Indices (within the CURRENT cluster) marked to delete. Reset every time
  // _index advances — see _resetSelectionForCurrentCluster.
  final Set<int> _markedForDeletion = {};
  List<int>? _sizes;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final clusters = await ref.read(duplicateClustersProvider.future);
    if (!mounted) return;
    setState(() {
      _clusters = clusters;
      _resetSelectionForCurrentCluster();
    });
  }

  /// Marks every member except the newest (index 0 — clusters are already
  /// sorted newest-first) for deletion by default, reversible per-item
  /// before confirming. Clears any previous cluster's file sizes first —
  /// otherwise the new cluster's tiles would briefly show the OLD cluster's
  /// sizes while _loadSizes' await is still in flight.
  void _resetSelectionForCurrentCluster() {
    final cluster = _currentCluster();
    _markedForDeletion
      ..clear()
      ..addAll([for (var i = 1; i < cluster.length; i++) i]);
    _sizes = null;
    _loadSizes();
  }

  List<Screenshot> _currentCluster() {
    final clusters = _clusters;
    if (clusters == null || _index >= clusters.length) return const [];
    return clusters[_index];
  }

  Future<void> _loadSizes() async {
    // Tagged with the cluster index it was loading for — if the user
    // advances again before this resolves (skip doesn't wait on it), a
    // slower stat() for the OLD cluster finishing after a newer one started
    // must not overwrite sizes for whatever cluster is showing by then.
    final requestedIndex = _index;
    final cluster = _currentCluster();
    final sizes = await Future.wait(cluster.map(fileSizeOf));
    if (mounted && _index == requestedIndex) setState(() => _sizes = sizes);
  }

  int get _selectedBytes {
    final sizes = _sizes;
    if (sizes == null) return 0;
    var total = 0;
    for (final i in _markedForDeletion) {
      if (i < sizes.length) total += sizes[i];
    }
    return total;
  }

  void _toggle(int i) {
    setState(() {
      if (!_markedForDeletion.remove(i)) _markedForDeletion.add(i);
    });
  }

  Future<void> _confirmAndAdvance() async {
    if (_busy) return;
    setState(() => _busy = true);
    final cluster = _currentCluster();
    final reclaimed = _selectedBytes;
    final repo = ref.read(galleryRepositoryProvider);
    for (final i in _markedForDeletion) {
      if (i < cluster.length) await repo.deleteScreenshot(cluster[i].id);
    }
    if (!mounted) return;
    setState(() {
      _deletedCount += _markedForDeletion.length;
      _reclaimedBytes += reclaimed;
      _index++;
      _busy = false;
      if (_index < (_clusters?.length ?? 0)) {
        _resetSelectionForCurrentCluster();
      }
    });
  }

  void _skip() {
    if (_busy) return;
    setState(() {
      _index++;
      if (_index < (_clusters?.length ?? 0)) {
        _resetSelectionForCurrentCluster();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final clusters = _clusters;
    return Scaffold(
      backgroundColor: SiftPillowyColors.surface,
      appBar: AppBar(
        backgroundColor: SiftPillowyColors.surfaceContainerLowest,
        elevation: 0,
        iconTheme: const IconThemeData(color: SiftPillowyColors.onSurface),
        title:
            const Text('Duplicates', style: SiftPillowyText.headlineSm),
        actions: [
          if (clusters != null && _index < clusters.length)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: SiftPillowyColors.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '${_index + 1} of ${clusters.length}',
                    style: SiftPillowyText.labelMd
                        .copyWith(color: SiftPillowyColors.onSurfaceVariant),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: clusters == null
          ? const Center(
              child: CircularProgressIndicator(
                  color: SiftPillowyColors.primary))
          : _index >= clusters.length
              ? _DoneState(
                  deletedCount: _deletedCount,
                  reclaimedBytes: _reclaimedBytes)
              : _ClusterView(
                  cluster: clusters[_index],
                  sizes: _sizes,
                  markedForDeletion: _markedForDeletion,
                  selectedBytes: _selectedBytes,
                  busy: _busy,
                  onToggle: _toggle,
                  onSkip: _skip,
                  onConfirm: _confirmAndAdvance,
                ),
    );
  }
}

class _ClusterView extends StatelessWidget {
  final List<Screenshot> cluster;
  final List<int>? sizes;
  final Set<int> markedForDeletion;
  final int selectedBytes;
  final bool busy;
  final void Function(int index) onToggle;
  final VoidCallback onSkip;
  final VoidCallback onConfirm;

  const _ClusterView({
    required this.cluster,
    required this.sizes,
    required this.markedForDeletion,
    required this.selectedBytes,
    required this.busy,
    required this.onToggle,
    required this.onSkip,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${cluster.length} screenshots look like the same shot',
            style: SiftPillowyText.headlineMd,
          ),
          const SizedBox(height: 4),
          Text(
            'Tap to keep or delete each one — the newest is kept by default.',
            style: SiftPillowyText.bodySm,
          ),
          const SizedBox(height: 16),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.8,
              ),
              itemCount: cluster.length,
              itemBuilder: (context, i) {
                final shot = cluster[i];
                final marked = markedForDeletion.contains(i);
                final size = sizes != null && i < sizes!.length
                    ? sizes![i]
                    : null;
                return _ClusterTile(
                  shot: shot,
                  isNewest: i == 0,
                  markedForDeletion: marked,
                  sizeLabel: size == null ? null : formatBytes(size),
                  onTap: () => onToggle(i),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          if (markedForDeletion.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text(
                'Deleting ${markedForDeletion.length} will free '
                '${formatBytes(selectedBytes)}.',
                style: SiftPillowyText.bodySm
                    .copyWith(color: SiftPillowyColors.onSurfaceVariant),
              ),
            ),
          Row(
            children: [
              Expanded(
                child: _PillButton(
                  label: 'Keep All',
                  filled: false,
                  color: SiftPillowyColors.onSurfaceVariant,
                  onTap: busy ? null : onSkip,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _PillButton(
                  label: markedForDeletion.isEmpty
                      ? 'Next'
                      : 'Delete ${markedForDeletion.length}',
                  filled: true,
                  color: markedForDeletion.isEmpty
                      ? SiftPillowyColors.primary
                      : SiftPillowyColors.error,
                  onTap: busy ? null : onConfirm,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ClusterTile extends StatelessWidget {
  final Screenshot shot;
  final bool isNewest;
  final bool markedForDeletion;
  final String? sizeLabel;
  final VoidCallback onTap;

  const _ClusterTile({
    required this.shot,
    required this.isNewest,
    required this.markedForDeletion,
    required this.sizeLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final accent =
        markedForDeletion ? SiftPillowyColors.error : SiftPillowyColors.tertiary;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: accent, width: 2.5),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            ScreenshotThumbnail(filePath: shot.filePath),
            if (markedForDeletion)
              Container(color: Colors.black.withOpacity(0.35)),
            Positioned(
              top: 8,
              left: 8,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: accent,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  markedForDeletion
                      ? 'Delete'
                      : (isNewest ? 'Newest' : 'Keep'),
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w700),
                ),
              ),
            ),
            if (sizeLabel != null)
              Positioned(
                bottom: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    sizeLabel!,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            Positioned(
              top: 8,
              right: 8,
              child: Icon(
                markedForDeletion
                    ? Icons.cancel_rounded
                    : Icons.check_circle_rounded,
                color: Colors.white,
                size: 20,
                shadows: const [Shadow(blurRadius: 4, color: Colors.black45)],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PillButton extends StatelessWidget {
  final String label;
  final Color color;
  final bool filled;
  final VoidCallback? onTap;

  const _PillButton({
    required this.label,
    required this.color,
    required this.filled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: filled ? color : Colors.transparent,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(vertical: 13),
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

class _DoneState extends StatelessWidget {
  final int deletedCount;
  final int reclaimedBytes;
  const _DoneState({required this.deletedCount, required this.reclaimedBytes});

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
            const Text('All clear!', style: SiftPillowyText.headlineMd),
            const SizedBox(height: 8),
            Text(
              deletedCount == 0
                  ? 'Nothing deleted — every duplicate was kept.'
                  : 'Deleted $deletedCount screenshot'
                      '${deletedCount == 1 ? '' : 's'}, freeing '
                      '${formatBytes(reclaimedBytes)}.',
              textAlign: TextAlign.center,
              style: SiftPillowyText.bodyMd
                  .copyWith(color: SiftPillowyColors.onSurfaceVariant),
            ),
            const SizedBox(height: 24),
            Material(
              color: SiftPillowyColors.primary,
              borderRadius: BorderRadius.circular(999),
              child: InkWell(
                borderRadius: BorderRadius.circular(999),
                onTap: () => Navigator.of(context).pop(),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                  child: Text('Done',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 14)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
