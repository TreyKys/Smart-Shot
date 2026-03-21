import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:sift/features/gallery/domain/screenshot.dart';
import 'package:sift/features/pro/pro_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:android_intent_plus/android_intent.dart';
import 'package:android_intent_plus/flag.dart';

class ImageDetailScreen extends ConsumerWidget {
  final Screenshot screenshot;

  const ImageDetailScreen({super.key, required this.screenshot});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textLength = (screenshot.cleanText?.length ?? screenshot.ocrText?.length ?? 0);
    final isHeavyText = textLength > 500;
    final isPro = ref.watch(proServiceProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(screenshot.tags?.firstOrNull ?? 'Detail'),
        actions: [
          if (isPro)
            IconButton(
              icon: const Icon(Icons.import_export),
              tooltip: 'Advanced Export',
              onPressed: () {
                _handleAdvancedExport(context);
              },
            ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              Share.shareXFiles([XFile(screenshot.filePath)]);
            },
          ),
        ],
      ),
      bottomNavigationBar: isHeavyText
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  icon: const Icon(Icons.chat_bubble_outline),
                  label: const Text(
                    "Need to chat with this full document? Open in Magnum Opus.",
                    textAlign: TextAlign.center,
                  ),
                  onPressed: () => _openMagnumOpus(context),
                ),
              ),
            )
          : null,
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

  void _handleAdvancedExport(BuildContext context) {
    final buffer = StringBuffer();
    buffer.writeln("# Sift AI Summary");
    buffer.writeln();
    if (screenshot.tags != null && screenshot.tags!.isNotEmpty) {
      buffer.writeln("Tags: ${screenshot.tags!.join(', ')}");
    }
    buffer.writeln("Date: ${screenshot.timestamp.toString()}");
    buffer.writeln();
    buffer.writeln("## Extracted Text");
    buffer.writeln();
    buffer.writeln(screenshot.cleanText ?? screenshot.ocrText ?? "No text extracted.");

    Share.share(buffer.toString(), subject: "Sift AI Export");
  }

  Future<void> _openMagnumOpus(BuildContext context) async {
    final text = screenshot.cleanText ?? screenshot.ocrText ?? "";
    await Clipboard.setData(ClipboardData(text: text));

    if (context.mounted) {
       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Text copied to clipboard!")));
    }

    try {
      const intent = AndroidIntent(
        action: 'android.intent.action.MAIN',
        package: 'com.neurodevlabs.magnumopus',
        flags: <int>[Flag.FLAG_ACTIVITY_NEW_TASK],
      );
      await intent.launch();
    } catch (e) {
      debugPrint("Magnum Opus not found: $e");
      // Fallback: prompt to play store
      final url = Uri.parse("https://play.google.com/store/apps/details?id=com.neurodevlabs.magnumopus");
      if (await canLaunchUrl(url)) {
         await launchUrl(url, mode: LaunchMode.externalApplication);
      }
    }
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
