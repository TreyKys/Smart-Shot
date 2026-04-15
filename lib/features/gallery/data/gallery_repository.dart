import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:isar/isar.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sift/core/database/isar_service.dart';
import 'package:sift/features/gallery/domain/screenshot.dart';
import 'package:sift/features/gallery/services/dedup_service.dart';
import 'package:sift/features/ingestion/services/llm_service.dart';
import 'package:sift/features/ingestion/services/ocr_service.dart';
import 'package:sift/features/economy/economy_service.dart';
import 'package:sift/features/pro/pro_service.dart';

part 'gallery_repository.g.dart';

@Riverpod(keepAlive: true)
GalleryRepository galleryRepository(GalleryRepositoryRef ref) {
  return GalleryRepository(ref);
}

class GalleryRepository {
  final GalleryRepositoryRef _ref;

  GalleryRepository(this._ref);

  // ── Sync ─────────────────────────────────────────────────────────────────────

  Future<void> syncGallery() async {
    final isar = await _ref.read(isarProvider.future);

    final PermissionStatus status = await Permission.photos.request();
    debugPrint('Permission.photos: $status');

    final PermissionState ps = await PhotoManager.requestPermissionExtend();
    debugPrint('PhotoManager: $ps');

    if (!ps.isAuth) {
      debugPrint('Permission denied');
      return;
    }

    final paths = await PhotoManager.getAssetPathList(
      type: RequestType.image,
      filterOption: FilterOptionGroup(
        orders: [const OrderOption(type: OrderOptionType.createDate, asc: false)],
      ),
    );

    if (paths.isEmpty) return;

    final album = paths.firstWhere((p) => p.isAll, orElse: () => paths.first);
    final count = await album.assetCountAsync;
    if (count == 0) return;

    final prefs = await SharedPreferences.getInstance();
    final mode = prefs.getString('smart_indexing_mode');
    final liveTs = prefs.getInt('live_mode_timestamp') ?? 0;

    // Fetch the first 10 immediately for fast UI, then yield rest lazily
    final firstBatch = await album.getAssetListRange(start: 0, end: 10);
    await _ingestAssets(firstBatch, isar, mode, liveTs, prefs, startIndex: 0);

    // Background yielding loop for the rest
    final total = count > 500 ? 500 : count;
    if (total > 10) {
      Future.microtask(() async {
        for (int offset = 10; offset < total; offset += 20) {
          final end = (offset + 20).clamp(0, total);
          final batch = await album.getAssetListRange(start: offset, end: end);
          await _ingestAssets(batch, isar, mode, liveTs, prefs,
              startIndex: offset);
          await Future.delayed(Duration.zero); // yield to event loop
        }
        _processPendingScreenshots();
      });
    } else {
      _processPendingScreenshots();
    }
  }

  Future<void> _ingestAssets(
    List<AssetEntity> assets,
    Isar isar,
    String? mode,
    int liveTs,
    SharedPreferences prefs, {
    required int startIndex,
  }) async {
    for (int i = 0; i < assets.length; i++) {
      final asset = assets[i];
      final idx = startIndex + i;

      // Live mode cutoff
      if (mode == 'live' && idx > 40) {
        if (liveTs > 0 &&
            asset.createDateTime.millisecondsSinceEpoch <= liveTs) {
          debugPrint('Live mode cutoff at index $idx');
          break;
        }
        if (liveTs == 0) break;
      }

      if (asset.type != AssetType.image) continue;

      File? file;
      try {
        file = await asset.file;
      } catch (e) {
        debugPrint('Error getting file for ${asset.id}: $e');
        continue;
      }
      if (file == null) continue;

      final existing =
          await isar.screenshots.where().filePathEqualTo(file.path).findFirst();
      if (existing != null) continue;

      // Perceptual dedup
      final hash =
          await compute(DedupService.hashIsolateEntry, file.absolute.path);
      if (hash != null) {
        final duplicate = await _findDuplicate(isar, hash);
        if (duplicate) {
          debugPrint('Dedup: skipping duplicate ${file.path}');
          continue;
        }
      }

      final fileSize = await file.length();

      await isar.writeTxn(() async {
        final shot = Screenshot()
          ..filePath = file!.path
          ..timestamp = asset.createDateTime
          ..isProcessed = false;
        await isar.screenshots.put(shot);
      });

      // Store hash in SharedPreferences (not Isar — @ignore field)
      if (hash != null) {
        final hashPrefs = await SharedPreferences.getInstance();
        await hashPrefs.setString('dhash:${file.path}', hash);
      }

      debugPrint('Ingested: ${file.path} (${fileSize}B, hash=$hash)');
    }
  }

  Future<bool> _findDuplicate(Isar isar, String newHash) async {
    // We store hashes in SharedPreferences; scan them
    final hashPrefs = await SharedPreferences.getInstance();
    final keys = hashPrefs.getKeys().where((k) => k.startsWith('dhash:'));
    for (final key in keys) {
      final existing = hashPrefs.getString(key);
      if (existing != null && DedupService.areDuplicates(newHash, existing)) {
        return true;
      }
    }
    return false;
  }

  // ── Share intent ──────────────────────────────────────────────────────────────

  Future<void> addFile(File file) async {
    final isar = await _ref.read(isarProvider.future);
    final existing =
        await isar.screenshots.where().filePathEqualTo(file.path).findFirst();
    if (existing != null) {
      debugPrint('File already in gallery: ${file.path}');
      return;
    }

    await isar.writeTxn(() async {
      final shot = Screenshot()
        ..filePath = file.path
        ..timestamp = await file.lastModified()
        ..isProcessed = false;
      await isar.screenshots.put(shot);
    });
    debugPrint('Shared file ingested: ${file.path}');
    _processPendingScreenshots();
  }

  // ── Processing ────────────────────────────────────────────────────────────────

  Future<void> _processPendingScreenshots() async {
    final isar = await _ref.read(isarProvider.future);
    final ocrService = _ref.read(ocrServiceProvider);
    final economyNotifier = _ref.read(economyServiceProvider.notifier);
    final isPro = _ref.read(proServiceProvider);
    final prefs = await SharedPreferences.getInstance();
    final mode = prefs.getString('smart_indexing_mode');

    final query = isar.screenshots.filter().isProcessedEqualTo(false);
    final List<Screenshot> unprocessed = mode == 'deep'
        ? await query.limit(5).findAll()
        : await query.findAll();

    if (unprocessed.isEmpty) return;

    debugPrint('Processing ${unprocessed.length} pending screenshots…');

    final byokKey = economyNotifier.getByokKey();
    final envKey = prefs.getString('gemini_api_key') ?? '';
    final effectiveKey = economyNotifier.getEffectiveApiKey(envKey);

    int processed = 0;

    for (final shot in unprocessed) {
      // Quota gate (skip for Pro or BYOK)
      final hasEnergy = await economyNotifier.hasEnoughEnergy();
      if (!hasEnergy && !isPro && (byokKey == null || byokKey.isEmpty)) {
        debugPrint('No energy remaining — stopping processing.');
        break;
      }

      final file = File(shot.filePath);
      if (!file.existsSync()) {
        debugPrint('File missing: ${shot.filePath}');
        await isar.writeTxn(() async {
          shot.isProcessed = true;
          await isar.screenshots.put(shot);
        });
        continue;
      }

      try {
        // OCR
        final text = await ocrService.processImage(file);

        // LLM via compute() isolate
        Map<String, dynamic> llmResult = {};
        if (effectiveKey != null && effectiveKey.isNotEmpty) {
          llmResult = await compute(
            runLlmIsolate,
            LlmIsolateParams(
              filePath: file.absolute.path,
              apiKey: effectiveKey,
            ),
          );
        }

        await isar.writeTxn(() async {
          shot.ocrText = text;
          if (llmResult.isNotEmpty) {
            shot.cleanText = llmResult['cleanText'] as String?;
            shot.tags = _listFrom(llmResult['tags']);
            shot.urls = _listFrom(llmResult['urls']);
            shot.emails = _listFrom(llmResult['emails']);
            shot.phoneNumbers = _listFrom(llmResult['phoneNumbers']);
            shot.dates = _listFrom(llmResult['dates']);
            shot.cryptoAddresses = _listFrom(llmResult['cryptoAddresses']);
            if (llmResult['suggested_actions'] != null) {
              final raw = llmResult['suggested_actions'] as List;
              shot.suggestedActions = raw.map((a) {
                final m = a as Map<String, dynamic>;
                return SuggestedAction()
                  ..label = m['label'] as String?
                  ..payload = m['payload'] as String?
                  ..intentType = m['intent_type'] as String?;
              }).toList();
            }
          }
          shot.isProcessed = true;
          await isar.screenshots.put(shot);
        });

        if (effectiveKey != null && effectiveKey.isNotEmpty) {
          await economyNotifier.consumeEnergy(1);
        }

        processed++;

        // Background deep scan chunk: pause after 50, prompt re-engagement
        if (mode == 'deep' && processed >= 50) {
          debugPrint('Deep scan: processed 50 — pausing for ad engagement.');
          break;
        }

        // Yield
        await Future.delayed(const Duration(milliseconds: 100));
      } catch (e) {
        debugPrint('Error processing ${shot.id}: $e');
      }
    }

    debugPrint('Processing complete. Handled $processed screenshots.');
  }

  /// Manually triggered batch scan — respects free/Pro cap.
  Future<void> runManualBatchScan({required bool isPro}) async {
    final isar = await _ref.read(isarProvider.future);
    final economyNotifier = _ref.read(economyServiceProvider.notifier);
    final ocrService = _ref.read(ocrServiceProvider);
    final prefs = await SharedPreferences.getInstance();
    final envKey = prefs.getString('gemini_api_key') ?? '';
    final effectiveKey = economyNotifier.getEffectiveApiKey(envKey);

    final batchLimit = isPro ? kProBatchLimit : kFreeBatchLimit;
    final unprocessed = await isar.screenshots
        .filter()
        .isProcessedEqualTo(false)
        .limit(batchLimit)
        .findAll();

    if (unprocessed.isEmpty) {
      debugPrint('No unprocessed screenshots for batch scan.');
      return;
    }

    debugPrint('Manual batch scan: ${unprocessed.length} screenshots (cap=$batchLimit)');

    for (final shot in unprocessed) {
      final hasEnergy = await economyNotifier.hasEnoughEnergy();
      if (!hasEnergy && !isPro &&
          (economyNotifier.getByokKey() == null ||
              economyNotifier.getByokKey()!.isEmpty)) {
        debugPrint('Quota exhausted during batch scan.');
        break;
      }

      final file = File(shot.filePath);
      if (!file.existsSync()) continue;

      try {
        final text = await ocrService.processImage(file);
        Map<String, dynamic> llmResult = {};
        if (effectiveKey != null && effectiveKey.isNotEmpty) {
          llmResult = await compute(
            runLlmIsolate,
            LlmIsolateParams(
              filePath: file.absolute.path,
              apiKey: effectiveKey,
            ),
          );
        }

        await isar.writeTxn(() async {
          shot.ocrText = text;
          if (llmResult.isNotEmpty) {
            shot.cleanText = llmResult['cleanText'] as String?;
            shot.tags = _listFrom(llmResult['tags']);
            shot.urls = _listFrom(llmResult['urls']);
            shot.emails = _listFrom(llmResult['emails']);
            shot.phoneNumbers = _listFrom(llmResult['phoneNumbers']);
            shot.dates = _listFrom(llmResult['dates']);
            shot.cryptoAddresses = _listFrom(llmResult['cryptoAddresses']);
            if (llmResult['suggested_actions'] != null) {
              final raw = llmResult['suggested_actions'] as List;
              shot.suggestedActions = raw.map((a) {
                final m = a as Map<String, dynamic>;
                return SuggestedAction()
                  ..label = m['label'] as String?
                  ..payload = m['payload'] as String?
                  ..intentType = m['intent_type'] as String?;
              }).toList();
            }
          }
          shot.isProcessed = true;
          await isar.screenshots.put(shot);
        });

        if (effectiveKey != null && effectiveKey.isNotEmpty) {
          await economyNotifier.consumeEnergy(1);
        }

        await Future.delayed(Duration.zero);
      } catch (e) {
        debugPrint('Batch scan error for ${shot.id}: $e');
      }
    }
  }

  // ── Watch ──────────────────────────────────────────────────────────────────────

  Stream<List<Screenshot>> watchScreenshots({String? tag}) async* {
    final isar = await _ref.read(isarProvider.future);
    if (tag != null && tag.isNotEmpty) {
      yield* isar.screenshots
          .filter()
          .tagsElementEqualTo(tag, caseSensitive: false)
          .sortByTimestampDesc()
          .watch(fireImmediately: true);
    } else {
      yield* isar.screenshots
          .where()
          .sortByTimestampDesc()
          .watch(fireImmediately: true);
    }
  }

  // ── Helpers ────────────────────────────────────────────────────────────────────

  List<String>? _listFrom(dynamic raw) {
    if (raw == null) return null;
    return (raw as List).map((e) => e.toString()).toList();
  }
}
