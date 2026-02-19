import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_shot/features/gallery/presentation/gallery_provider.dart';
import 'package:smart_shot/features/search/search_provider.dart';
import 'package:smart_shot/features/gallery/data/gallery_repository.dart';
import 'package:smart_shot/features/gallery/domain/screenshot.dart';

class GalleryScreen extends ConsumerWidget {
  const GalleryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final searchQuery = ref.watch(searchQueryProvider);
    final isSearching = searchQuery.isNotEmpty;

    final AsyncValue<List<Screenshot>> content = isSearching
        ? ref.watch(searchResultsProvider)
        : ref.watch(galleryStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('SmartShot'),
        actions: [
          IconButton(
            icon: const Icon(Icons.sync),
            onPressed: () {
               ref.read(galleryRepositoryProvider).syncGallery();
            },
          )
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: SearchBar(
              hintText: "Search screenshots...",
              onChanged: (value) {
                ref.read(searchQueryProvider.notifier).setQuery(value);
              },
              leading: const Icon(Icons.search),
              trailing: searchQuery.isNotEmpty
                  ? [
                      IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          ref.read(searchQueryProvider.notifier).setQuery('');
                        },
                      )
                    ]
                  : null,
            ),
          ),
        ),
      ),
      body: content.when(
        data: (screenshots) {
          if (screenshots.isEmpty) {
             return Center(child: Text(isSearching ? "No results found." : "No screenshots yet."));
          }
          return GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 4,
              mainAxisSpacing: 4,
            ),
            itemCount: screenshots.length,
            itemBuilder: (context, index) {
              final screenshot = screenshots[index];
              return GestureDetector(
                onTap: () {
                  // Show detail?
                },
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.file(
                      File(screenshot.filePath),
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => const Center(child: Icon(Icons.broken_image)),
                    ),
                    if (screenshot.isProcessed)
                      const Positioned(
                        right: 4,
                        bottom: 4,
                        child: Icon(Icons.check_circle, size: 16, color: Colors.green),
                      )
                  ],
                ),
              );
            },
          );
        },
        error: (err, stack) => Center(child: Text('Error: $err')),
        loading: () => const Center(child: CircularProgressIndicator()),
      ),
    );
  }
}
