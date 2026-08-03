import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:isar/isar.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sift/core/config/app_config.dart';
import 'package:sift/core/database/isar_service.dart';
import 'package:sift/features/economy/economy_service.dart';
import 'package:sift/features/gallery/domain/screenshot.dart';
import 'package:sift/features/gallery/presentation/providers/processing_progress_provider.dart';
import 'package:sift/features/gallery/services/dedup_service.dart';
import 'package:sift/features/ingestion/services/llm_service.dart';
import 'package:sift/features/ingestion/services/ocr_service.dart';
import 'package:sift/features/ingestion/services/tag_engine.dart';
import 'package:sift/services/notification_service.dart';

part 'gallery_repository.g.dart';

@Riverpod(keepAlive: true)
GalleryRepository galleryRepository(GalleryRepositoryRef ref) {
  return GalleryRepository(ref);
}

/// Upper bound on how many assets a single sync will ingest.
const int _kMaxIngestCount = 500;

class GalleryRepository {
  final GalleryRepositoryRef _ref;

  /// syncGallery() is reachable from app resume, pull-to-refresh and several
  /// buttons, and _processAllPending() from five call sites. Without this
  /// guard two overlapping runs process the same rows twice — burning double
  /// the AI quota and double-billing the user's daily energy.
  bool _isProcessing = false;

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

    // Loaded once for the whole run rather than per image.
    final dedup = await _DedupIndex.load();

    // Fetch first 10 immediately for fast UI paint
    final firstBatch = await album.getAssetListRange(start: 0, end: 10);
    await _ingestAssets(firstBatch, isar, mode, liveTs,
        startIndex: 0, dedup: dedup);

    // Then ingest the rest lazily in the background
    final total = count > _kMaxIngestCount ? _kMaxIngestCount : count;
    if (total > 10) {
      Future.microtask(() async {
        for (int offset = 10; offset < total; offset += 20) {
          final end = (offset + 20).clamp(0, total);
          final batch =
              await album.getAssetListRange(start: offset, end: end);
          await _ingestAssets(batch, isar, mode, liveTs,
              startIndex: offset, dedup: dedup);
          await Future.delayed(Duration.zero); // yield to event loop
        }
        await dedup.flush();
        // Once all ingested, kick off automatic AI processing
        _processAllPending();
      });
    } else {
      await dedup.flush();
      _processAllPending();
    }
  }

  Future<void> _ingestAssets(
    List<AssetEntity> assets,
    Isar isar,
    String? mode,
    int liveTs, {
    required int startIndex,
    required _DedupIndex dedup,
  }) async {
    // Collected across the batch so the whole batch lands in one transaction
    // instead of one transaction per image.
    final newShots = <Screenshot>[];

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
      if (hash != null && dedup.isDuplicate(hash)) {
        debugPrint('Dedup: skipping ${file.path}');
        continue;
      }

      newShots.add(Screenshot()
        ..filePath = file.path
        ..timestamp = asset.createDateTime
        ..isProcessed = false);

      // Buffered — persisted by dedup.flush() once the run completes.
      if (hash != null) dedup.add(file.path, hash);
    }

    if (newShots.isNotEmpty) {
      await isar.writeTxn(() async {
        await isar.screenshots.putAll(newShots);
      });
    }
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

  // ── Mutation helpers ───────────────────────────────────────────────────────

  /// Deletes a screenshot record from Isar and the file from disk.
  Future<void> deleteScreenshot(int id) async {
    final isar = await _ref.read(isarProvider.future);
    final shot = await isar.screenshots.get(id);
    final filePath = shot?.filePath;
    await isar.writeTxn(() async {
      await isar.screenshots.delete(id);
    });
    if (filePath != null) {
      try {
        final file = File(filePath);
        if (await file.exists()) await file.delete();
        await _DedupIndex.forget(filePath);
      } catch (e) {
        debugPrint('deleteScreenshot: file delete failed — $e');
      }
    }
  }

  /// Overwrites the tags list for a given screenshot.
  Future<void> updateTags(int id, List<String> tags) async {
    final isar = await _ref.read(isarProvider.future);
    await isar.writeTxn(() async {
      final shot = await isar.screenshots.get(id);
      if (shot == null) return;
      shot.tags = tags.isEmpty ? null : tags;
      await isar.screenshots.put(shot);
    });
  }


  // ── Automatic AI processing ───────────────────────────────────────────────

  Future<void> _processAllPending() async {
    if (_isProcessing) {
      debugPrint('_processAllPending: already running — skipping.');
      return;
    }
    _isProcessing = true;
    try {
      await _processAllPendingInner();
    } finally {
      _isProcessing = false;
    }
  }

  Future<void> _processAllPendingInner() async {
    final isar = await _ref.read(isarProvider.future);
    final ocrService = _ref.read(ocrServiceProvider);
    final llmService = _ref.read(llmServiceProvider);
    final economyNotifier = _ref.read(economyServiceProvider.notifier);
    final progress = _ref.read(processingProgressProvider.notifier);

    // Resolve effective API key: BYOK > build-time config
    final byokKey = economyNotifier.getByokKey() ?? '';
    final envKey = AppConfig.geminiApiKey;
    final apiKey = byokKey.isNotEmpty ? byokKey : envKey;
    final hasKey = apiKey.isNotEmpty;

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
        // Phase 1: run OCR on-device
        final ocrText = await ocrService.processImage(file);
        debugPrint('OCR: ${ocrText.length} chars — ${shot.filePath}');

        // Phase 2: send image + OCR text together to Gemini (dual-signal)
        Map<String, dynamic> llmResult = {};
        if (hasKey) {
          try {
            llmResult = await llmService.processFile(
              file,
              apiKey: apiKey,
              ocrText: ocrText,
            );
          } catch (llmErr) {
            debugPrint('LLM error for shot ${shot.id}: $llmErr — using OCR + local tags only');
          }
        }

        // Phase 3: merge AI tags with local keyword-scoring engine
        final aiTags = _list(llmResult['tags']) ?? [];
        final localTags = TagEngine.suggestFromOcr(ocrText);
        final isJunk = TagEngine.isLikelyJunk(ocrText, file);

        final List<String> finalTags;
        if (isJunk) {
          // Junk always wins — prepend #Junk, keep any other AI context
          final others = TagEngine.merge(aiTags, []).where((t) => t != '#Junk').toList();
          finalTags = ['#Junk', ...others];
        } else {
          finalTags = TagEngine.merge(aiTags, localTags);
        }

        await isar.writeTxn(() async {
          shot.ocrText = ocrText;
          shot.tags = finalTags.isEmpty ? null : finalTags;
          if (llmResult.isNotEmpty) {
            shot.cleanText = llmResult['cleanText'] as String?;
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
      } catch (e) {
        // Don't mark isProcessed = true — will retry on next sync
        debugPrint('Processing error for shot ${shot.id}: $e');
        progress.advance(); // still advance UI counter
      }
    }

    progress.finish();
    if (processed > 0) {
      await NotificationService.instance.notifyProcessingComplete(processed);
    }
    debugPrint('Auto-processing complete. $processed of ${unprocessed.length} handled.');
  }

  /// Resets only screenshots that have garbage/invented tags so they get re-tagged.
  Future<void> reprocessGarbageTags() async {
    final isar = await _ref.read(isarProvider.future);
    const badTags = {
      '#BlankImage', '#Empty', '#NoContent', '#Unknown', '#Blank',
      'BlankImage', 'Empty', 'NoContent', 'Unknown', 'Blank',
    };
    await isar.writeTxn(() async {
      final all = await isar.screenshots.where().findAll();
      final toReset = all.where((s) =>
          s.tags != null && s.tags!.any((t) => badTags.contains(t)));
      for (final s in toReset) {
        s.isProcessed = false;
        s.tags = null;
      }
      await isar.screenshots.putAll(toReset.toList());
    });
    debugPrint('reprocessGarbageTags: reset screenshots with bad tags.');
    _processAllPending();
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
    debugPrint('_list: unexpected type ${raw.runtimeType} — ignoring');
    return [];
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

/// In-memory perceptual-hash index for the duration of one sync run.
///
/// Replaces the previous approach, which per image opened SharedPreferences,
/// enumerated every key, and re-parsed each stored hex hash into a 64-char bit
/// string to compare. That is O(n²) hash comparisons with a very large
/// constant, plus a full XML rewrite per stored hash. Here the index loads
/// once, compares packed ints, and persists in a single write.
class _DedupIndex {
  static const _kIndexKey = 'dhash_index_v2';
  static const _kLegacyPrefix = 'dhash:';

  final SharedPreferences _prefs;
  final Map<String, String> _byPath;
  final List<List<int>> _packed;
  bool _dirty = false;

  _DedupIndex._(this._prefs, this._byPath, this._packed);

  static Future<_DedupIndex> load() async {
    final prefs = await SharedPreferences.getInstance();
    final byPath = <String, String>{};

    final raw = prefs.getString(_kIndexKey);
    if (raw != null && raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map) {
          decoded.forEach((k, v) {
            if (v is String) byPath['$k'] = v;
          });
        }
      } catch (e) {
        debugPrint('_DedupIndex: corrupt index, rebuilding — $e');
      }
    }

    // Absorb hashes written by the old per-path key scheme.
    final legacyKeys =
        prefs.getKeys().where((k) => k.startsWith(_kLegacyPrefix)).toList();
    for (final key in legacyKeys) {
      final h = prefs.getString(key);
      if (h != null) byPath[key.substring(_kLegacyPrefix.length)] = h;
    }

    final packed = <List<int>>[];
    for (final h in byPath.values) {
      final p = DedupService.pack(h);
      if (p != null) packed.add(p);
    }

    final index = _DedupIndex._(prefs, byPath, packed);
    if (legacyKeys.isNotEmpty) {
      // Migrate: fold the old keys into the blob and drop them.
      for (final key in legacyKeys) {
        await prefs.remove(key);
      }
      index._dirty = true;
      debugPrint('_DedupIndex: migrated ${legacyKeys.length} legacy entries.');
    }
    return index;
  }

  bool isDuplicate(String hash) {
    final p = DedupService.pack(hash);
    if (p == null) return false;
    for (final other in _packed) {
      if (DedupService.areDuplicatesPacked(p, other)) return true;
    }
    return false;
  }

  void add(String filePath, String hash) {
    final p = DedupService.pack(hash);
    if (p == null) return;
    _packed.add(p);
    _byPath[filePath] = hash;
    _dirty = true;
  }

  Future<void> flush() async {
    if (!_dirty) return;
    await _prefs.setString(_kIndexKey, jsonEncode(_byPath));
    _dirty = false;
  }

  /// Drops a single path's hash — used when a screenshot is deleted.
  static Future<void> forget(String filePath) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('$_kLegacyPrefix$filePath');
    final raw = prefs.getString(_kIndexKey);
    if (raw == null || raw.isEmpty) return;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map || !decoded.containsKey(filePath)) return;
      decoded.remove(filePath);
      await prefs.setString(_kIndexKey, jsonEncode(decoded));
    } catch (e) {
      debugPrint('_DedupIndex.forget: $e');
    }
  }
}
