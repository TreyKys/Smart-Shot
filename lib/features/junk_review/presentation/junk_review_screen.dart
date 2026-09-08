import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sift/core/database/isar_service.dart';
import 'package:sift/core/theme/app_theme.dart';
import 'package:sift/features/gallery/data/gallery_repository.dart';
import 'package:sift/features/gallery/domain/screenshot.dart';
import 'package:sift/features/gallery/presentation/widgets/screenshot_thumbnail.dart';
import 'package:sift/features/junk_review/junk_review_service.dart';

/// Works through one sitting's batch of #Junk screenshots one at a time —
/// swipe left to delete, right to keep. Reached either from the drawer or
/// from tapping the "junk ready to review" notification (see
/// notification_service.dart's payload routing).
///
/// Deletion here is immediate with no undo, same as everywhere else
/// swipe-to-delete exists in this app (see AssistantScreen's doc comment) —
/// consistent, not a new risk this screen introduces. "Keep" just marks the
/// item reviewed so it stops showing up in future batches; it doesn't touch
/// the #Junk tag itself.
class JunkReviewScreen extends ConsumerStatefulWidget {
  const JunkReviewScreen({super.key});

  @override
  ConsumerState<JunkReviewScreen> createState() => _JunkReviewScreenState();
}

class _JunkReviewScreenState extends ConsumerState<JunkReviewScreen> {
  List<Screenshot>? _batch;
  int _totalInBatch = 0;
  int _keptCount = 0;
  int _deletedCount = 0;
  // Neither the swipe gesture nor the Keep/Delete buttons disable themselves
  // while a keep/delete is in flight (deleteScreenshot does real file I/O
  // plus an Isar write). Without this guard, a rapid double-tap or a
  // tap-then-swipe on the same card fires _keep/_delete twice before the
  // first setState ever runs — both calls capture the same "top" via a
  // StatelessWidget that hasn't rebuilt yet, so the second call's
  // _removeTop still blindly removes whatever is now at index 0. After the
  // first call's removal that's a DIFFERENT, never-reviewed screenshot,
  // which then silently disappears from this batch (not deleted — just
  // skipped) and skews the kept/deleted counts shown at the end.
  bool _processing = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final repo = ref.read(galleryRepositoryProvider);
    final batch = await loadJunkBatch(repo);
    if (mounted) {
      setState(() {
        _batch = batch;
        _totalInBatch = batch.length;
      });
    }
  }

  Future<void> _keep(Screenshot shot) async {
    if (_processing) return;
    _processing = true;
    final isar = await ref.read(isarProvider.future);
    await isar.writeTxn(() async {
      shot.junkReviewed = true;
      await isar.screenshots.put(shot);
    });
    _removeTop(kept: true);
  }

  Future<void> _delete(Screenshot shot) async {
    if (_processing) return;
    _processing = true;
    await ref.read(galleryRepositoryProvider).deleteScreenshot(shot.id);
    _removeTop(kept: false);
  }

  void _removeTop({required bool kept}) {
    _processing = false;
    if (!mounted) return;
    setState(() {
      _batch!.removeAt(0);
      if (kept) {
        _keptCount++;
      } else {
        _deletedCount++;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final batch = _batch;
    return Scaffold(
      backgroundColor: SiftPillowyColors.surface,
      appBar: AppBar(
        backgroundColor: SiftPillowyColors.surfaceContainerLowest,
        elevation: 0,
        iconTheme: const IconThemeData(color: SiftPillowyColors.onSurface),
        title: const Text('Review Junk', style: SiftPillowyText.headlineSm),
        actions: [
          if (batch != null && batch.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: SiftPillowyColors.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '${_totalInBatch - batch.length + 1} of $_totalInBatch',
                    style: SiftPillowyText.labelMd
                        .copyWith(color: SiftPillowyColors.onSurfaceVariant),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: batch == null
          ? const Center(
              child: CircularProgressIndicator(
                  color: SiftPillowyColors.primary))
          : batch.isEmpty
              ? _DoneState(kept: _keptCount, deleted: _deletedCount)
              : _ReviewStack(
                  batch: batch,
                  onKeep: _keep,
                  onDelete: _delete,
                ),
    );
  }
}

class _ReviewStack extends StatelessWidget {
  final List<Screenshot> batch;
  final void Function(Screenshot) onKeep;
  final void Function(Screenshot) onDelete;

  const _ReviewStack({
    required this.batch,
    required this.onKeep,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final top = batch.first;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: Column(
        children: [
          Expanded(
            child: Dismissible(
              // Keyed on the file path, not the Isar id — id alone would be
              // fine too, but a Dismissible re-keyed on every new "top of
              // stack" item is what actually lets it animate cleanly for
              // each successive card rather than reusing stale state.
              key: ValueKey(top.filePath),
              direction: DismissDirection.horizontal,
              background: _swipeBackground(
                alignment: Alignment.centerLeft,
                color: SiftPillowyColors.tertiary,
                icon: Icons.check_circle_outline,
                label: 'Keep',
              ),
              secondaryBackground: _swipeBackground(
                alignment: Alignment.centerRight,
                color: SiftPillowyColors.primary,
                icon: Icons.delete_outline,
                label: 'Delete',
              ),
              onDismissed: (direction) {
                if (direction == DismissDirection.startToEnd) {
                  onKeep(top);
                } else {
                  onDelete(top);
                }
              },
              child: _JunkCard(shot: top),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _ActionButton(
                icon: Icons.check_circle_outline,
                label: 'Keep',
                color: SiftPillowyColors.tertiary,
                onTap: () => onKeep(top),
              ),
              _ActionButton(
                icon: Icons.delete_outline,
                label: 'Delete',
                color: SiftPillowyColors.primary,
                onTap: () => onDelete(top),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _swipeBackground({
    required Alignment alignment,
    required Color color,
    required IconData icon,
    required String label,
  }) {
    return Container(
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: 32),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _JunkCard extends StatelessWidget {
  final Screenshot shot;
  const _JunkCard({required this.shot});

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
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
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: ScreenshotThumbnail(filePath: shot.filePath),
              ),
            ),
          ),
          if ((shot.topic ?? '').isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  shot.topic!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: SiftPillowyText.bodySm,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color,
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.35),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                  BoxShadow(
                    color: Colors.white.withOpacity(0.4),
                    blurRadius: 0,
                    offset: const Offset(0, 1),
                    spreadRadius: -1,
                  ),
                ],
              ),
              child: Icon(icon, color: Colors.white, size: 28),
            ),
            const SizedBox(height: 8),
            Text(label,
                style: SiftPillowyText.labelMd.copyWith(color: color)),
          ],
        ),
      ),
    );
  }
}

class _DoneState extends StatelessWidget {
  final int kept;
  final int deleted;
  const _DoneState({required this.kept, required this.deleted});

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
              child: const Icon(Icons.celebration_rounded,
                  size: 36, color: Colors.white),
            ),
            const SizedBox(height: 20),
            const Text('All caught up!', style: SiftPillowyText.headlineMd),
            const SizedBox(height: 8),
            Text('Kept $kept, deleted $deleted.',
                style: SiftPillowyText.bodyMd
                    .copyWith(color: SiftPillowyColors.onSurfaceVariant)),
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
