import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:isar/isar.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sift/core/config/shared_key_service.dart';
import 'package:sift/core/database/isar_service.dart';
import 'package:sift/features/economy/economy_service.dart';
import 'package:sift/features/gallery/domain/screenshot.dart';
import 'package:sift/features/gallery/presentation/providers/processing_progress_provider.dart';
import 'package:sift/features/gallery/services/dedup_service.dart';
import 'package:sift/features/ingestion/services/llm_service.dart';
import 'package:sift/features/ingestion/services/ocr_service.dart';
import 'package:sift/features/ingestion/domain/tag_vocabulary.dart';
import 'package:sift/features/ingestion/services/tag_engine.dart';
import 'package:sift/services/notification_service.dart';

part 'gallery_repository.g.dart';

@Riverpod(keepAlive: true)
GalleryRepository galleryRepository(GalleryRepositoryRef ref) {
  return GalleryRepository(ref);
}

/// Upper bound on how many assets a single sync will ingest.
const int _kMaxIngestCount = 500;

// ── Discovery ──────────────────────────────────────────────────────────────
//
// Free-standing rather than methods on GalleryRepository, so the WorkManager
// background isolate can discover new screenshots too: that isolate has no
// Riverpod ProviderContainer, so anything it calls has to work from a plain
// Isar handle. GalleryRepository.syncGallery() below is the foreground
// caller; discoverNewScreenshots() is the background one. Both share these.

/// Finds the "all photos" album, or null if there is none to scan.
///
/// Deliberately does not call `Permission.photos.request()` — that shows a
/// system dialog, which requires a foreground Activity and is a no-op (or
/// worse, hangs) called from WorkManager's headless isolate. By the time a
/// background sync runs, the foreground app has already requested and been
/// granted (or denied) access at least once; this only re-checks that grant.
Future<AssetPathEntity?> _openAllPhotosAlbum() async {
  final PermissionState ps = await PhotoManager.requestPermissionExtend();
  debugPrint('PhotoManager: $ps');
  if (!ps.isAuth) {
    debugPrint('Permission denied');
    return null;
  }

  final paths = await PhotoManager.getAssetPathList(
    type: RequestType.image,
    filterOption: FilterOptionGroup(
      orders: [const OrderOption(type: OrderOptionType.createDate, asc: false)],
    ),
  );
  if (paths.isEmpty) return null;
  return paths.firstWhere((p) => p.isAll, orElse: () => paths.first);
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
    final existing =
        await isar.screenshots.where().filePathEqualTo(file.path).findFirst();
    if (existing != null) continue;

    // Perceptual dedup — run in compute isolate
    final hash =
        await compute(DedupService.hashIsolateEntry, file.absolute.path);
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

/// Drops a deleted screenshot's perceptual-hash entry from the dedup index.
///
/// Free-standing (like the discovery helpers above) so callers outside this
/// file — [PurgeService] included — can keep the dedup index consistent with
/// what's actually still on disk. Without this, a purged file's hash lingers
/// forever, and a future legitimate screenshot that happens to look similar
/// gets silently skipped as a "duplicate" of a file that no longer exists.
Future<void> forgetDedupHash(String filePath) => _DedupIndex.forget(filePath);

/// Background-isolate counterpart to [GalleryRepository.syncGallery] — finds
/// screenshots the gallery hasn't seen yet and inserts them unprocessed, so
/// the periodic deep-scan task in background_service.dart has something to
/// do beyond reprocessing whatever the UI last queued.
///
/// No fast-first-10 split and no `Future.microtask` tail: those exist in
/// syncGallery purely for perceived UI speed, which does not apply to a
/// headless task. This awaits everything in order and returns once ingestion
/// is actually done, which is what a WorkManager task needs — the OS expects
/// the callback to finish, not to fire off unawaited work and return early.
Future<void> discoverNewScreenshots(Isar isar) async {
  final album = await _openAllPhotosAlbum();
  if (album == null) return;

  final count = await album.assetCountAsync;
  if (count == 0) return;

  final prefs = await SharedPreferences.getInstance();
  final mode = prefs.getString('smart_indexing_mode');
  final liveTs = prefs.getInt('live_mode_timestamp') ?? 0;
  final dedup = await _DedupIndex.load();

  final total = count > _kMaxIngestCount ? _kMaxIngestCount : count;
  await prefs.setInt('ingest_deferred_count', count - total);

  for (int offset = 0; offset < total; offset += 20) {
    final end = (offset + 20).clamp(0, total);
    final batch = await album.getAssetListRange(start: offset, end: end);
    await _ingestAssets(batch, isar, mode, liveTs,
        startIndex: offset, dedup: dedup);
  }
  await dedup.flush();
  debugPrint('discoverNewScreenshots: scanned $total assets.');
}

/// Upper bound on pending rows pulled into memory for one processing run.
/// The remainder is picked up by the next run rather than loaded up front.
const int _kMaxPerRun = 300;

/// Concurrent in-flight Gemini calls. These are network-bound, so a handful in
/// parallel is a near-linear speedup; the cap keeps memory and rate limits sane.
const int _kVisionConcurrency = 4;

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

    final album = await _openAllPhotosAlbum();
    if (album == null) return;

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

    // A library larger than the cap used to be truncated with no trace, so a
    // user with 3,000 screenshots simply never saw 2,500 of them. Record the
    // remainder so the UI can say so.
    await prefs.setInt('ingest_deferred_count', count - total);
    if (count > total) {
      debugPrint('Ingest cap: ${count - total} assets deferred to a later run.');
    }

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
    final economy = _ref.read(economyServiceProvider.notifier);
    final progress = _ref.read(processingProgressProvider.notifier);

    // A BYOK key calls Gemini with the user's own key and cost. Without one,
    // LLMService falls back to the shared key Remote Config hands out after
    // App Check — nothing here needs a key compiled into the app.
    final byokKey = economy.getByokKey() ?? '';
    final canAttemptAi =
        byokKey.isNotEmpty || SharedKeyService.isConfigured;

    if (!canAttemptAi) {
      debugPrint('No BYOK key and GEMINI_PROXY_URL not configured - OCR '
          'and local tags only.');
    }

    // Newest first: the user is looking at recent screenshots, so those are the
    // ones whose tags need to appear. Bounded so a large library can't pull
    // every pending row into memory at once.
    final pending = await isar.screenshots
        .filter()
        .isProcessedEqualTo(false)
        .sortByTimestampDesc()
        .limit(_kMaxPerRun)
        .findAll();

    if (pending.isEmpty) {
      debugPrint('No unprocessed screenshots.');
      return;
    }

    debugPrint('Auto-processing ${pending.length} screenshots...');
    progress.start(pending.length);

    var processed = 0;
    for (var i = 0; i < pending.length; i += kBackgroundDeepScanChunkSize) {
      final end = math.min(i + kBackgroundDeepScanChunkSize, pending.length);
      final handled = await _processChunk(
        pending.sublist(i, end),
        isar: isar,
        ocrService: ocrService,
        llmService: llmService,
        economy: economy,
        progress: progress,
        canAttemptAi: canAttemptAi,
        byokKey: byokKey,
      );
      processed += handled;
      // A chunk handling nothing means the quota ran out; stop rather than
      // spinning through the remainder to no effect.
      if (handled == 0) break;
    }

    progress.finish();
    if (processed > 0) {
      await NotificationService.instance.notifyProcessingComplete(processed);
    }
    debugPrint('Auto-processing complete. $processed of ${pending.length} handled.');
  }

  /// Runs one chunk end to end. Returns how many screenshots were written.
  ///
  /// Ordering matters here: OCR runs first for the whole chunk because it is
  /// on-device and free, and its output decides how each screenshot reaches the
  /// model. Text-dominant ones go out in batched text-only requests; the rest
  /// are sent as images with bounded concurrency.
  Future<int> _processChunk(
    List<Screenshot> chunk, {
    required Isar isar,
    required OcrService ocrService,
    required LLMService llmService,
    required EconomyService economy,
    required ProcessingProgressNotifier progress,
    required bool canAttemptAi,
    required String byokKey,
  }) async {
    final ocrByShot = <int, OcrResult>{};
    final alive = <Screenshot>[];
    final missing = <Screenshot>[];

    for (final shot in chunk) {
      final file = File(shot.filePath);
      if (!file.existsSync()) {
        shot.isProcessed = true;
        missing.add(shot);
        progress.advance();
        continue;
      }
      ocrByShot[shot.id] = await ocrService.processImage(file);
      alive.add(shot);
    }

    if (missing.isNotEmpty) {
      await isar.writeTxn(() async => isar.screenshots.putAll(missing));
    }
    if (alive.isEmpty) return missing.length;

    // No BYOK key and no shared key — nothing to spend, so skip the
    // quota entirely and fall back to local tagging.
    if (!canAttemptAi) {
      await _writeResults(
          alive, const <int, Map<String, dynamic>>{}, ocrByShot, isar);
      for (var i = 0; i < alive.length; i++) {
        progress.advance();
      }
      return alive.length + missing.length;
    }

    // Claim the whole chunk up front. Reserving before any work starts is what
    // makes the concurrent calls below safe to run.
    final granted = await economy.reserveEnergy(alive.length);
    if (granted == 0) {
      debugPrint('Daily AI quota exhausted - deferring ${alive.length}.');
      return 0;
    }
    final toAnalyze = alive.take(granted).toList();

    // Partition by what each screenshot actually needs sent.
    final textItems = <TextAnalysisItem>[];
    final visionShots = <Screenshot>[];
    for (final shot in toAnalyze) {
      final ocr = ocrByShot[shot.id]!;
      if (ocr.route == AnalysisRoute.textOnly) {
        textItems.add(TextAnalysisItem(id: shot.id, ocrText: ocr.text));
      } else {
        visionShots.add(shot);
      }
    }
    debugPrint('Chunk: ${textItems.length} text-only, '
        '${visionShots.length} vision of ${toAnalyze.length}.');

    final results = <int, Map<String, dynamic>>{};
    final byId = {for (final s in toAnalyze) s.id: s};

    // Text-only screenshots, batched.
    for (var i = 0; i < textItems.length; i += kTextBatchSize) {
      final slice =
          textItems.sublist(i, math.min(i + kTextBatchSize, textItems.length));
      Map<int, Map<String, dynamic>> batch = {};
      try {
        batch = await llmService.analyzeTextBatch(slice, byokApiKey: byokKey);
      } catch (e) {
        debugPrint('Text batch failed ($e) - retrying individually.');
      }
      results.addAll(batch);

      // Anything the batch dropped is retried alone, so one malformed item
      // can't take the rest of the batch down with it.
      final dropped =
          slice.where((it) => !batch.containsKey(it.id)).toList();
      await _runBounded(dropped, _kVisionConcurrency, (item) async {
        final shot = byId[item.id];
        if (shot == null) return;
        try {
          results[item.id] = await llmService.analyze(
            File(shot.filePath),
            byokApiKey: byokKey,
            ocr: ocrByShot[item.id]!,
          );
        } catch (e) {
          debugPrint('Single retry failed for ${item.id}: $e');
        }
      });
    }

    // Image-bearing screenshots, run concurrently since these are
    // network-bound rather than CPU-bound.
    await _runBounded(visionShots, _kVisionConcurrency, (shot) async {
      try {
        results[shot.id] = await llmService.analyze(
          File(shot.filePath),
          byokApiKey: byokKey,
          ocr: ocrByShot[shot.id]!,
        );
      } catch (e) {
        debugPrint('Vision analysis failed for ${shot.id}: $e');
      }
    });

    await _writeResults(toAnalyze, results, ocrByShot, isar);
    for (var i = 0; i < toAnalyze.length; i++) {
      progress.advance();
    }

    // Hand back quota for anything the model never answered on, so a network
    // blip doesn't cost the user their daily allowance.
    final unanswered = toAnalyze.length - results.length;
    if (unanswered > 0) await economy.releaseEnergy(unanswered);
    await economy.recordUsage(results.length);

    return toAnalyze.length + missing.length;
  }

  /// Persists a chunk's analysis in a single transaction.
  Future<void> _writeResults(
    List<Screenshot> shots,
    Map<int, Map<String, dynamic>> results,
    Map<int, OcrResult> ocrByShot,
    Isar isar,
  ) async {
    for (final shot in shots) {
      final ocr = ocrByShot[shot.id] ?? OcrResult.empty;
      final llm = results[shot.id] ?? const <String, dynamic>{};

      final aiTags = TagVocabulary.canonicalize(_list(llm['tags']) ?? const []);
      final localTags = TagEngine.suggestFromOcr(ocr.text);
      final isJunk = TagEngine.isLikelyJunk(ocr.text, File(shot.filePath));

      // isLikelyJunk is an OCR-length/file-size heuristic that knows nothing
      // about what the model actually saw — routing sends an image via
      // AnalysisRoute.vision precisely when OCR found little text, so this
      // heuristic fires constantly on legitimate vision-routed screenshots
      // (charts, photos, UI screens). Only fall back to #Junk when neither
      // the AI nor the local engine found anything to tag it with; otherwise
      // a confident classification must not be clobbered by a blank-OCR guess.
      final finalTags = (isJunk && aiTags.isEmpty && localTags.isEmpty)
          ? const ['#Junk']
          : TagEngine.merge(aiTags, localTags);

      shot.ocrText = ocr.text;
      shot.tags = finalTags.isEmpty ? null : finalTags;
      if (llm.isNotEmpty) {
        shot.topic = llm['topic'] as String?;
        shot.cleanText = llm['cleanText'] as String?;
        shot.urls = _list(llm['urls']);
        shot.emails = _list(llm['emails']);
        shot.phoneNumbers = _list(llm['phoneNumbers']);
        shot.dates = _list(llm['dates']);
        shot.cryptoAddresses = _list(llm['cryptoAddresses']);
        shot.suggestedActions = _buildActions(llm);
      }
      shot.isProcessed = true;
    }

    await isar.writeTxn(() async => isar.screenshots.putAll(shots));
  }

  /// Runs [fn] over [items] with at most [limit] in flight at once.
  static Future<void> _runBounded<T>(
    List<T> items,
    int limit,
    Future<void> Function(T) fn,
  ) async {
    if (items.isEmpty) return;
    var next = 0;
    Future<void> worker() async {
      while (true) {
        final index = next++;
        if (index >= items.length) return;
        await fn(items[index]);
      }
    }

    final workers = math.min(limit, items.length);
    await Future.wait([for (var i = 0; i < workers; i++) worker()]);
  }

  /// Resets screenshots whose tags fall outside the closed vocabulary.
  ///
  /// Previously this matched a hardcoded list of tags the model was known to
  /// invent, which meant every newly invented tag needed a code change. Now
  /// anything [TagVocabulary] can't map is garbage by definition.
  Future<void> reprocessGarbageTags() async {
    final isar = await _ref.read(isarProvider.future);
    var reset = 0;
    await _forEachPage(isar, (page) async {
      final toReset = page.where((s) {
        final tags = s.tags;
        if (tags == null || tags.isEmpty) return false;
        return TagVocabulary.canonicalize(tags).length != tags.length;
      }).toList();
      if (toReset.isEmpty) return;
      for (final s in toReset) {
        s.isProcessed = false;
        s.tags = null;
      }
      await isar.writeTxn(() async => isar.screenshots.putAll(toReset));
      reset += toReset.length;
    });
    debugPrint('reprocessGarbageTags: reset $reset screenshots.');
    _processAllPending();
  }

  /// Marks every screenshot as unprocessed so the pipeline re-runs on next sync.
  Future<void> reprocessAll() async {
    final isar = await _ref.read(isarProvider.future);
    var count = 0;
    await _forEachPage(isar, (page) async {
      for (final s in page) {
        s.isProcessed = false;
      }
      await isar.writeTxn(() async => isar.screenshots.putAll(page));
      count += page.length;
    });
    debugPrint('Re-processing all $count screenshots.');
    _processAllPending();
  }

  /// Walks the collection a page at a time so a large library never lands in
  /// memory all at once.
  Future<void> _forEachPage(
    Isar isar,
    Future<void> Function(List<Screenshot>) visit, {
    int pageSize = 200,
  }) async {
    var offset = 0;
    while (true) {
      final page = await isar.screenshots
          .where()
          .offset(offset)
          .limit(pageSize)
          .findAll();
      if (page.isEmpty) break;
      await visit(page);
      if (page.length < pageSize) break;
      offset += pageSize;
    }
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
    // "none" as the documented way of saying "nothing to suggest here" (see
    // llm_service.dart's suggested_app enum). Only excluding 'null' let
    // 'none' fall through and render a button literally labeled "Try none."
    if (appId is String &&
        appId.isNotEmpty &&
        appId != 'null' &&
        appId != 'none') {
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
