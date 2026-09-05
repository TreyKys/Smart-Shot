import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:sift/core/navigation.dart';
import 'package:sift/features/junk_review/presentation/junk_review_screen.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

/// Payload strings notifications can carry — matched in [_route] to decide
/// what tapping one should open. A plain string, not an enum, because it
/// crosses the plugin's platform channel as one either way and this is the
/// only place that ever reads it back.
const String _kPayloadJunkReview = 'junk_review';

/// Engagement notification service.
/// Handles: processing complete, storage pressure, daily digest,
/// re-engagement nudge, quota nudge, and junk-batch-ready.
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
      // Fires when a notification is tapped while this isolate is alive
      // (foreground or backgrounded, not fully killed) — the background
      // WorkManager isolate that can also call init() has no navigator to
      // route with, but it's never the one receiving a tap either, so
      // appNavigatorKey being unattached there is harmless.
      onDidReceiveNotificationResponse: (response) =>
          _route(response.payload),
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

  /// Call once, after the widget tree is up — handles the case
  /// [init]'s own callback can't: the app was fully closed and got launched
  /// by tapping a notification, so there was no running isolate for the tap
  /// to reach in the first place.
  Future<void> routeIfLaunchedFromNotification() async {
    final details = await _plugin.getNotificationAppLaunchDetails();
    if (details?.didNotificationLaunchApp ?? false) {
      _route(details!.notificationResponse?.payload);
    }
  }

  void _route(String? payload) {
    if (payload == _kPayloadJunkReview) {
      // A frame or two after a cold start, the navigator may not be
      // attached yet — addPostFrameCallback runs after the current frame
      // finishes building rather than needing this to be synchronous.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        appNavigatorKey.currentState?.push(
          MaterialPageRoute(builder: (_) => const JunkReviewScreen()),
        );
      });
    }
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

  /// [count] is capped at kJunkBatchSize by the caller (background_service.dart)
  /// — this doesn't re-check, it just reports whatever it's given. Reusing
  /// id 1004 for every call means a second batch accumulating before the
  /// first is reviewed updates the existing notification instead of piling
  /// up a new one each time — exactly the "notify rarely" half of the
  /// scan-often-notify-rarely cadence background_service.dart implements.
  Future<void> notifyJunkBatchReady(int count) async {
    await _show(
      id: 1004,
      title: 'Junk to clear out',
      body: '$count screenshot${count == 1 ? '' : 's'} look like junk — '
          'swipe through and clear them out.',
      payload: _kPayloadJunkReview,
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
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
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
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  Future<void> _show({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    await _plugin.show(id, title, body, _notifDetails(), payload: payload);
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
