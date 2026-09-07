import 'package:flutter/material.dart';
import 'package:sift/core/theme/app_theme.dart';
import 'package:sift/features/gallery/domain/screenshot.dart';
import 'package:sift/features/gallery/presentation/image_detail_screen.dart';
import 'package:sift/features/gallery/presentation/widgets/screenshot_thumbnail.dart';

/// A single memory's screenshots, read-only — tap one to open it full
/// screen. Deliberately not built on CollectionDetailScreen: that screen's
/// whole reason to exist is "remove from this collection," a concept a
/// memory group doesn't have — it's not a collection, just a real date match.
class MemoryGridScreen extends StatelessWidget {
  final String title;
  final List<Screenshot> shots;
  const MemoryGridScreen({super.key, required this.title, required this.shots});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SiftPillowyColors.surface,
      appBar: AppBar(
        backgroundColor: SiftPillowyColors.surfaceContainerLowest,
        elevation: 0,
        iconTheme: const IconThemeData(color: SiftPillowyColors.onSurface),
        title: Text(title, style: SiftPillowyText.headlineSm),
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(12),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
        ),
        itemCount: shots.length,
        itemBuilder: (context, i) {
          final shot = shots[i];
          return GestureDetector(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                  builder: (_) => ImageDetailScreen(screenshot: shot)),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: ScreenshotThumbnail(filePath: shot.filePath),
            ),
          );
        },
      ),
    );
  }
}
