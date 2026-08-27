import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sift/core/theme/app_theme.dart';
import 'package:sift/features/collections/collections_service.dart';
import 'package:sift/features/collections/domain/gallery_collection.dart';
import 'package:sift/features/collections/presentation/collection_detail_screen.dart';

class CollectionsScreen extends ConsumerStatefulWidget {
  const CollectionsScreen({super.key});

  @override
  ConsumerState<CollectionsScreen> createState() => _CollectionsScreenState();
}

class _CollectionsScreenState extends ConsumerState<CollectionsScreen> {
  // Membership counts live in SharedPreferences, one key per collection —
  // loaded on demand here rather than folded into CollectionsService's own
  // state, since most callers of that service only ever need the list of
  // collections, not every collection's member count up front.
  final Map<String, int> _counts = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadCounts());
  }

  Future<void> _loadCounts() async {
    final collections = ref.read(collectionsServiceProvider).value ?? [];
    final service = ref.read(collectionsServiceProvider.notifier);
    for (final c in collections) {
      final members = await service.membersOf(c.id);
      if (mounted) setState(() => _counts[c.id] = members.length);
    }
  }

  Future<void> _createCollection() async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: SiftColors.surface,
        title: const Text('New Collection',
            style: TextStyle(color: SiftColors.textPrimary)),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(color: SiftColors.textPrimary),
          decoration:
              const InputDecoration(hintText: 'e.g. Apartment hunting'),
          onSubmitted: (v) => Navigator.pop(ctx, v),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, controller.text),
            child: const Text('Create'),
          ),
        ],
      ),
    );
    if (name != null && name.trim().isNotEmpty) {
      await ref.read(collectionsServiceProvider.notifier).create(name.trim());
      _loadCounts();
    }
  }

  Future<void> _confirmDelete(GalleryCollection c) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: SiftColors.surface,
        title: const Text('Delete Collection?',
            style: TextStyle(color: SiftColors.textPrimary)),
        content: Text(
          'This removes "${c.name}" — the screenshots inside it are not '
          'deleted, just no longer grouped.',
          style: const TextStyle(color: SiftColors.textSecondary),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: SiftColors.danger,
                foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(collectionsServiceProvider.notifier).delete(c.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final collectionsAsync = ref.watch(collectionsServiceProvider);

    return Scaffold(
      backgroundColor: SiftColors.background,
      appBar: AppBar(
        backgroundColor: SiftColors.background,
        title: const Text('Collections'),
        actions: [
          IconButton(
              icon: const Icon(Icons.add), onPressed: _createCollection),
        ],
      ),
      body: collectionsAsync.when(
        data: (collections) {
          if (collections.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.folder_outlined,
                        size: 52, color: SiftColors.textTertiary),
                    const SizedBox(height: 12),
                    const Text('No collections yet.',
                        style: TextStyle(
                            color: SiftColors.textSecondary, fontSize: 15)),
                    const SizedBox(height: 6),
                    const Text(
                      'Group screenshots by whatever matters to you — '
                      'trips, projects, gift ideas.',
                      textAlign: TextAlign.center,
                      style:
                          TextStyle(color: SiftColors.textTertiary, fontSize: 13),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                        onPressed: _createCollection,
                        child: const Text('New Collection')),
                  ],
                ),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: collections.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final c = collections[index];
              return Container(
                decoration: BoxDecoration(
                  color: SiftColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: SiftColors.border, width: 0.5),
                ),
                child: ListTile(
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Color(c.colorValue).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.folder,
                        color: Color(c.colorValue), size: 20),
                  ),
                  title: Text(c.name,
                      style: const TextStyle(
                          color: SiftColors.textPrimary,
                          fontWeight: FontWeight.w600)),
                  subtitle: Text(
                    '${_counts[c.id] ?? '…'} screenshot'
                    '${_counts[c.id] == 1 ? '' : 's'}',
                    style: const TextStyle(
                        color: SiftColors.textTertiary, fontSize: 12),
                  ),
                  trailing: PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert,
                        color: SiftColors.textTertiary),
                    color: SiftColors.surfaceElevated,
                    onSelected: (value) {
                      if (value == 'delete') _confirmDelete(c);
                    },
                    itemBuilder: (context) => const [
                      PopupMenuItem(
                        value: 'delete',
                        child: Text('Delete',
                            style: TextStyle(color: SiftColors.danger)),
                      ),
                    ],
                  ),
                  onTap: () => Navigator.of(context)
                      .push(
                        MaterialPageRoute(
                            builder: (_) =>
                                CollectionDetailScreen(collection: c)),
                      )
                      .then((_) => _loadCounts()),
                ),
              );
            },
          );
        },
        loading: () => const Center(
            child: CircularProgressIndicator(color: SiftColors.accent)),
        error: (err, _) => Center(
            child: Text('Error: $err',
                style: const TextStyle(color: SiftColors.danger))),
      ),
    );
  }
}
