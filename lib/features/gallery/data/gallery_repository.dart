import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:isar/isar.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sift/core/database/isar_service.dart';
import 'package:sift/features/gallery/domain/screenshot.dart';
import 'package:sift/features/ingestion/services/ocr_service.dart';
import 'package:sift/features/ingestion/services/llm_service.dart';
import 'package:sift/features/economy/economy_service.dart';
import 'package:sift/features/pro/pro_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

part 'gallery_repository.g.dart';

@Riverpod(keepAlive: true)
GalleryRepository galleryRepository(GalleryRepositoryRef ref) {
  return GalleryRepository(ref);
}

class GalleryRepository {
  final GalleryRepositoryRef _ref;

  GalleryRepository(this._ref);

  Future<void> syncGallery() async {
    final isar = await _ref.read(isarProvider.future);

    // 1. Request native permission first (Android 13+ specific)
    // This forces the OS dialog if not already granted.
    final PermissionStatus status = await Permission.photos.request();
    debugPrint("Native Permission.photos status: $status");

    // 2. Request PhotoManager permission (Library sync)
    // This ensures PhotoManager is aware of the permission state.
    final PermissionState ps = await PhotoManager.requestPermissionExtend();
    debugPrint("PhotoManager PermissionState: $ps");

    if (!ps.isAuth) {
      debugPrint("Permission not granted according to PhotoManager: $ps");
      return;
    }

    final List<AssetPathEntity> paths = await PhotoManager.getAssetPathList(
      type: RequestType.image,
      filterOption: FilterOptionGroup(
        orders: [const OrderOption(type: OrderOptionType.createDate, asc: false)],
      ),
    );

    if (paths.isEmpty) {
        debugPrint("No asset paths found.");
        return;
    }

    // Attempt to find the "Recent" or "All" album
    final recentAlbum = paths.firstWhere((path) => path.isAll, orElse: () => paths.first);
    debugPrint("Syncing album: ${recentAlbum.name} (id: ${recentAlbum.id}), count: ${await recentAlbum.assetCountAsync}");

    // Fetch batch in rigid pagination
    final int count = await recentAlbum.assetCountAsync;
    final prefs = await SharedPreferences.getInstance();
    final isPro = _ref.read(proServiceProvider);
    final isDeepScan = prefs.getString('smart_indexing_mode') == 'deep' && isPro;
    final timestamp = prefs.getInt('live_mode_timestamp') ?? 0;

    int addedCount = 0;

    // Process in batches of 20
    const batchSize = 20;
    for (int i = 0; i < count; i += batchSize) {
      final List<AssetEntity> assets = await recentAlbum.getAssetListRange(start: i, end: i + batchSize);
      if (assets.isEmpty) break;

      bool stopSyncing = false;

      for (final asset in assets) {
        // Free users only get "live" mode regardless of deep scan preference.
        // Even Pro users respect live mode if that's what they chose.
        if (!isDeepScan) {
           if (i + assets.indexOf(asset) > 40) { // Keep buffer of 40
              if (timestamp > 0 && asset.createDateTime.millisecondsSinceEpoch <= timestamp) {
                   debugPrint("Live mode: Reached cutoff. Stopping sync.");
                   stopSyncing = true;
                   break;
               }
               if (timestamp == 0) {
                   debugPrint("Live mode: Reached buffer limit. Stopping sync.");
                   stopSyncing = true;
                   break;
               }
           }
        }

        if (asset.type != AssetType.image) continue;

        File? file;
        try {
          file = await asset.file;
        } catch (e) {
          debugPrint("Error getting file for asset ${asset.id}: $e");
          continue;
        }

        if (file == null) continue;

        final existing = await isar.screenshots.where().filePathEqualTo(file.path).findFirst();

        if (existing == null) {
          await isar.writeTxn(() async {
             final screenshot = Screenshot()
              ..filePath = file!.path
              ..timestamp = asset.createDateTime;
             await isar.screenshots.put(screenshot);
          });
          addedCount++;
        }
      }

      if (stopSyncing) break;
      // Yield to keep UI smooth
      await Future.delayed(const Duration(milliseconds: 50));
    }

    debugPrint("Sync complete. Added $addedCount new screenshots.");

    // Trigger processing
    _processPendingScreenshots();
  }

  Future<void> addFile(File file) async {
    final isar = await _ref.read(isarProvider.future);

    // Check if file exists in DB
    final existing = await isar.screenshots.where().filePathEqualTo(file.path).findFirst();

    if (existing == null) {
      await isar.writeTxn(() async {
         final screenshot = Screenshot()
          ..filePath = file.path
          ..timestamp = await file.lastModified()
          ..isProcessed = false;
         await isar.screenshots.put(screenshot);
      });
      debugPrint("Added file via Share: ${file.path}");
      // Trigger processing for the new file
      _processPendingScreenshots();
    } else {
        debugPrint("File already exists in gallery: ${file.path}");
    }
  }

  Future<void> _processPendingScreenshots() async {
    final isar = await _ref.read(isarProvider.future);

    // Filter pending screenshots
    var query = isar.screenshots.filter().isProcessedEqualTo(false);
    final unprocessed = await query.findAll();

    if (unprocessed.isEmpty) return;

    debugPrint("Processing ${unprocessed.length} pending screenshots...");

    // Spawn an Isolate for processing to keep UI smooth
    for (final screenshot in unprocessed) {
      final file = File(screenshot.filePath);
      if (!file.existsSync()) continue;

      // Ensure we have an active instance of the ocr service and isolate computation
      final text = await compute(_runOcrIsolate, file.path);

      await isar.writeTxn(() async {
         screenshot.ocrText = text;
         await isar.screenshots.put(screenshot);
      });

      // 2. LLM (Layer 2 - Bounded by Energy)
      final hasEnergy = await _ref.read(economyServiceProvider.notifier).hasEnoughEnergy();
      if (!hasEnergy) {
          debugPrint("Skipping LLM: Not enough energy.");
          // Still mark as processed so it doesn't loop forever, but user gets no AI analysis
          await isar.writeTxn(() async {
              screenshot.isProcessed = true;
              await isar.screenshots.put(screenshot);
          });
          continue;
      }

      // We have energy, process
      final llmService = _ref.read(llmServiceProvider);
      await Future.delayed(const Duration(seconds: 4)); // Respect rate limits

      final Map<String, dynamic> llmResult = await compute(_runLlmIsolate, {
        'text': text,
        'apiKey': dotenv.env['GEMINI_API_KEY'] ?? "",
      });

      await isar.writeTxn(() async {
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

      // Consume energy after successful process
      await _ref.read(economyServiceProvider.notifier).consumeEnergy(1);
    }
    debugPrint("Processing complete.");
  }

  // Top-level functions for compute()
  static Future<String> _runOcrIsolate(String filePath) async {
    final ocrService = OcrService();
    final text = await ocrService.processImage(File(filePath));
    ocrService.dispose();
    return text;
  }

  static Future<Map<String, dynamic>> _runLlmIsolate(Map<String, dynamic> args) async {
    // We cannot easily pass LLMService across isolate boundary because of GenerativeModel,
    // so we construct a temporary one with the passed in key.
    final llmService = LLMService(apiKey: args['apiKey'] as String? ?? "");
    return await llmService.processOCRText(args['text'] as String? ?? "");
  }

  Stream<List<Screenshot>> watchScreenshots({String? tag}) async* {
     final isar = await _ref.read(isarProvider.future);
     if (tag != null && tag.isNotEmpty) {
       yield* isar.screenshots.filter().tagsElementEqualTo(tag, caseSensitive: false).sortByTimestampDesc().watch(fireImmediately: true);
     } else {
       yield* isar.screenshots.where().sortByTimestampDesc().watch(fireImmediately: true);
     }
  }
}
