import 'dart:io';
import 'package:add_2_calendar/add_2_calendar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:sift/core/theme/app_theme.dart';
import 'package:sift/features/gallery/domain/screenshot.dart';
import 'package:sift/features/pro/pro_service.dart';
import 'package:url_launcher/url_launcher.dart';

class ImageDetailScreen extends ConsumerWidget {
  final Screenshot screenshot;
  const ImageDetailScreen({super.key, required this.screenshot});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPro = ref.watch(proServiceProvider);
    final hasText =
        (screenshot.cleanText?.isNotEmpty ?? false) ||
        (screenshot.ocrText?.isNotEmpty ?? false);
    final isTodo = screenshot.tags?.any(
            (t) => t.toLowerCase().contains('to-do') ||
                t.toLowerCase().contains('todo') ||
                t.toLowerCase().contains('task')) ??
        false;
    final hasDates = (screenshot.dates?.isNotEmpty ?? false) || isTodo;

    return Scaffold(
      backgroundColor: SiftColors.background,
      appBar: AppBar(
        backgroundColor: SiftColors.background,
        title: Text(
          screenshot.tags?.firstOrNull ?? 'Detail',
          style: const TextStyle(
            color: SiftColors.textPrimary,
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          // Share image
          IconButton(
            icon: const Icon(Icons.ios_share, color: SiftColors.textSecondary),
            onPressed: () => Share.shareXFiles([XFile(screenshot.filePath)]),
          ),
          // Advanced markdown export (Pro only)
          if (isPro)
            IconButton(
              icon: const Icon(Icons.text_snippet_outlined,
                  color: SiftColors.proGold),
              tooltip: 'Export as Markdown',
              onPressed: () => _exportMarkdown(context),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Image
            InteractiveViewer(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.55,
                ),
                child: Image.file(
                  File(screenshot.filePath),
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Center(
                    child: Icon(Icons.broken_image,
                        size: 64, color: SiftColors.textTertiary),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Action chips (exclude app_recommendation — shown separately)
            if (screenshot.suggestedActions != null &&
                screenshot.suggestedActions!.any((a) => a.intentType != 'app_recommendation'))
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: screenshot.suggestedActions!
                      .where((a) => a.intentType != 'app_recommendation')
                      .map((action) => ActionChip(
                            avatar: _actionIcon(action.intentType),
                            label: Text(action.label ?? 'Action'),
                            backgroundColor: SiftColors.surfaceElevated,
                            labelStyle: const TextStyle(
                                color: SiftColors.textPrimary, fontSize: 12),
                            side:
                                const BorderSide(color: SiftColors.border, width: 0.5),
                            onPressed: () => _handleAction(context, action),
                          ))
                      .toList(),
                ),
              ),

            // Dynamic cross-app recommendation card
            if (screenshot.suggestedActions != null)
              ...screenshot.suggestedActions!
                  .where((a) => a.intentType == 'app_recommendation')
                  .map((rec) => _AppRecommendationCard(action: rec)),

            // Calendar export button
            if (hasDates)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: SiftColors.accent,
                    side: const BorderSide(
                        color: SiftColors.accent, width: 0.8),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  icon: const Icon(Icons.calendar_today, size: 16),
                  label: const Text('Add to Calendar',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  onPressed: () => _addToCalendar(context),
                ),
              ),


            const SizedBox(height: 16),

            // Tags
            if (screenshot.tags != null && screenshot.tags!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: screenshot.tags!.map((tag) {
                    final color = SiftColors.forTag(tag);
                    return Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: color.withOpacity(0.4), width: 0.8),
                      ),
                      child: Text(
                        tag,
                        style: TextStyle(
                          color: color,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),

            const SizedBox(height: 16),

            // Text content
            if (hasText)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: SelectableText(
                  screenshot.cleanText ?? screenshot.ocrText ?? '',
                  style: const TextStyle(
                    color: SiftColors.textSecondary,
                    fontSize: 14,
                    height: 1.6,
                  ),
                ),
              )
            else
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'No text detected.',
                  style: TextStyle(
                      color: SiftColors.textTertiary,
                      fontSize: 14,
                      fontStyle: FontStyle.italic),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Icon? _actionIcon(String? type) {
    switch (type) {
      case 'url':
        return const Icon(Icons.link, size: 14);
      case 'copy':
        return const Icon(Icons.copy, size: 14);
      case 'dial':
        return const Icon(Icons.phone, size: 14);
      default:
        return const Icon(Icons.touch_app, size: 14);
    }
  }

  Future<void> _handleAction(BuildContext context, SuggestedAction action) async {
    final payload = action.payload;
    if (payload == null || payload.isEmpty) return;

    try {
      if (action.intentType == 'url') {
        final uri = Uri.tryParse(payload);
        if (uri != null) {
          if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Could not launch URL')));
            }
          }
        }
      } else if (action.intentType == 'dial') {
        final uri = Uri(scheme: 'tel', path: payload);
        if (!await launchUrl(uri)) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Could not dial number')));
          }
        }
      } else if (action.intentType == 'copy') {
        await Clipboard.setData(ClipboardData(text: payload));
        if (context.mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text('Copied: $payload')));
        }
      }
    } catch (e) {
      debugPrint('Action error: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  void _addToCalendar(BuildContext context) {
    // Extract first date string or use current date
    final dateStr = screenshot.dates?.firstOrNull;
    final title = screenshot.cleanText?.split('\n').first.trim() ??
        screenshot.tags?.firstOrNull ??
        'Screenshot reminder';

    DateTime startDate = DateTime.now().add(const Duration(days: 1));
    if (dateStr != null) {
      try {
        startDate = DateTime.parse(dateStr);
      } catch (_) {
        // Use tomorrow as fallback
      }
    }

    final event = Event(
      title: title.length > 50 ? '${title.substring(0, 47)}…' : title,
      description: screenshot.cleanText ?? screenshot.ocrText ?? '',
      startDate: startDate,
      endDate: startDate.add(const Duration(hours: 1)),
      allDay: false,
    );

    Add2Calendar.addEvent2Cal(event);
  }

  void _exportMarkdown(BuildContext context) {
    final sb = StringBuffer();
    sb.writeln('# ${screenshot.tags?.join(', ') ?? 'Screenshot'}');
    sb.writeln();
    sb.writeln('**Date:** ${screenshot.timestamp.toIso8601String()}');
    if (screenshot.urls != null && screenshot.urls!.isNotEmpty) {
      sb.writeln();
      sb.writeln('## URLs');
      for (final url in screenshot.urls!) {
        sb.writeln('- $url');
      }
    }
    if (screenshot.dates != null && screenshot.dates!.isNotEmpty) {
      sb.writeln();
      sb.writeln('## Dates');
      for (final d in screenshot.dates!) {
        sb.writeln('- $d');
      }
    }
    sb.writeln();
    sb.writeln('## Content');
    sb.writeln(screenshot.cleanText ?? screenshot.ocrText ?? '');

    Share.share(sb.toString(), subject: 'Sift Export');
  }

}

// ── Cross-app recommendation card ─────────────────────────────────────────────

class _AppRecommendationCard extends StatelessWidget {
  final SuggestedAction action;
  const _AppRecommendationCard({required this.action});

  static const _appIcons = <String, IconData>{
    'Pulse': Icons.favorite_outline,
    'Context Dictionary': Icons.menu_book_outlined,
    'Magnum Opus': Icons.auto_awesome_outlined,
  };

  static const _appDescriptions = <String, String>{
    'Pulse': 'Track health vitals, habits and biometrics.',
    'Context Dictionary': 'Look up words, meanings and translations.',
    'Magnum Opus': 'Write, brainstorm and chat with AI.',
  };

  @override
  Widget build(BuildContext context) {
    final name = action.label ?? 'NeuroDevLabs App';
    final icon = _appIcons[name] ?? Icons.apps_outlined;
    final description = _appDescriptions[name] ?? 'Coming soon from NeuroDevLabs.';

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFFAE6EFD).withOpacity(0.12),
              const Color(0xFF6E8EFD).withOpacity(0.08),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFAE6EFD).withOpacity(0.35), width: 0.8),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFAE6EFD).withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: const Color(0xFFAE6EFD), size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Try $name',
                    style: const TextStyle(
                      color: Color(0xFFAE6EFD),
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: const TextStyle(color: SiftColors.textSecondary, fontSize: 11),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFAE6EFD).withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFAE6EFD).withOpacity(0.4), width: 0.5),
              ),
              child: const Text(
                'Coming Soon',
                style: TextStyle(
                  color: Color(0xFFAE6EFD),
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
