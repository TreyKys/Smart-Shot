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
    final isar = await ref.read(isarProvider.future);
    await isar.writeTxn(() async {
      shot.junkReviewed = true;
      await isar.screenshots.put(shot);
    });
    _removeTop(kept: true);
  }

  Future<void> _delete(Screenshot shot) async {
    await ref.read(galleryRepositoryProvider).deleteScreenshot(shot.id);
    _removeTop(kept: false);
  }

  void _removeTop({required bool kept}) {
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
      backgroundColor: SiftColors.background,
      appBar: AppBar(
        backgroundColor: SiftColors.background,
        title: const Text('Review Junk'),
        actions: [
          if (batch != null && batch.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Text(
                  '${_totalInBatch - batch.length + 1} of $_totalInBatch',
                  style: const TextStyle(
                      color: SiftColors.textTertiary, fontSize: 13),
                ),
              ),
            ),
        ],
      ),
      body: batch == null
          ? const Center(
              child: CircularProgressIndicator(color: SiftColors.accent))
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
                color: SiftColors.success,
                icon: Icons.check_circle_outline,
                label: 'Keep',
              ),
              secondaryBackground: _swipeBackground(
                alignment: Alignment.centerRight,
                color: SiftColors.danger,
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
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _ActionButton(
                icon: Icons.check_circle_outline,
                label: 'Keep',
                color: SiftColors.success,
                onTap: () => onKeep(top),
              ),
              _ActionButton(
                icon: Icons.delete_outline,
                label: 'Delete',
                color: SiftColors.danger,
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
      padding: const EdgeInsets.symmetric(horizontal: 28),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.5)),
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
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: SiftColors.surfaceElevated,
          border: Border.all(color: SiftColors.border, width: 0.8),
        ),
        child: Column(
          children: [
            Expanded(
              child: ScreenshotThumbnail(filePath: shot.filePath),
            ),
            if ((shot.topic ?? '').isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(12),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    shot.topic!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: SiftColors.textSecondary, fontSize: 13),
                  ),
                ),
              ),
          ],
        ),
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
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withOpacity(0.15),
              border: Border.all(color: color.withOpacity(0.5), width: 1.5),
            ),
            child: Icon(icon, color: color, size: 26),
          ),
          const SizedBox(height: 6),
          Text(label,
              style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
        ],
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
            const Icon(Icons.celebration_outlined,
                size: 48, color: SiftColors.accent),
            const SizedBox(height: 16),
            const Text('All caught up!',
                style: TextStyle(
                    color: SiftColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text(
              'Kept $kept, deleted $deleted.',
              style: const TextStyle(
                  color: SiftColors.textSecondary, fontSize: 14),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Done'),
            ),
          ],
        ),
      ),
    );
  }
}
