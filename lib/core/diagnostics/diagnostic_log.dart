import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AiLogLevel { info, warn, error }

@immutable
class DiagnosticEntry {
  final DateTime time;
  final AiLogLevel level;
  final String message;
  const DiagnosticEntry(this.time, this.level, this.message);

  Map<String, dynamic> toJson() => {
        't': time.toIso8601String(),
        'l': level.name,
        'm': message,
      };

  factory DiagnosticEntry.fromJson(Map<String, dynamic> json) {
    return DiagnosticEntry(
      DateTime.tryParse(json['t'] as String? ?? '') ?? DateTime.now(),
      AiLogLevel.values.firstWhere(
        (l) => l.name == json['l'],
        orElse: () => AiLogLevel.info,
      ),
      json['m'] as String? ?? '',
    );
  }

  String get _levelTag {
    switch (level) {
      case AiLogLevel.info:
        return 'INFO';
      case AiLogLevel.warn:
        return 'WARN';
      case AiLogLevel.error:
        return 'ERROR';
    }
  }

  @override
  String toString() {
    final t = time.toIso8601String().substring(11, 19); // HH:MM:SS
    return '[$t] $_levelTag  $message';
  }
}

/// Persisted, cross-isolate log of AI-pipeline events (shared-key fetch, App
/// Check, AI calls, parse results).
///
/// Exists because a real device has no dev-environment path back to us — no
/// adb, no logcat — so `debugPrint` alone is invisible once the app isn't
/// running from a debugger. Backed by SharedPreferences rather than a plain
/// in-memory list because AI processing runs in *two* different Dart
/// isolates: the UI isolate (foreground import/reopen) and WorkManager's
/// background isolate (deep scan / live-mode periodic sync), which has its
/// own separate memory — see the comment on SharedKeyService for the same
/// isolate split biting the shared-key cache. A static list here would
/// silently miss every event the background isolate logs; SharedPreferences
/// is one of the few things both isolates can actually see, once reloaded.
class DiagnosticLog {
  DiagnosticLog._();

  static const String _prefsKey = 'diagnostic_log_v1';

  /// Bounded so a long-running app doesn't grow this unboundedly; recent
  /// events matter far more than old ones for "what just happened".
  static const int _maxEntries = 300;

  static void info(String message) => unawaited(_add(AiLogLevel.info, message));
  static void warn(String message) => unawaited(_add(AiLogLevel.warn, message));
  static void error(String message) => unawaited(_add(AiLogLevel.error, message));

  /// Serializes every persist within this isolate — callers use `unawaited`,
  /// so without this, concurrent writers (e.g. up to `_kVisionConcurrency`
  /// AI calls in flight at once, each logging its own outcome) would each
  /// read-modify-write `_prefsKey` independently and clobber one another,
  /// silently dropping entries. This is the same admission-tail pattern
  /// RateLimitedQueue uses to serialize its own concurrent callers.
  static Future<void> _writeTail = Future.value();

  static Future<void> _add(AiLogLevel level, String message) {
    final entry = DiagnosticEntry(DateTime.now(), level, message);
    // Still useful when a dev environment *does* have a console attached
    // (emulator, `flutter run`).
    debugPrint('DiagnosticLog: $entry');
    final myTurn = _writeTail.then((_) async {
      try {
        final prefs = await SharedPreferences.getInstance();
        // Each isolate's SharedPreferences instance only reflects native
        // state as of its own last fetch — reload() forces this write to
        // actually see what the other isolate persisted, instead of
        // clobbering it with a stale snapshot.
        await prefs.reload();
        final raw = prefs.getStringList(_prefsKey) ?? <String>[];
        raw.add(jsonEncode(entry.toJson()));
        final trimmed = raw.length > _maxEntries
            ? raw.sublist(raw.length - _maxEntries)
            : raw;
        await prefs.setStringList(_prefsKey, trimmed);
      } catch (e) {
        // Persisting the log must never be why an AI call itself fails.
        debugPrint('DiagnosticLog: failed to persist entry: $e');
      }
    });
    _writeTail = myTurn;
    return myTurn;
  }

  /// Loads the full persisted log, oldest first.
  static Future<List<DiagnosticEntry>> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.reload();
      final raw = prefs.getStringList(_prefsKey) ?? <String>[];
      return raw
          .map((s) {
            try {
              return DiagnosticEntry.fromJson(
                  jsonDecode(s) as Map<String, dynamic>);
            } catch (_) {
              return null;
            }
          })
          .whereType<DiagnosticEntry>()
          .toList();
    } catch (e) {
      debugPrint('DiagnosticLog: failed to load: $e');
      return [];
    }
  }

  static Future<void> clear() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_prefsKey);
    } catch (e) {
      debugPrint('DiagnosticLog: failed to clear: $e');
    }
  }

  /// Plain-text dump, newest last, suitable for pasting into a chat or bug
  /// report as-is.
  static String dump(List<DiagnosticEntry> entries) {
    if (entries.isEmpty) {
      return 'No diagnostic events recorded yet. Import or reopen a '
          'screenshot to generate some, then come back here.';
    }
    return entries.map((e) => e.toString()).join('\n');
  }
}
