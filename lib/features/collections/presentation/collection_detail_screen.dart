import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sift/core/database/isar_service.dart';
import 'package:sift/core/theme/app_theme.dart';
import 'package:sift/features/collections/collections_service.dart';
import 'package:sift/features/collections/domain/gallery_collection.dart';
import 'package:sift/features/gallery/domain/screenshot.dart';
import 'package:sift/features/gallery/presentation/image_detail_screen.dart';
import 'package:sift/features/gallery/presentation/widgets/screenshot_thumbnail.dart';

class CollectionDetailScreen extends ConsumerStatefulWidget {
  final GalleryCollection collection;
  const CollectionDetailScreen({super.key, required this.collection});

  @override
  ConsumerState<CollectionDetailScreen> createState() =>
      _CollectionDetailScreenState();
}

class _CollectionDetailScreenState
    extends ConsumerState<CollectionDetailScreen> {
  List<Screenshot>? _shots;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final service = ref.read(collectionsServiceProvider.notifier);
    final ids = await service.membersOf(widget.collection.id);
    final isar = await ref.read(isarProvider.future);
    final shots = (await isar.screenshots.getAll(ids.toList()))
        .whereType<Screenshot>()
        .toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    if (mounted) setState(() => _shots = shots);
  }

  Future<void> _remove(Screenshot shot) async {
    await ref
        .read(collectionsServiceProvider.notifier)
        .removeScreenshots(widget.collection.id, [shot.id]);
    _load();
  }

  void _confirmRemove(Screenshot shot) {
    showModalBottomSheet(
      context: context,
      backgroundColor: SiftColors.surfaceElevated,
      builder: (ctx) => SafeArea(
        child: ListTile(
          leading:
              const Icon(Icons.remove_circle_outline, color: SiftColors.danger),
          title: const Text('Remove from collection',
              style: TextStyle(color: SiftColors.textPrimary)),
          subtitle: const Text('The screenshot itself is not deleted.',
              style: TextStyle(color: SiftColors.textTertiary, fontSize: 12)),
          onTap: () {
            Navigator.pop(ctx);
            _remove(shot);
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final shots = _shots;
    return Scaffold(
      backgroundColor: SiftColors.background,
      appBar: AppBar(
        backgroundColor: SiftColors.background,
        title: Text(widget.collection.name),
      ),
      body: shots == null
          ? const Center(
              child: CircularProgressIndicator(color: SiftColors.accent))
          : shots.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.photo_outlined,
                            size: 48, color: SiftColors.textTertiary),
                        SizedBox(height: 12),
                        Text('Nothing here yet.',
                            style: TextStyle(
                                color: SiftColors.textSecondary, fontSize: 15)),
                        const SizedBox(height: 6),
                        const Text(
                          'Long-press a screenshot in the gallery, or ask '
                          'the assistant, to add it here.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: SiftColors.textTertiary, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                )
              : GridView.builder(
                  padding: const EdgeInsets.all(12),
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    mainAxisSpacing: 6,
                    crossAxisSpacing: 6,
                  ),
                  itemCount: shots.length,
                  itemBuilder: (context, index) {
                    final shot = shots[index];
                    return GestureDetector(
                      onTap: () => Navigator.of(context)
                          .push(
                            MaterialPageRoute(
                                builder: (_) =>
                                    ImageDetailScreen(screenshot: shot)),
                          )
                          .then((_) => _load()),
                      onLongPress: () => _confirmRemove(shot),
                      child: ScreenshotThumbnail(filePath: shot.filePath),
                    );
                  },
                ),
    );
  }
}
