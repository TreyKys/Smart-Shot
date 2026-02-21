import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:isar/isar.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_shot/core/database/isar_service.dart';
import 'package:smart_shot/features/gallery/domain/screenshot.dart';
import 'package:smart_shot/features/ingestion/services/ocr_service.dart';
import 'package:smart_shot/features/ingestion/services/llm_service.dart';

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

    // Fetch batch
    final int count = await recentAlbum.assetCountAsync;
    final int fetchCount = count > 500 ? 500 : count;

    if (fetchCount == 0) {
      debugPrint("No assets in album.");
      return;
    }

    final List<AssetEntity> assets = await recentAlbum.getAssetListRange(start: 0, end: fetchCount);
    debugPrint("Fetched ${assets.length} assets from PhotoManager.");

    final prefs = await SharedPreferences.getInstance();
    final mode = prefs.getString('smart_indexing_mode');
    final timestamp = prefs.getInt('live_mode_timestamp') ?? 0;

    int addedCount = 0;
    int index = 0;
    for (final asset in assets) {
      index++;
      // Live Mode Check: Stop processing deep history
      if (mode == 'live' && timestamp > 0) {
          // If we are past the initial "recent buffer" (e.g. 40 items) AND the asset is older than the start time
          if (index > 40 && asset.createDateTime.millisecondsSinceEpoch <= timestamp) {
              debugPrint("Live mode: Reached cutoff at index $index. Stopping sync.");
              break;
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

      if (file == null) {
        debugPrint("File is null for asset ${asset.id}. It might be cloud-only.");
        continue;
      }

      // Check if exists using a transaction is safer but slower in loop.
      // Better to batch read.
      // For MVP, we'll check individually inside the writeTxn or before.

      // We can use put by index if we had a unique ID, but filePath is unique index.
      // Isar put will update if id matches, but here we don't know the ID.
      // We rely on checking filePath.

      // Optimization: Check if it exists before writing.
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
    final ocrService = _ref.read(ocrServiceProvider);
    final llmService = _ref.read(llmServiceProvider);
    final prefs = await SharedPreferences.getInstance();
    final mode = prefs.getString('smart_indexing_mode');

    // Filter pending screenshots
    var query = isar.screenshots.filter().isProcessedEqualTo(false);
    List<Screenshot> unprocessed;

    if (mode == 'deep') {
      // In deep scan mode, only process a small batch in foreground (e.g., 5) to give immediate feedback,
      // let background task handle the rest.
      unprocessed = await query.limit(5).findAll();
    } else {
      // Live mode (or unset): Process all pending (which should be few due to sync filtering)
      unprocessed = await query.findAll();
    }

    if (unprocessed.isEmpty) return;

    debugPrint("Processing ${unprocessed.length} pending screenshots...");

    for (final screenshot in unprocessed) {
      final file = File(screenshot.filePath);
      if (!file.existsSync()) {
          debugPrint("File not found for processing: ${screenshot.filePath}");
          continue;
      }

      // 1. OCR
      final text = await ocrService.processImage(file);
      debugPrint("OCR Text length: ${text.length}");

      // 2. LLM Processing
      final Map<String, dynamic> llmResult = await llmService.processOCRText(text);

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
    }
    debugPrint("Processing complete.");
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
