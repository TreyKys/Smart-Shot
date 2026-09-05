import 'dart:io';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sift/core/config/shared_key_service.dart';
import 'package:sift/core/diagnostics/diagnostic_log.dart';
import 'package:sift/features/gallery/data/gallery_repository.dart'
    show discoverNewScreenshots;
import 'package:sift/features/gallery/domain/screenshot.dart';
import 'package:sift/features/ingestion/domain/tag_vocabulary.dart';
import 'package:sift/features/ingestion/services/llm_service.dart';
import 'package:sift/features/ingestion/services/ocr_service.dart';
import 'package:sift/features/ingestion/services/tag_engine.dart';
import 'package:sift/features/junk_review/junk_review_service.dart'
    show kJunkBatchSize;
import 'package:sift/services/notification_service.dart';
import 'package:workmanager/workmanager.dart';

// Name predates this task also covering Live Mode; kept as-is rather than
// renamed, since WorkManager persists it as an opaque identifier on the OS
// side and there's no user-visible reason to churn it.
const String kDeepScanTask = "com.neurodevlabs.sift.deepscan";
const String kPrefsIndexingMode = "smart_indexing_mode";
const String kPrefsLiveModeTimestamp = "live_mode_timestamp";
const String kPrefsLastProcessedIndex = "last_processed_index";

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    debugPrint("Native called background task: $task");
    if (task == kDeepScanTask) {
      return await _processDeepScanBatch();
    }
    return Future.value(true);
  });
}

Future<bool> _processDeepScanBatch() async {
  try {
    // WorkManager runs this in its own isolate with its own memory, so nothing
    // main.dart set up exists here — Firebase, App Check and the shared key all
    // have to be established again. SharedKeyService caches into a static, and
    // that static is empty in this isolate no matter what the UI isolate
    // fetched. Skipping the initialize() below would leave every background
    // scan falling back to local-only tags while the foreground worked fine.
    try {
      await Firebase.initializeApp();
      await FirebaseAppCheck.instance.activate(
        providerAndroid: kDebugMode
            ? const AndroidDebugProvider()
            : const AndroidPlayIntegrityProvider(),
      );
      // After App Check, so the fetch carries an attestation token.
      await SharedKeyService.initialize();
    } catch (e) {
      debugPrint('Background isolate Firebase/App Check init failed: $e');
      DiagnosticLog.error(
          'Background scan: Firebase/App Check init failed ($e) — this '
          'batch will fall back to local-only tags unless a BYOK key is '
          'set.');
    }

    final dir = await getApplicationDocumentsDirectory();
    final isar = await Isar.open(
      [ScreenshotSchema],
      directory: dir.path,
    );

    // Without this, the periodic task only ever reprocesses whatever the UI
    // last queued — a user who never reopens the app after choosing Live
    // Mode would get no indexing at all, since nothing else discovers new
    // screenshots. This is the same scan syncGallery() runs in the
    // foreground, factored out so it works from a bare Isar handle.
    try {
      // Bounded: if the permission plugin ever behaves differently than
      // expected here — e.g. blocks on a UI callback that can't fire with no
      // Activity attached — this must not hang the whole task until the OS's
      // own ~10-minute WorkManager execution limit kills it. A timeout turns
      // that into a fast, logged no-op that still falls through to
      // processing whatever was already queued.
      await discoverNewScreenshots(isar).timeout(const Duration(seconds: 20));
    } catch (e) {
      debugPrint('discoverNewScreenshots failed: $e — processing whatever '
          'is already queued.');
    }

    final screenshots = await isar.screenshots
        .filter()
        .isProcessedEqualTo(false)
        .sortByTimestamp()
        .limit(50)
        .findAll();

    if (screenshots.isEmpty) {
      debugPrint("No pending screenshots for deep scan.");
      await isar.close();
      return true;
    }

    debugPrint("Processing batch of ${screenshots.length} screenshots...");
    DiagnosticLog.info(
        'Background scan: processing batch of ${screenshots.length} '
        'screenshot(s).');

    final ocrService = OcrService();
    final llmService = LLMService();

    // Honour the user's own key here too — otherwise a BYOK user's background
    // scans would quietly spend the shared quota instead of their own key.
    final prefs = await SharedPreferences.getInstance();
    final byokKey = prefs.getString('byok_key') ?? '';

    var aiTaggedCount = 0;
    var localOnlyCount = 0;

    for (final screenshot in screenshots) {
      final file = File(screenshot.filePath);
      if (!file.existsSync()) {
        debugPrint("File missing: ${screenshot.filePath}");
        await isar.writeTxn(() async {
          screenshot.isProcessed = true;
          await isar.screenshots.put(screenshot);
        });
        continue;
      }

      try {
        // Phase 1: OCR — also decides whether the image is worth uploading.
        final ocr = await ocrService.processImage(file);
        debugPrint('OCR: ${ocr.charCount} chars, route=${ocr.route.name} '
            '— ${screenshot.filePath}');

        // Phase 2: AI call, routed by what phase 1 found.
        Map<String, dynamic> llmResult = {};
        try {
          llmResult = await llmService.analyze(
            file,
            byokApiKey: byokKey,
            ocr: ocr,
          );
        } catch (llmErr) {
          debugPrint("LLM error for ${screenshot.id}: $llmErr — using local tags only");
        }
        if (llmResult.isNotEmpty) {
          aiTaggedCount++;
        } else {
          localOnlyCount++;
        }

        // Phase 3: merge AI tags (closed vocabulary) with local engine
        final aiTags =
            TagVocabulary.canonicalize(_toList(llmResult['tags']) ?? const []);
        final localTags = TagEngine.suggestFromOcr(ocr.text);
        final isJunk = TagEngine.isLikelyJunk(ocr.text, file);
        final finalTags = (isJunk && aiTags.isEmpty && localTags.isEmpty)
            ? ['#Junk']
            : TagEngine.merge(aiTags, localTags);

        await isar.writeTxn(() async {
          screenshot.ocrText = ocr.text;
          screenshot.tags = finalTags.isEmpty ? null : finalTags;
          if (llmResult.isNotEmpty) {
            screenshot.topic = llmResult['topic'] as String?;
            screenshot.cleanText = llmResult['cleanText'] as String?;
            screenshot.urls = _toList(llmResult['urls']);
            screenshot.emails = _toList(llmResult['emails']);
            screenshot.phoneNumbers = _toList(llmResult['phoneNumbers']);
            screenshot.dates = _toList(llmResult['dates']);
            screenshot.cryptoAddresses = _toList(llmResult['cryptoAddresses']);
            screenshot.suggestedActions = _buildActions(llmResult);
          }
          screenshot.isProcessed = true;
          await isar.screenshots.put(screenshot);
        });
      } catch (e) {
        debugPrint("Error processing screenshot ${screenshot.id}: $e");
      }
    }

    ocrService.dispose();

    // Detection runs on every scan (cheap — one indexed count query) but the
    // notification itself is throttled, so a user isn't pinged every 15
    // minutes just because tagging keeps finding more junk. Fires early if
    // a full batch has piled up, otherwise waits out the day so it reads as
    // an occasional tidy-up nudge rather than nagging.
    await _maybeNotifyJunkBatch(isar);

    await isar.close();
    DiagnosticLog.info(
        'Background scan: done — $aiTaggedCount AI-tagged, '
        '$localOnlyCount fell back to local-only tags.');
    return true;
  } catch (e) {
    debugPrint("Background task failed: $e");
    DiagnosticLog.error('Background scan: task failed entirely — $e');
    return false;
  }
}

const String _kPrefsLastJunkNotificationAt = 'last_junk_notification_at';
const Duration _kJunkNotificationMinInterval = Duration(hours: 24);

/// Notifies at most once every [_kJunkNotificationMinInterval] — sooner only
/// if a full [kJunkBatchSize] worth of unreviewed #Junk has piled up, so a
/// heavy week doesn't just sit unnoticed until the daily window comes
/// around. A failure here (notification init, plugin channel, whatever)
/// must not fail the whole scan — tagging already succeeded by this point
/// and shouldn't be thrown away over a nudge that didn't fire.
Future<void> _maybeNotifyJunkBatch(Isar isar) async {
  try {
    final unreviewedCount = await isar.screenshots
        .filter()
        .tagsElementEqualTo('#Junk')
        .junkReviewedEqualTo(false)
        .count();
    if (unreviewedCount == 0) return;

    final prefs = await SharedPreferences.getInstance();
    final lastNotifiedMs = prefs.getInt(_kPrefsLastJunkNotificationAt) ?? 0;
    final sinceLast = DateTime.now()
        .difference(DateTime.fromMillisecondsSinceEpoch(lastNotifiedMs));

    final dueForDailyNudge = sinceLast >= _kJunkNotificationMinInterval;
    final batchIsFull = unreviewedCount >= kJunkBatchSize;
    if (!dueForDailyNudge && !batchIsFull) return;

    // A fresh plugin instance in this isolate, same as SharedKeyService
    // above — nothing main.dart's own init() set up carries over here.
    await NotificationService.instance.init();
    await NotificationService.instance
        .notifyJunkBatchReady(unreviewedCount.clamp(0, kJunkBatchSize));
    await prefs.setInt(
        _kPrefsLastJunkNotificationAt, DateTime.now().millisecondsSinceEpoch);
  } catch (e) {
    debugPrint('_maybeNotifyJunkBatch failed: $e');
    DiagnosticLog.error('Background scan: junk-batch notification failed — $e');
  }
}

List<String>? _toList(dynamic raw) {
  if (raw == null) return null;
  if (raw is List) {
    return raw
        .where((e) => e != null)
        .map((e) => e.toString().trim())
        .where((s) => s.isNotEmpty)
        .toList();
  }
  if (raw is String) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;
    if (trimmed.contains(',')) {
      return trimmed.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
    }
    return [trimmed];
  }
  debugPrint('_toList: unexpected type ${raw.runtimeType}');
  return [];
}

List<SuggestedAction> _buildActions(Map<String, dynamic> llmResult) {
  final actions = <SuggestedAction>[];
  if (llmResult['suggested_actions'] != null) {
    final raw = llmResult['suggested_actions'] as List;
    actions.addAll(raw.map((a) {
      final m = a as Map<String, dynamic>;
      return SuggestedAction()
        ..label = m['label'] as String?
        ..payload = m['payload'] as String?
        ..intentType = m['intent_type'] as String?;
    }));
  }
  final appId = llmResult['suggested_app'];
  // The schema explicitly allows the model to return the literal string
  // "none" ("Best companion app, or 'none'") — that's the documented way it
  // says "nothing to suggest here." Only excluding 'null' let 'none' fall
  // through, land in `names[appId] ?? appId`, and render a button literally
  // labeled "Try none."
  if (appId is String &&
      appId.isNotEmpty &&
      appId != 'null' &&
      appId != 'none') {
    const names = {
      'pulse': 'Pulse',
      'context': 'Context Dictionary',
      'magnum_opus': 'Magnum Opus',
    };
    const urls = {
      'pulse': 'https://neurodevlabs.com/pulse',
      'context': 'https://neurodevlabs.com/context',
      'magnum_opus': 'https://neurodevlabs.com/magnum-opus',
    };
    actions.add(SuggestedAction()
      ..label = names[appId] ?? appId
      ..payload = urls[appId] ?? 'https://neurodevlabs.com'
      ..intentType = 'app_recommendation');
  }
  return actions;
}

/// Registers the periodic background sync — both Live Mode and Deep Scan use
/// this now, since both need screenshots discovered and processed without
/// the app being open. 15 minutes is Android's floor for periodic
/// WorkManager work, not a choice made here; nothing schedules it tighter.
/// `requiresBatteryNotLow` and requiring a network connection keep it from
/// running at a cost the user would notice.
Future<void> scheduleBackgroundSync() async {
  // main.dart awaits Workmanager().initialize() before runApp(), so this
  // should never actually hit an uninitialized plugin. Caught anyway rather
  // than left to throw into a button's onPressed handler — the cost of being
  // wrong here is a dropped tap and a silent log line; the cost of not
  // catching it is a crash mid-onboarding if init ever genuinely fails.
  // registerPeriodicTask is itself async, so the try/catch has to await it —
  // wrapping the un-awaited call would only catch a synchronous throw, and
  // this one fails on the returned Future instead.
  try {
    await Workmanager().registerPeriodicTask(
      "deepScanTask",
      kDeepScanTask,
      frequency: const Duration(minutes: 15),
      initialDelay: const Duration(seconds: 10),
      constraints: Constraints(
        networkType: NetworkType.connected,
        requiresBatteryNotLow: true,
      ),
    );
  } catch (e) {
    debugPrint('scheduleBackgroundSync failed: $e');
  }
}

void cancelBackgroundSync() {
  Workmanager().cancelByUniqueName("deepScanTask");
}
