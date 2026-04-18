import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sift/features/gallery/domain/screenshot.dart';
import 'package:sift/features/ingestion/services/llm_service.dart';
import 'package:sift/features/ingestion/services/ocr_service.dart';
import 'package:sift/features/ingestion/services/tag_engine.dart';
import 'package:workmanager/workmanager.dart';

const String kDeepScanTask = "com.smartshot.deepscan";
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
    await dotenv.load(fileName: ".env");

    final dir = await getApplicationDocumentsDirectory();
    final isar = await Isar.open(
      [ScreenshotSchema],
      directory: dir.path,
    );

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

    final ocrService = OcrService();
    final llmService = LLMService(apiKey: dotenv.env['GEMINI_API_KEY'] ?? '');

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
        // Phase 1: OCR (warm file cache in parallel)
        final ocrText = await ocrService.processImage(file);
        debugPrint('OCR: ${ocrText.length} chars — ${screenshot.filePath}');

        // Phase 2: dual-signal Gemini call
        Map<String, dynamic> llmResult = {};
        try {
          llmResult = await llmService.processFile(file, ocrText: ocrText);
        } catch (llmErr) {
          debugPrint("LLM error for ${screenshot.id}: $llmErr — using local tags only");
        }

        // Phase 3: merge AI tags with local engine
        final aiTags = _toList(llmResult['tags']) ?? [];
        final localTags = TagEngine.suggestFromOcr(ocrText);
        final isJunk = TagEngine.isLikelyJunk(ocrText, file);
        final finalTags = (isJunk && aiTags.isEmpty && localTags.isEmpty)
            ? ['#Junk']
            : TagEngine.merge(aiTags, localTags);

        await isar.writeTxn(() async {
          screenshot.ocrText = ocrText;
          screenshot.tags = finalTags.isEmpty ? null : finalTags;
          if (llmResult.isNotEmpty) {
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
    await isar.close();
    return true;
  } catch (e) {
    debugPrint("Background task failed: $e");
    return false;
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
  if (appId is String && appId.isNotEmpty && appId != 'null') {
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

void scheduleDeepScan() {
  Workmanager().registerPeriodicTask(
    "deepScanTask",
    kDeepScanTask,
    frequency: const Duration(minutes: 15),
    initialDelay: const Duration(seconds: 10),
    constraints: Constraints(
      networkType: NetworkType.connected,
      requiresBatteryNotLow: true,
    ),
  );
}

void cancelDeepScan() {
  Workmanager().cancelByUniqueName("deepScanTask");
}
