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
        final text = await ocrService.processImage(file);
        final llmResult = await llmService.processOCRText(text);

        await isar.writeTxn(() async {
          screenshot.ocrText = text;

          if (llmResult.isNotEmpty) {
            screenshot.cleanText = llmResult['cleanText'] as String?;

            if (llmResult['tags'] != null) {
              screenshot.tags = (llmResult['tags'] as List).map((e) => e.toString()).toList();
            }
            if (llmResult['urls'] != null) {
              screenshot.urls = (llmResult['urls'] as List).map((e) => e.toString()).toList();
            }
            if (llmResult['emails'] != null) {
              screenshot.emails = (llmResult['emails'] as List).map((e) => e.toString()).toList();
            }
            if (llmResult['phoneNumbers'] != null) {
              screenshot.phoneNumbers = (llmResult['phoneNumbers'] as List).map((e) => e.toString()).toList();
            }
            if (llmResult['dates'] != null) {
              screenshot.dates = (llmResult['dates'] as List).map((e) => e.toString()).toList();
            }
            if (llmResult['cryptoAddresses'] != null) {
              screenshot.cryptoAddresses = (llmResult['cryptoAddresses'] as List).map((e) => e.toString()).toList();
            }
            if (llmResult['suggested_actions'] != null) {
             final actionsList = llmResult['suggested_actions'] as List;
             screenshot.suggestedActions = actionsList.map((actionJson) {
                final actionMap = actionJson as Map<String, dynamic>;
                return SuggestedAction()
                  ..label = actionMap['label'] as String?
                  ..payload = actionMap['payload'] as String?
                  ..intentType = actionMap['intent_type'] as String?;
             }).toList();
           }
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
