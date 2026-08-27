import 'dart:io';

import 'package:flutter/material.dart';
import 'package:sift/core/theme/app_theme.dart';

/// A single screenshot's image, clipped and with a broken-image fallback —
/// shared by the collection grid and the Gallery Assistant's result strips
/// so both get the same load-failure handling `gallery_screen.dart`'s own
/// card already has, without copy-pasting it a third time.
///
/// Deliberately unsized — the caller controls dimensions (a GridView cell, a
/// fixed SizedBox in a horizontal chat strip, etc.) via its own constraints.
class ScreenshotThumbnail extends StatelessWidget {
  final String filePath;
  final BoxFit fit;
  final double borderRadius;

  const ScreenshotThumbnail({
    super.key,
    required this.filePath,
    this.fit = BoxFit.cover,
    this.borderRadius = 10,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: Container(
        color: SiftColors.surface,
        child: Image.file(
          File(filePath),
          fit: fit,
          cacheWidth: 200,
          errorBuilder: (_, __, ___) => const Center(
            child: Icon(Icons.broken_image,
                color: SiftColors.textTertiary, size: 20),
          ),
        ),
      ),
    );
  }
}
