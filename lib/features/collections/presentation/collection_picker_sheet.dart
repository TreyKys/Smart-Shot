import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sift/core/theme/app_theme.dart';
import 'package:sift/features/collections/collections_service.dart';
import 'package:sift/features/collections/domain/gallery_collection.dart';

/// Bottom sheet for filing screenshots into a collection — pick an existing
/// one or create a new one inline. Shared by the gallery's multi-select bulk
/// actions and the image detail screen, so "add to collection" behaves the
/// same regardless of where it's triggered from.
Future<void> showCollectionPickerSheet(
  BuildContext context, {
  required List<int> screenshotIds,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _CollectionPickerSheet(screenshotIds: screenshotIds),
  );
}

class _CollectionPickerSheet extends ConsumerStatefulWidget {
  final List<int> screenshotIds;
  const _CollectionPickerSheet({required this.screenshotIds});

  @override
  ConsumerState<_CollectionPickerSheet> createState() =>
      _CollectionPickerSheetState();
}

class _CollectionPickerSheetState
    extends ConsumerState<_CollectionPickerSheet> {
  final _controller = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _addTo(GalleryCollection collection) async {
    setState(() => _busy = true);
    await ref
        .read(collectionsServiceProvider.notifier)
        .addScreenshots(collection.id, widget.screenshotIds);
    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Added ${widget.screenshotIds.length} to '
                '"${collection.name}"')),
      );
    }
  }

  Future<void> _createAndAdd() async {
    final name = _controller.text.trim();
    if (name.isEmpty) return;
    setState(() => _busy = true);
    final collection =
        await ref.read(collectionsServiceProvider.notifier).create(name);
    await ref
        .read(collectionsServiceProvider.notifier)
        .addScreenshots(collection.id, widget.screenshotIds);
    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Created "${collection.name}" and added '
                '${widget.screenshotIds.length}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final collectionsAsync = ref.watch(collectionsServiceProvider);
    final count = widget.screenshotIds.length;

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
          Text(
            'Add $count screenshot${count == 1 ? '' : 's'} to…',
            style: const TextStyle(
                color: SiftColors.textPrimary,
                fontSize: 17,
                fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 16),
          collectionsAsync.when(
            data: (collections) {
              if (collections.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    'No collections yet — create your first one below.',
                    style:
                        TextStyle(color: SiftColors.textTertiary, fontSize: 13),
                  ),
                );
              }
              return ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 240),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: collections.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 4),
                  itemBuilder: (context, index) {
                    final c = collections[index];
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: Color(c.colorValue).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.folder_outlined,
                            color: Color(c.colorValue), size: 18),
                      ),
                      title: Text(c.name,
                          style: const TextStyle(
                              color: SiftColors.textPrimary, fontSize: 14)),
                      onTap: _busy ? null : () => _addTo(c),
                    );
                  },
                ),
              );
            },
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(
                  child:
                      CircularProgressIndicator(color: SiftColors.accent)),
            ),
            error: (_, __) => const Text('Could not load collections.',
                style: TextStyle(color: SiftColors.danger)),
          ),
          const SizedBox(height: 12),
          const Divider(color: SiftColors.border, height: 1),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  enabled: !_busy,
                  style: const TextStyle(
                      color: SiftColors.textPrimary, fontSize: 14),
                  decoration: const InputDecoration(
                    hintText: 'New collection name',
                    border: OutlineInputBorder(),
                  ),
                  onSubmitted: (_) => _createAndAdd(),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _busy ? null : _createAndAdd,
                child: _busy
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.black))
                    : const Text('Create'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
