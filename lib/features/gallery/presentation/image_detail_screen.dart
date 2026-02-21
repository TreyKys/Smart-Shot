import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:smart_shot/features/gallery/domain/screenshot.dart';
import 'package:url_launcher/url_launcher.dart';

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
            if (screenshot.suggestedActions != null && screenshot.suggestedActions!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: screenshot.suggestedActions!.map((action) => ActionChip(
                    avatar: _getActionIcon(action.intentType),
                    label: Text(action.label ?? "Action"),
                    onPressed: () => _handleAction(context, action),
                  )).toList(),
                ),
              ),
            if (screenshot.suggestedActions != null && screenshot.suggestedActions!.isNotEmpty)
              const SizedBox(height: 8),

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

  Icon? _getActionIcon(String? intentType) {
    switch (intentType) {
      case 'url': return const Icon(Icons.link, size: 16);
      case 'copy': return const Icon(Icons.copy, size: 16);
      case 'dial': return const Icon(Icons.phone, size: 16);
      default: return const Icon(Icons.touch_app, size: 16);
    }
  }

  Future<void> _handleAction(BuildContext context, SuggestedAction action) async {
    final payload = action.payload;
    if (payload == null || payload.isEmpty) return;

    try {
      if (action.intentType == 'url') {
        final uri = Uri.tryParse(payload);
        if (uri != null) {
           // Try to launch without check first, or just launch
           if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Could not launch URL")));
              }
           }
        }
      } else if (action.intentType == 'dial') {
        final uri = Uri(scheme: 'tel', path: payload);
        if (!await launchUrl(uri)) {
           if (context.mounted) {
             ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Could not dial number")));
           }
        }
      } else if (action.intentType == 'copy') {
        await Clipboard.setData(ClipboardData(text: payload));
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Copied: $payload")));
        }
      }
    } catch (e) {
      debugPrint("Action failed: $e");
      if (context.mounted) {
         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    }
  }
}
