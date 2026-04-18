import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:isar/isar.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sift/core/database/isar_service.dart';
import 'package:sift/features/economy/economy_service.dart';
import 'package:sift/features/gallery/domain/screenshot.dart';
import 'package:sift/features/gallery/presentation/providers/processing_progress_provider.dart';
import 'package:sift/features/gallery/services/dedup_service.dart';
import 'package:sift/features/ingestion/services/llm_service.dart';
import 'package:sift/features/ingestion/services/ocr_service.dart';

part 'gallery_repository.g.dart';

@Riverpod(keepAlive: true)
GalleryRepository galleryRepository(GalleryRepositoryRef ref) {
  return GalleryRepository(ref);
}

class GalleryRepository {
  final GalleryRepositoryRef _ref;

  GalleryRepository(this._ref);

  // ── Sync ──────────────────────────────────────────────────────────────────

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
        orders: [
          const OrderOption(type: OrderOptionType.createDate, asc: false)
        ],
      ),
    );

    if (paths.isEmpty) return;

    final album = paths.firstWhere((p) => p.isAll, orElse: () => paths.first);
    final count = await album.assetCountAsync;
    if (count == 0) return;

    final prefs = await SharedPreferences.getInstance();
    final mode = prefs.getString('smart_indexing_mode');
    final liveTs = prefs.getInt('live_mode_timestamp') ?? 0;

    // Fetch first 10 immediately for fast UI paint
    final firstBatch = await album.getAssetListRange(start: 0, end: 10);
    await _ingestAssets(firstBatch, isar, mode, liveTs, startIndex: 0);

    // Then ingest the rest lazily in the background
    final total = count > 500 ? 500 : count;
    if (total > 10) {
      Future.microtask(() async {
        for (int offset = 10; offset < total; offset += 20) {
          final end = (offset + 20).clamp(0, total);
          final batch =
              await album.getAssetListRange(start: offset, end: end);
          await _ingestAssets(batch, isar, mode, liveTs,
              startIndex: offset);
          await Future.delayed(Duration.zero); // yield to event loop
        }
        // Once all ingested, kick off automatic AI processing
        _processAllPending();
      });
    } else {
      _processAllPending();
    }
  }

  Future<void> _ingestAssets(
    List<AssetEntity> assets,
    Isar isar,
    String? mode,
    int liveTs, {
    required int startIndex,
  }) async {
    for (int i = 0; i < assets.length; i++) {
      final asset = assets[i];
      final idx = startIndex + i;

      // Live mode: only recent 40, then respect timestamp cutoff
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

      // Skip if already in DB
      final existing = await isar.screenshots
          .where()
          .filePathEqualTo(file.path)
          .findFirst();
      if (existing != null) continue;

      // Perceptual dedup — run in compute isolate
      final hash = await compute(
          DedupService.hashIsolateEntry, file.absolute.path);
      if (hash != null && await _isDuplicate(hash)) {
        debugPrint('Dedup: skipping ${file.path}');
        continue;
      }

      await isar.writeTxn(() async {
        final shot = Screenshot()
          ..filePath = file!.path
          ..timestamp = asset.createDateTime
          ..isProcessed = false;
        await isar.screenshots.put(shot);
      });

      // Persist hash for future dedup checks
      if (hash != null) {
        final p = await SharedPreferences.getInstance();
        await p.setString('dhash:${file.path}', hash);
      }
    }
  }

  Future<bool> _isDuplicate(String newHash) async {
    final p = await SharedPreferences.getInstance();
    for (final key in p.getKeys().where((k) => k.startsWith('dhash:'))) {
      final h = p.getString(key);
      if (h != null && DedupService.areDuplicates(newHash, h)) return true;
    }
    return false;
  }

  // ── Share intent ───────────────────────────────────────────────────────────

  Future<void> addFile(File file) async {
    final isar = await _ref.read(isarProvider.future);
    final existing = await isar.screenshots
        .where()
        .filePathEqualTo(file.path)
        .findFirst();
    if (existing != null) return;

    await isar.writeTxn(() async {
      final shot = Screenshot()
        ..filePath = file.path
        ..timestamp = await file.lastModified()
        ..isProcessed = false;
      await isar.screenshots.put(shot);
    });
    debugPrint('Shared file ingested: ${file.path}');
    _processAllPending();
  }

  // ── Automatic AI processing ───────────────────────────────────────────────

  Future<void> _processAllPending() async {
    final isar = await _ref.read(isarProvider.future);
    final ocrService = _ref.read(ocrServiceProvider);
    final llmService = _ref.read(llmServiceProvider);
    final economyNotifier = _ref.read(economyServiceProvider.notifier);
    final progress = _ref.read(processingProgressProvider.notifier);

    // Resolve effective API key: BYOK > .env
    final byokKey = economyNotifier.getByokKey() ?? '';
    final envKey = dotenv.env['GEMINI_API_KEY'] ?? '';
    final apiKey = byokKey.isNotEmpty ? byokKey : envKey;
    final hasKey = apiKey.isNotEmpty && apiKey != 'INSERT_API_KEY_HERE';

    if (!hasKey) {
      debugPrint('⚠ No Gemini API key — OCR only. Set GEMINI_API_KEY in .env or BYOK in Settings.');
    }

    final unprocessed = await isar.screenshots
        .filter()
        .isProcessedEqualTo(false)
        .sortByTimestamp()
        .findAll();

    if (unprocessed.isEmpty) {
      debugPrint('No unprocessed screenshots.');
      return;
    }

    debugPrint('Auto-processing ${unprocessed.length} screenshots…');
    progress.start(unprocessed.length);

    int processed = 0;

    for (final shot in unprocessed) {
      // Quota gate (skip entirely for BYOK/Pro)
      if (byokKey.isEmpty) {
        final hasEnergy = await economyNotifier.hasEnoughEnergy();
        if (!hasEnergy) {
          debugPrint('Daily AI quota reached at $processed processed.');
          break;
        }
      }

      final file = File(shot.filePath);
      if (!file.existsSync()) {
        await isar.writeTxn(() async {
          shot.isProcessed = true;
          await isar.screenshots.put(shot);
        });
        progress.advance();
        continue;
      }

      try {
        // Start OCR and LLM in parallel — both only need the file path.
        // OCR is on-device and fast; LLM is network I/O. Running together
        // roughly halves processing time per image.
        final ocrFuture = ocrService.processImage(file);
        final llmFuture = hasKey
            ? llmService.processFile(file, apiKey: apiKey)
            : Future.value(<String, dynamic>{});

        final text = await ocrFuture;
        debugPrint('OCR: ${text.length} chars — ${shot.filePath}');

        Map<String, dynamic> llmResult;
        try {
          llmResult = await llmFuture;
        } catch (llmErr) {
          debugPrint('LLM error for shot ${shot.id}: $llmErr — saving OCR only');
          llmResult = {};
        }

        await isar.writeTxn(() async {
          shot.ocrText = text;
          if (llmResult.isNotEmpty) {
            shot.cleanText = llmResult['cleanText'] as String?;
            shot.tags = _list(llmResult['tags']);
            shot.urls = _list(llmResult['urls']);
            shot.emails = _list(llmResult['emails']);
            shot.phoneNumbers = _list(llmResult['phoneNumbers']);
            shot.dates = _list(llmResult['dates']);
            shot.cryptoAddresses = _list(llmResult['cryptoAddresses']);
            shot.suggestedActions = _buildActions(llmResult);
          }
          shot.isProcessed = true;
          await isar.screenshots.put(shot);
        });

        if (hasKey && byokKey.isEmpty) await economyNotifier.consumeEnergy(1);

        processed++;
        progress.advance();

        await Future.delayed(const Duration(milliseconds: 100));
      } catch (e) {
        // Don't mark isProcessed = true — will retry on next sync
        debugPrint('Processing error for shot ${shot.id}: $e');
        progress.advance(); // still advance UI counter
      }
    }

    progress.finish();
    debugPrint('Auto-processing complete. $processed of ${unprocessed.length} handled.');
  }

  /// Marks every screenshot as unprocessed so the pipeline re-runs on next sync.
  Future<void> reprocessAll() async {
    final isar = await _ref.read(isarProvider.future);
    await isar.writeTxn(() async {
      final all = await isar.screenshots.where().findAll();
      for (final s in all) {
        s.isProcessed = false;
      }
      await isar.screenshots.putAll(all);
    });
    debugPrint('Re-processing all ${(await isar.screenshots.count())} screenshots.');
    _processAllPending();
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
      actions.add(SuggestedAction()
        ..label = _appName(appId)
        ..payload = _appUrl(appId)
        ..intentType = 'app_recommendation');
    }
    return actions;
  }

  // ── Watch stream ───────────────────────────────────────────────────────────

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

  // ── Helpers ────────────────────────────────────────────────────────────────

  List<String>? _list(dynamic raw) {
    if (raw == null) return null;
    return (raw as List).map((e) => e.toString()).toList();
  }

  static String _appName(String id) {
    switch (id) {
      case 'pulse': return 'Pulse';
      case 'context': return 'Context Dictionary';
      case 'magnum_opus': return 'Magnum Opus';
      default: return id;
    }
  }

  static String _appUrl(String id) {
    switch (id) {
      case 'pulse': return 'https://neurodevlabs.com/pulse';
      case 'context': return 'https://neurodevlabs.com/context';
      case 'magnum_opus': return 'https://neurodevlabs.com/magnum-opus';
      default: return 'https://neurodevlabs.com';
    }
  }
}
