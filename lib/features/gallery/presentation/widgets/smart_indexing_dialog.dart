import 'package:flutter/material.dart';
import 'package:sift/core/theme/app_theme.dart';

/// Shown once, on first launch — before this, the app has no idea whether
/// to index new screenshots only or sweep the user's entire history, so
/// nothing in Organize would have anything real to show yet.
class SmartIndexingDialog extends StatelessWidget {
  final VoidCallback onLiveMode;
  final VoidCallback onDeepScan;

  const SmartIndexingDialog({
    super.key,
    required this.onLiveMode,
    required this.onDeepScan,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: SiftColors.surfaceElevated,
      title: Text('Smart Indexing',
          style: TextStyle(
              color: SiftColors.textPrimary, fontWeight: FontWeight.w700)),
      content: Text(
        'To protect your battery and data, Sift needs to know how to handle your gallery.\n\n'
        'Live Mode: Only process new screenshots from now on. (Recommended)\n\n'
        'Deep Scan: Slowly process your entire history in the background when the device is idle.',
        style: TextStyle(color: SiftColors.textSecondary),
      ),
      actions: [
        TextButton(
          onPressed: onLiveMode,
          child: const Text('Live Mode',
              style: TextStyle(color: SiftColors.accent)),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
              backgroundColor: SiftColors.accent,
              foregroundColor: SiftColors.background),
          onPressed: onDeepScan,
          child: const Text('Deep Scan'),
        ),
      ],
    );
  }
}
