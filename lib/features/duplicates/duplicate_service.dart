import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sift/features/gallery/data/gallery_repository.dart';
import 'package:sift/features/gallery/domain/screenshot.dart';

/// Clusters of near-perceptually-identical screenshots, newest first within
/// each cluster — see [GalleryRepository.findDuplicateClusters] for how
/// these are actually found (the existing ingest-time dHash index, not a
/// new AI call). autoDispose rather than kept alive: this is an O(n^2) scan
/// over the whole library, worth re-running when the review screen is
/// reopened but not worth holding in memory or recomputing reactively on
/// every unrelated rebuild the way a live Isar-backed count would.
final duplicateClustersProvider =
    FutureProvider.autoDispose<List<List<Screenshot>>>((ref) {
  final repo = ref.watch(galleryRepositoryProvider);
  return repo.findDuplicateClusters();
});

/// Real file size, computed on demand — Screenshot.fileSizeBytes is declared
/// but never actually populated anywhere in this codebase (confirmed by
/// grep), so an on-demand stat is the only path that ever produces a real
/// number. Mirrors the exact fallback PurgeService already uses.
Future<int> fileSizeOf(Screenshot shot) async {
  try {
    final file = File(shot.filePath);
    if (await file.exists()) return await file.length();
  } catch (_) {
    // Swallowed deliberately: a size that can't be read shows as 0 rather
    // than blocking the review screen over a stat() failure.
  }
  return 0;
}

String formatBytes(int bytes) {
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(0)} KB';
  return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
}
