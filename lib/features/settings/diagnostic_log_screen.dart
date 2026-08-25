import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sift/core/diagnostics/diagnostic_log.dart';

/// Shows the persisted AI diagnostic log and lets the user copy it.
///
/// This exists because on a real device there is no dev environment plugged
/// in to read `adb logcat` from — this screen is the only way to see whether
/// AI calls are actually succeeding (foreground or background), and to get
/// that evidence off the phone (paste into a chat, an email, a bug report)
/// without any tooling at all.
class DiagnosticLogScreen extends StatefulWidget {
  const DiagnosticLogScreen({super.key});

  @override
  State<DiagnosticLogScreen> createState() => _DiagnosticLogScreenState();
}

class _DiagnosticLogScreenState extends State<DiagnosticLogScreen> {
  late Future<List<DiagnosticEntry>> _future;

  @override
  void initState() {
    super.initState();
    _future = DiagnosticLog.load();
  }

  void _reload() => setState(() => _future = DiagnosticLog.load());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Diagnostics Log'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: _reload,
          ),
          FutureBuilder<List<DiagnosticEntry>>(
            future: _future,
            builder: (context, snapshot) {
              final entries = snapshot.data ?? const [];
              return IconButton(
                icon: const Icon(Icons.copy_all_outlined),
                tooltip: 'Copy log',
                onPressed:
                    entries.isEmpty ? null : () => _copyLog(entries),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Clear log',
            onPressed: () async {
              await DiagnosticLog.clear();
              _reload();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: const Text(
              'This is a record of what happened the last few times Sift '
              'tried to tag a screenshot with AI — whether a shared key or '
              'your own key was used, whether the call succeeded, and why it '
              'didn\'t when it fails. Tap the copy icon and paste it '
              'somewhere to share it.',
              style: TextStyle(fontSize: 13),
            ),
          ),
          Expanded(
            child: FutureBuilder<List<DiagnosticEntry>>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                final entries = snapshot.data ?? const [];
                if (entries.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'No AI events recorded yet.\n\n'
                        'Import or reopen a screenshot to generate some, '
                        'then come back here and hit refresh.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  // Newest first — the most recent AI call is what a user
                  // just tried to reproduce and is here to check on.
                  itemCount: entries.length,
                  itemBuilder: (context, i) {
                    final entry = entries[entries.length - 1 - i];
                    final color = switch (entry.level) {
                      DiagnosticLevel.error => Colors.red,
                      DiagnosticLevel.warn => Colors.orange,
                      DiagnosticLevel.info => Colors.green,
                    };
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.circle, size: 8, color: color),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              entry.toString(),
                              style: const TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _copyLog(List<DiagnosticEntry> entries) {
    Clipboard.setData(ClipboardData(text: DiagnosticLog.dump(entries)));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Diagnostic log copied to clipboard.')),
    );
  }
}
