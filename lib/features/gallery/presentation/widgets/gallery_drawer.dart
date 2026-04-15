import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sift/features/gallery/presentation/gallery_provider.dart';

class GalleryDrawer extends ConsumerWidget {
  const GalleryDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tagsAsync = ref.watch(uniqueTagsProvider);
    final selectedTag = ref.watch(selectedTagProvider);

    return Drawer(
      child: Column(
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
            ),
            child: Center(
              child: Text(
                'Categories',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.grid_view),
            title: const Text('All Screenshots'),
            selected: selectedTag == null,
            onTap: () {
              ref.read(selectedTagProvider.notifier).select(null);
              Navigator.pop(context);
            },
          ),
          const Divider(),
          Expanded(
            child: tagsAsync.when(
              data: (tags) {
                if (tags.isEmpty) {
                  return const Center(child: Text("No tags yet."));
                }
                return ListView.builder(
                  itemCount: tags.length,
                  itemBuilder: (context, index) {
                    final tag = tags[index];
                    return ListTile(
                      leading: Icon(_getIconForTag(tag)),
                      title: Text(tag),
                      selected: selectedTag == tag,
                      onTap: () {
                        ref.read(selectedTagProvider.notifier).select(tag);
                        Navigator.pop(context);
                      },
                    );
                  },
                );
              },
              error: (err, stack) => Center(child: Text('Error: $err')),
              loading: () => const Center(child: CircularProgressIndicator()),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getIconForTag(String tag) {
    final lower = tag.toLowerCase().replaceAll('#', '');
    if (lower.contains('finance') || lower.contains('receipt') || lower.contains('money')) {
      return CupertinoIcons.money_dollar;
    }
    if (lower.contains('travel') || lower.contains('flight')) {
      return CupertinoIcons.airplane;
    }
    if (lower.contains('web3') || lower.contains('crypto') || lower.contains('btc') || lower.contains('eth')) {
      return CupertinoIcons.bitcoin;
    }
    if (lower.contains('code') || lower.contains('dev') || lower.contains('git')) {
      return CupertinoIcons.chevron_left_slash_chevron_right;
    }
    if (lower.contains('social') || lower.contains('instagram') || lower.contains('twitter') || lower.contains('x')) {
      return CupertinoIcons.person_2;
    }
    if (lower.contains('meme') || lower.contains('funny')) {
      return CupertinoIcons.smiley;
    }
    if (lower.contains('chem') || lower.contains('science') || lower.contains('lab')) {
      return CupertinoIcons.lab_flask;
    }
    if (lower.contains('date') || lower.contains('calendar') || lower.contains('schedule')) {
      return CupertinoIcons.calendar;
    }
    if (lower.contains('chart') || lower.contains('trading') || lower.contains('stock')) {
      return CupertinoIcons.graph_circle;
    }
    if (lower.contains('news') || lower.contains('article')) {
      return CupertinoIcons.news;
    }
    if (lower.contains('shop') || lower.contains('buy')) {
      return CupertinoIcons.shopping_cart;
    }
    if (lower.contains('music') || lower.contains('song')) {
      return CupertinoIcons.music_note;
    }
    if (lower.contains('video') || lower.contains('movie')) {
      return CupertinoIcons.film;
    }
    if (lower.contains('book') || lower.contains('read') || lower.contains('edu')) {
      return CupertinoIcons.book;
    }

    return CupertinoIcons.tag;
  }
}
