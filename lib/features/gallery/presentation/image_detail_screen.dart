import 'dart:io';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:smart_shot/features/gallery/domain/screenshot.dart';

class ImageDetailScreen extends StatelessWidget {
  final Screenshot screenshot;

  const ImageDetailScreen({super.key, required this.screenshot});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(screenshot.tags?.firstOrNull ?? 'Detail'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              Share.shareXFiles([XFile(screenshot.filePath)]);
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            InteractiveViewer(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.7,
                ),
                child: Image.file(
                  File(screenshot.filePath),
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) =>
                      const Center(child: Icon(Icons.broken_image, size: 64)),
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (screenshot.tags != null && screenshot.tags!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: screenshot.tags!
                      .map((tag) => Chip(
                            label: Text(tag),
                            backgroundColor: Theme.of(context).colorScheme.surfaceContainerHigh,
                          ))
                      .toList(),
                ),
              ),
             const SizedBox(height: 16),
            if (screenshot.cleanText != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                child: SelectableText(
                  screenshot.cleanText!,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              )
            else if (screenshot.ocrText != null)
               Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                child: SelectableText(
                  "Raw OCR:\n${screenshot.ocrText!}",
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
