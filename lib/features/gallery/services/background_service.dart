import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sift/features/gallery/domain/screenshot.dart';
import 'package:sift/features/ingestion/services/llm_service.dart';
import 'package:sift/features/ingestion/services/ocr_service.dart';
import 'package:workmanager/workmanager.dart';

const String kDeepScanTask = "com.smartshot.deepscan";
const String kPrefsIndexingMode = "smart_indexing_mode";
const String kPrefsLiveModeTimestamp = "live_mode_timestamp";
const String kPrefsLastProcessedIndex = "last_processed_index"; // For tracking batch index if needed, or rely on isProcessed flag + limit

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
    // 1. Load Env
    await dotenv.load(fileName: ".env");

    // 2. Init Isar
    final dir = await getApplicationDocumentsDirectory();
    final isar = await Isar.open(
      [ScreenshotSchema],
      directory: dir.path,
    );

    // 3. Fetch batch of 50 unprocessed images
    final screenshots = await isar.screenshots
        .filter()
        .isProcessedEqualTo(false)
        .sortByTimestamp()
        .limit(50)
        .findAll();

    if (screenshots.isEmpty) {
      debugPrint("No pending screenshots for deep scan.");
      // Could cancel task here if we want, but periodic tasks keep running.
      await isar.close();
      return true;
    }

    debugPrint("Processing batch of ${screenshots.length} screenshots...");

    // 4. Process
    final ocrService = OcrService();
    // Create LLMService manually since we are not in Riverpod scope
    final llmService = LLMService(apiKey: dotenv.env['GEMINI_API_KEY'] ?? '');

    for (final screenshot in screenshots) {
      final file = File(screenshot.filePath);
      if (!file.existsSync()) {
        debugPrint("File missing: ${screenshot.filePath}");
        await isar.writeTxn(() async {
           // Mark as processed anyway to skip next time or delete?
           // Mark as processed so we don't loop forever.
           screenshot.isProcessed = true;
           await isar.screenshots.put(screenshot);
        });
        continue;
      }

      try {
        // Use vision API (same as foreground) — start OCR + LLM in parallel
        final ocrFuture = ocrService.processImage(file);
        final llmFuture = llmService.processFile(file);

        final text = await ocrFuture;

        Map<String, dynamic> llmResult;
        try {
          llmResult = await llmFuture;
        } catch (llmErr) {
          debugPrint("LLM error for ${screenshot.id}: $llmErr — saving OCR only");
          llmResult = {};
        }

        await isar.writeTxn(() async {
          screenshot.ocrText = text;
          if (llmResult.isNotEmpty) {
            screenshot.cleanText = llmResult['cleanText'] as String?;
            screenshot.tags = _toList(llmResult['tags']);
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
    await isar.close();

    // Check if more work is needed
    // Actually Workmanager periodic tasks run every 15 mins (minimum), so we just finish this batch.

    return true;
  } catch (e) {
    debugPrint("Background task failed: $e");
    return false;
  }
}

List<String>? _toList(dynamic raw) {
  if (raw == null) return null;
  return (raw as List).map((e) => e.toString()).toList();
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
  if (appId is String && appId.isNotEmpty && appId != 'null') {
    final names = {'pulse': 'Pulse', 'context': 'Context Dictionary', 'magnum_opus': 'Magnum Opus'};
    final urls = {
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

void scheduleDeepScan() {
  Workmanager().registerPeriodicTask(
    "deepScanTask",
    kDeepScanTask,
    frequency: const Duration(minutes: 15),
    initialDelay: const Duration(seconds: 10),
    constraints: Constraints(
      networkType: NetworkType.connected, // Need internet for LLM
      requiresBatteryNotLow: true,
    ),
  );
}

void cancelDeepScan() {
  Workmanager().cancelByUniqueName("deepScanTask");
}
