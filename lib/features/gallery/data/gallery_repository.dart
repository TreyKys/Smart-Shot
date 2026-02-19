import 'dart:io';
import 'package:isar/isar.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:smart_shot/core/database/isar_service.dart';
import 'package:smart_shot/features/gallery/domain/screenshot.dart';
import 'package:smart_shot/features/ingestion/services/ocr_service.dart';

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

    final PermissionState ps = await PhotoManager.requestPermissionExtend();
    if (!ps.isAuth) return;

    final List<AssetPathEntity> paths = await PhotoManager.getAssetPathList(
      type: RequestType.image,
      filterOption: FilterOptionGroup(
        orders: [const OrderOption(type: OrderOptionType.createDate, asc: false)],
      ),
    );

    if (paths.isEmpty) return;

    // Use the "Recent" album (usually the first one)
    final recentAlbum = paths.first;

    // Fetch a large batch. For production, pagination is better.
    // Fetching 500 for MVP.
    final List<AssetEntity> assets = await recentAlbum.getAssetListRange(start: 0, end: 500);

    for (final asset in assets) {
      final file = await asset.file;
      if (file == null) continue;

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
            ..filePath = file.path
            ..timestamp = asset.createDateTime;
           await isar.screenshots.put(screenshot);
        });
      }
    }

    // Trigger processing
    _processPendingScreenshots();
  }

  Future<void> _processPendingScreenshots() async {
    final isar = await _ref.read(isarProvider.future);
    final ocrService = _ref.read(ocrServiceProvider);

    final unprocessed = await isar.screenshots.filter().isProcessedEqualTo(false).findAll();

    for (final screenshot in unprocessed) {
      final file = File(screenshot.filePath);
      if (!file.existsSync()) continue;

      final text = await ocrService.processImage(file);

      await isar.writeTxn(() async {
         screenshot.ocrText = text;
         screenshot.isProcessed = true;
         await isar.screenshots.put(screenshot);
      });
    }
  }

  Stream<List<Screenshot>> watchScreenshots() async* {
     final isar = await _ref.read(isarProvider.future);
     yield* isar.screenshots.where().sortByTimestampDesc().watch(fireImmediately: true);
  }
}
