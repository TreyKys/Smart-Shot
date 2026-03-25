import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sift/core/theme/theme_provider.dart';
import 'package:sift/features/gallery/presentation/gallery_provider.dart';
import 'package:sift/features/search/search_provider.dart';
import 'package:sift/features/gallery/data/gallery_repository.dart';
import 'package:sift/features/gallery/domain/screenshot.dart';
import 'package:sift/features/gallery/presentation/image_detail_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sift/features/gallery/presentation/widgets/smart_indexing_dialog.dart';
import 'package:sift/features/gallery/presentation/widgets/sift_bottom_sheet.dart';
import 'package:sift/features/gallery/services/background_service.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

class GalleryScreen extends ConsumerStatefulWidget {
  const GalleryScreen({super.key});

  @override
  ConsumerState<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends ConsumerState<GalleryScreen> {

  @override
  void initState() {
    super.initState();
    // Check consent before sync
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkSmartIndexingConsent();
    });
  }

  Future<void> _checkSmartIndexingConsent() async {
    final prefs = await SharedPreferences.getInstance();
    final mode = prefs.getString('smart_indexing_mode');

    if (mode == 'deep') {
      scheduleDeepScan(); // Ensure it's scheduled
    }
    // Now that consent is handled in onboarding, just sync
    ref.read(galleryRepositoryProvider).syncGallery();
  }

  @override
  Widget build(BuildContext context) {
    final searchQuery = ref.watch(searchQueryProvider);
    final isSearching = searchQuery.isNotEmpty;
    final selectedTag = ref.watch(selectedTagProvider);

    final AsyncValue<List<Screenshot>> content = isSearching
        ? ref.watch(searchResultsProvider)
        : ref.watch(galleryStreamProvider);

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(selectedTag != null ? 'Tag: $selectedTag' : 'Sift', style: const TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.sync),
            onPressed: () {
               ref.read(galleryRepositoryProvider).syncGallery();
            },
          ),
          IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () {
               showSiftBottomSheet(context);
            },
          ),
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
             return Center(
               child: Column(
                 mainAxisAlignment: MainAxisAlignment.center,
                 children: [
                   const Icon(Icons.cleaning_services, size: 64, color: Colors.grey),
                   const SizedBox(height: 16),
                   Text(
                     isSearching ? "No results found." : "Your gallery is clean.\nTake a screenshot to extract data.",
                     textAlign: TextAlign.center,
                     style: const TextStyle(color: Colors.grey, fontSize: 16),
                   ),
                 ],
               ),
             );
          }
          return MasonryGridView.count(
            crossAxisCount: 2,
            mainAxisSpacing: 4,
            crossAxisSpacing: 4,
            itemCount: screenshots.length,
            itemBuilder: (context, index) {
              final screenshot = screenshots[index];
              return GestureDetector(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => ImageDetailScreen(screenshot: screenshot),
                    ),
                  );
                },
                child: Card(
                  clipBehavior: Clip.antiAlias,
                  elevation: 2,
                  child: Stack(
                    children: [
                      Image.file(
                        File(screenshot.filePath),
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => const SizedBox(
                          height: 150,
                          child: Center(child: Icon(Icons.broken_image)),
                        ),
                      ),
                      // Loading State Overlay
                      if (!screenshot.isProcessed)
                        const Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: LinearProgressIndicator(
                            backgroundColor: Colors.black54,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.cyanAccent),
                            minHeight: 4,
                          ),
                        ),
                      // Status Indicator
                      if (screenshot.isProcessed)
                        const Positioned(
                          top: 4,
                          right: 4,
                          child: Icon(Icons.check_circle, size: 16, color: Colors.green),
                        ),
                      // Tags Overlay
                      if (screenshot.isProcessed && screenshot.tags != null && screenshot.tags!.isNotEmpty)
                        Positioned(
                          left: 4,
                          right: 4,
                          bottom: 4,
                          child: Wrap(
                            spacing: 4,
                            runSpacing: 4,
                            alignment: WrapAlignment.start,
                            children: screenshot.tags!.take(3).map((tag) => Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.black87,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    tag,
                                    style: const TextStyle(
                                      fontSize: 10,
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                )).toList(),
                          ),
                        ),
                    ],
                  ),
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
