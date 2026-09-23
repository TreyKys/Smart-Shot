import 'package:shared_preferences/shared_preferences.dart';

/// Which entry point drove the last scan — the Settings tile shows this
/// so a user who thought "background sync is broken, nothing has run" can
/// tell that in fact the foreground scan on last app open covered it.
enum SyncSource {
  /// GalleryRepository.syncGallery — the pull-to-refresh / cold-start /
  /// app-resume path.
  foreground,

  /// WorkManager periodic task — background_service.dart's deep scan.
  background,
}

/// Snapshot of the most recent gallery-sync run's outcome, persisted so the
/// Settings screen can tell the user when Sift last checked their photos
/// and what it found. Both scan paths — foreground [syncGallery] and the
/// WorkManager periodic task — write here, so the tile reflects whichever
/// ran most recently regardless of which triggered it.
///
/// Written to SharedPreferences (rather than Isar) intentionally: the tile
/// needs to render before the app has done anything at all, and prefs load
/// synchronously ahead of the DB.
class SyncStatus {
  final DateTime at;
  final SyncSource source;

  /// Newly-discovered screenshots ingested during this run.
  final int added;

  /// Assets past the per-run ingest cap — visible in the log as "N assets
  /// deferred to a later run." Non-zero means the library outgrew a single
  /// scan and there's more coming next time.
  final int deferred;

  /// Non-null if the run failed. A stringified exception is fine — this is
  /// diagnostic surface, not something the app itself branches on.
  final String? error;

  const SyncStatus({
    required this.at,
    required this.source,
    required this.added,
    required this.deferred,
    this.error,
  });

  bool get failed => error != null;

  static const _kAt = 'sync_status_at';
  static const _kSource = 'sync_status_source';
  static const _kAdded = 'sync_status_added';
  static const _kDeferred = 'sync_status_deferred';
  static const _kError = 'sync_status_error';

  static Future<SyncStatus?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final atMs = prefs.getInt(_kAt);
    if (atMs == null) return null;
    return SyncStatus(
      at: DateTime.fromMillisecondsSinceEpoch(atMs),
      source: SyncSource.values.firstWhere(
        (s) => s.name == (prefs.getString(_kSource) ?? 'foreground'),
        orElse: () => SyncSource.foreground,
      ),
      added: prefs.getInt(_kAdded) ?? 0,
      deferred: prefs.getInt(_kDeferred) ?? 0,
      error: prefs.getString(_kError),
    );
  }

  static Future<void> record({
    required SyncSource source,
    required int added,
    int deferred = 0,
    String? error,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kAt, DateTime.now().millisecondsSinceEpoch);
    await prefs.setString(_kSource, source.name);
    await prefs.setInt(_kAdded, added);
    await prefs.setInt(_kDeferred, deferred);
    if (error != null) {
      await prefs.setString(_kError, error);
    } else {
      await prefs.remove(_kError);
    }
  }
}
