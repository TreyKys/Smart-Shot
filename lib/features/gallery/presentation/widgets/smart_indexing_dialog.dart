import 'package:flutter/material.dart';

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
      title: const Text("Smart Indexing"),
      content: const Text(
        "To protect your battery and data, SmartShot needs to know how to handle your gallery.\n\n"
        "Live Mode: Only process new screenshots from now on. (Recommended)\n\n"
        "Deep Scan: Slowly process your entire history in the background when the device is idle.",
      ),
      actions: [
        TextButton(
          onPressed: onLiveMode,
          child: const Text("Live Mode"),
        ),
        FilledButton(
          onPressed: onDeepScan,
          child: const Text("Deep Scan"),
        ),
      ],
    );
  }
}
