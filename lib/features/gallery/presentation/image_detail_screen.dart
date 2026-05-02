import 'dart:io';
import 'package:add_2_calendar/add_2_calendar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sift/core/theme/app_theme.dart';
import 'package:sift/features/gallery/data/gallery_repository.dart';
import 'package:sift/features/gallery/domain/screenshot.dart';
import 'package:sift/features/gallery/presentation/gallery_provider.dart';
import 'package:sift/features/ingestion/services/tag_engine.dart';
import 'package:sift/features/pro/pro_service.dart';
import 'package:url_launcher/url_launcher.dart';

String _cleanTag(String tag) => tag.startsWith('#') ? tag.substring(1) : tag;

class ImageDetailScreen extends ConsumerStatefulWidget {
  final Screenshot screenshot;
  const ImageDetailScreen({super.key, required this.screenshot});

  @override
  ConsumerState<ImageDetailScreen> createState() => _ImageDetailScreenState();
}

class _ImageDetailScreenState extends ConsumerState<ImageDetailScreen> {
  late Screenshot _shot;

  @override
  void initState() {
    super.initState();
    _shot = widget.screenshot;
  }

  Future<void> _togglePin() async {
    final pinnedIds = ref.read(pinnedIdsProvider);
    final wasPinned = pinnedIds.contains(_shot.id);
    final newIds = Set<int>.from(pinnedIds);
    if (wasPinned) {
      newIds.remove(_shot.id);
    } else {
      newIds.add(_shot.id);
    }
    ref.read(pinnedIdsProvider.notifier).state = newIds;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
        'pinned_ids', newIds.map((e) => e.toString()).toList());
  }

  void _showTagEditSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _TagEditSheet(
        initialTags: _shot.tags ?? [],
        onSave: (newTags) async {
          await ref
              .read(galleryRepositoryProvider)
              .updateTags(_shot.id, newTags);
          if (mounted) {
            setState(() {
              _shot.tags = newTags.isEmpty ? null : newTags;
            });
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isPro = ref.watch(proServiceProvider);
    final isPinned = ref.watch(pinnedIdsProvider).contains(_shot.id);
    final hasText = (_shot.cleanText?.isNotEmpty ?? false) ||
        (_shot.ocrText?.isNotEmpty ?? false);
    final isTodo = _shot.tags?.any((t) =>
            t.toLowerCase().contains('to-do') ||
            t.toLowerCase().contains('todo') ||
            t.toLowerCase().contains('task')) ??
        false;
    final hasDates = (_shot.dates?.isNotEmpty ?? false) || isTodo;

    return Scaffold(
      backgroundColor: SiftColors.background,
      appBar: AppBar(
        backgroundColor: SiftColors.background,
        title: Text(
          _cleanTag(_shot.tags?.firstOrNull ?? 'Detail'),
          style: const TextStyle(
            color: SiftColors.textPrimary,
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              isPinned ? Icons.push_pin : Icons.push_pin_outlined,
              color: isPinned ? SiftColors.accent : SiftColors.textSecondary,
            ),
            onPressed: _togglePin,
            tooltip: isPinned ? 'Unpin' : 'Pin',
          ),
          IconButton(
            icon: const Icon(Icons.ios_share, color: SiftColors.textSecondary),
            onPressed: () => Share.shareXFiles([XFile(_shot.filePath)]),
          ),
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
            InteractiveViewer(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.55,
                ),
                child: Image.file(
                  File(_shot.filePath),
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Center(
                    child: Icon(Icons.broken_image,
                        size: 64, color: SiftColors.textTertiary),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Action chips
            if (_shot.suggestedActions != null &&
                _shot.suggestedActions!
                    .any((a) => a.intentType != 'app_recommendation'))
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: _shot.suggestedActions!
                      .where((a) => a.intentType != 'app_recommendation')
                      .map((action) => ActionChip(
                            avatar: _actionIcon(action.intentType),
                            label: Text(action.label ?? 'Action'),
                            backgroundColor: SiftColors.surfaceElevated,
                            labelStyle: const TextStyle(
                                color: SiftColors.textPrimary, fontSize: 12),
                            side: const BorderSide(
                                color: SiftColors.border, width: 0.5),
                            onPressed: () => _handleAction(context, action),
                          ))
                      .toList(),
                ),
              ),

            // App recommendation
            if (_shot.suggestedActions != null)
              ..._shot.suggestedActions!
                  .where((a) => a.intentType == 'app_recommendation')
                  .map((rec) => _AppRecommendationCard(action: rec)),

            // Calendar button
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
                      style: TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w600)),
                  onPressed: () => _addToCalendar(context),
                ),
              ),

            const SizedBox(height: 16),

            // Tags section header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  const Text(
                    'TAGS',
                    style: TextStyle(
                      color: SiftColors.textTertiary,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: _showTagEditSheet,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: SiftColors.surfaceElevated,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: SiftColors.border, width: 0.5),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.edit_outlined,
                              size: 12, color: SiftColors.textSecondary),
                          SizedBox(width: 4),
                          Text('Edit',
                              style: TextStyle(
                                  color: SiftColors.textSecondary,
                                  fontSize: 12)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // Tag pills
            if (_shot.tags != null && _shot.tags!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: _shot.tags!.map((tag) {
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
                        _cleanTag(tag),
                        style: TextStyle(
                            color: color,
                            fontSize: 12,
                            fontWeight: FontWeight.w600),
                      ),
                    );
                  }).toList(),
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: GestureDetector(
                  onTap: _showTagEditSheet,
                  child: const Text(
                    'No tags yet — tap Edit to add some.',
                    style: TextStyle(
                        color: SiftColors.textTertiary,
                        fontSize: 13,
                        fontStyle: FontStyle.italic),
                  ),
                ),
              ),

            const SizedBox(height: 16),

            // Text content
            if (hasText)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: SelectableText(
                  _shot.cleanText ?? _shot.ocrText ?? '',
                  style: const TextStyle(
                      color: SiftColors.textSecondary,
                      fontSize: 14,
                      height: 1.6),
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

  Future<void> _handleAction(
      BuildContext context, SuggestedAction action) async {
    final payload = action.payload;
    if (payload == null || payload.isEmpty) return;
    try {
      if (action.intentType == 'url') {
        final uri = Uri.tryParse(payload);
        if (uri != null &&
            !await launchUrl(uri, mode: LaunchMode.externalApplication)) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Could not launch URL')));
          }
        }
      } else if (action.intentType == 'dial') {
        if (!await launchUrl(Uri(scheme: 'tel', path: payload))) {
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
    final dateStr = _shot.dates?.firstOrNull;
    final title = _shot.cleanText?.split('\n').first.trim() ??
        _shot.tags?.firstOrNull ??
        'Screenshot reminder';

    final startDate =
        _parseDate(dateStr) ?? DateTime.now().add(const Duration(days: 1));

    final event = Event(
      title: title.length > 50 ? '${title.substring(0, 47)}…' : title,
      description: _shot.cleanText ?? _shot.ocrText ?? '',
      startDate: startDate,
      endDate: startDate.add(const Duration(hours: 1)),
      allDay: false,
    );
    Add2Calendar.addEvent2Cal(event);
  }

  static DateTime? _parseDate(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    final s = raw.trim();
    // ISO 8601: YYYY-MM-DD
    try {
      return DateTime.parse(s);
    } catch (_) {}
    // US: MM/DD/YYYY
    final us =
        RegExp(r'^(\d{1,2})/(\d{1,2})/(\d{4})$').firstMatch(s);
    if (us != null) {
      return DateTime.tryParse(
          '${us[3]}-${us[1]!.padLeft(2, '0')}-${us[2]!.padLeft(2, '0')}');
    }
    const months = {
      'jan': '01', 'feb': '02', 'mar': '03', 'apr': '04',
      'may': '05', 'jun': '06', 'jul': '07', 'aug': '08',
      'sep': '09', 'oct': '10', 'nov': '11', 'dec': '12',
    };
    // "15 March 2024"
    final nat1 =
        RegExp(r'^(\d{1,2})\s+([A-Za-z]+)\s+(\d{4})').firstMatch(s);
    if (nat1 != null) {
      final mon = months[nat1[2]!.substring(0, 3).toLowerCase()];
      if (mon != null) {
        return DateTime.tryParse(
            '${nat1[3]}-$mon-${nat1[1]!.padLeft(2, '0')}');
      }
    }
    // "March 15, 2024"
    final nat2 =
        RegExp(r'^([A-Za-z]+)\s+(\d{1,2}),?\s+(\d{4})').firstMatch(s);
    if (nat2 != null) {
      final mon = months[nat2[1]!.substring(0, 3).toLowerCase()];
      if (mon != null) {
        return DateTime.tryParse(
            '${nat2[3]}-$mon-${nat2[2]!.padLeft(2, '0')}');
      }
    }
    return null;
  }

  void _exportMarkdown(BuildContext context) {
    final sb = StringBuffer();
    sb.writeln('# ${_shot.tags?.join(', ') ?? 'Screenshot'}');
    sb.writeln('\n**Date:** ${_shot.timestamp.toIso8601String()}');
    if (_shot.urls?.isNotEmpty ?? false) {
      sb.writeln('\n## URLs');
      for (final url in _shot.urls!) {
        sb.writeln('- $url');
      }
    }
    if (_shot.dates?.isNotEmpty ?? false) {
      sb.writeln('\n## Dates');
      for (final d in _shot.dates!) {
        sb.writeln('- $d');
      }
    }
    sb.writeln('\n## Content');
    sb.writeln(_shot.cleanText ?? _shot.ocrText ?? '');
    Share.share(sb.toString(), subject: 'Sift Export');
  }
}

// ── Tag edit bottom sheet ─────────────────────────────────────────────────────

class _TagEditSheet extends StatefulWidget {
  final List<String> initialTags;
  final Future<void> Function(List<String>) onSave;

  const _TagEditSheet({required this.initialTags, required this.onSave});

  @override
  State<_TagEditSheet> createState() => _TagEditSheetState();
}

class _TagEditSheetState extends State<_TagEditSheet> {
  late List<String> _tags;
  final _controller = TextEditingController();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _tags = List.from(widget.initialTags);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _addTag() {
    final raw = _controller.text.trim();
    if (raw.isEmpty) return;
    final norm = TagEngine.normalize(raw);
    if (norm.isNotEmpty && !_tags.contains(norm)) {
      setState(() => _tags.add(norm));
    }
    _controller.clear();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    await widget.onSave(_tags);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: SiftColors.surfaceElevated,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: SiftColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const Text('Edit Tags',
              style: TextStyle(
                  color: SiftColors.textPrimary,
                  fontSize: 17,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          if (_tags.isNotEmpty)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _tags.map((tag) {
                final color = SiftColors.forTag(tag);
                return GestureDetector(
                  onTap: () => setState(() => _tags.remove(tag)),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                      border:
                          Border.all(color: color.withOpacity(0.4), width: 0.8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_cleanTag(tag),
                            style: TextStyle(
                                color: color,
                                fontSize: 13,
                                fontWeight: FontWeight.w600)),
                        const SizedBox(width: 4),
                        Icon(Icons.close,
                            size: 12, color: color.withOpacity(0.7)),
                      ],
                    ),
                  ),
                );
              }).toList(),
            )
          else
            const Text('No tags — add some below.',
                style: TextStyle(
                    color: SiftColors.textTertiary, fontSize: 13)),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  style: const TextStyle(
                      color: SiftColors.textPrimary, fontSize: 14),
                  decoration: const InputDecoration(
                    hintText: 'Add tag (e.g. Finance)',
                    prefixText: '# ',
                    prefixStyle: TextStyle(color: SiftColors.accent),
                  ),
                  onSubmitted: (_) => _addTag(),
                  textInputAction: TextInputAction.done,
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: _addTag,
                icon: const Icon(Icons.add_circle, color: SiftColors.accent),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.black))
                  : const Text('Save'),
            ),
          ),
        ],
      ),
    );
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
    final description =
        _appDescriptions[name] ?? 'Coming soon from NeuroDevLabs.';

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
          border: Border.all(
              color: const Color(0xFFAE6EFD).withOpacity(0.35), width: 0.8),
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
                    style: const TextStyle(
                        color: SiftColors.textSecondary, fontSize: 11),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFAE6EFD).withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: const Color(0xFFAE6EFD).withOpacity(0.4),
                    width: 0.5),
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
