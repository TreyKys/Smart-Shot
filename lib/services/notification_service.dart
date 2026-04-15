import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

/// Engagement notification service.
/// Handles: processing complete, storage pressure, daily digest,
/// re-engagement nudge, and quota nudge.
class NotificationService {
  NotificationService._();
  static final instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const _channelId = 'sift_engagement';
  static const _channelName = 'Sift Activity';

  Future<void> init() async {
    tz.initializeTimeZones();

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: false,
    );
    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: ios),
    );

    // Create notification channel (Android 8+)
    const channel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: 'Sift activity, processing status and smart reminders.',
      importance: Importance.defaultImportance,
      playSound: false,
    );
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    debugPrint('NotificationService: initialised.');
  }

  // ── Immediate notifications ───────────────────────────────────────────────

  Future<void> notifyProcessingComplete(int count) async {
    await _show(
      id: 1001,
      title: 'Sift',
      body: 'Sift tagged $count screenshot${count == 1 ? '' : 's'} — tap to see what it found.',
    );
  }

  Future<void> notifyStoragePressure(
      {required double usedGb, required double freeableMb}) async {
    await _show(
      id: 1002,
      title: 'Storage Alert',
      body:
          'Your gallery is using ${usedGb.toStringAsFixed(1)} GB. Tap to free ${freeableMb.toStringAsFixed(0)} MB.',
    );
  }

  Future<void> notifyQuotaNudge(int used, int total) async {
    if (used < total - 1) return; // Only fire when 1 left
    await _show(
      id: 1003,
      title: 'Sift AI',
      body: '$used of $total AI scans used today. Pro removes this limit.',
    );
  }

  // ── Scheduled notifications ──────────────────────────────────────────────

  /// Daily digest at 8am — call once on app start.
  Future<void> scheduleDailyDigest({
    required int unprocessedCount,
    required int receiptCount,
    required int memeCount,
  }) async {
    await _plugin.cancelAll();

    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
        tz.local, now.year, now.month, now.day, 8, 0, 0);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    await _plugin.zonedSchedule(
      2001,
      'Good morning ☀️',
      'You have $unprocessedCount unprocessed screenshots. '
          '$receiptCount receipt${receiptCount == 1 ? '' : 's'}, '
          '$memeCount meme${memeCount == 1 ? '' : 's'} found this week.',
      scheduled,
      _notifDetails(),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  /// Re-engagement if app hasn't been opened in 5 days.
  Future<void> scheduleReEngagement(int unprocessedCount) async {
    final trigger = tz.TZDateTime.now(tz.local).add(const Duration(days: 5));
    await _plugin.zonedSchedule(
      3001,
      'Sift',
      '$unprocessedCount screenshot${unprocessedCount == 1 ? ' is' : 's are'} unprocessed. Your data is waiting.',
      trigger,
      _notifDetails(),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  Future<void> _show(
      {required int id, required String title, required String body}) async {
    await _plugin.show(id, title, body, _notifDetails());
  }

  NotificationDetails _notifDetails() {
    return const NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription:
            'Sift activity, processing status and smart reminders.',
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
        playSound: false,
        enableVibration: false,
        icon: '@mipmap/ic_launcher',
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: false,
        presentSound: false,
      ),
    );
  }
}
