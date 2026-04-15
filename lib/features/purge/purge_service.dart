import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:isar/isar.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sift/core/database/isar_service.dart';
import 'package:sift/features/gallery/domain/screenshot.dart';

part 'purge_service.g.dart';

class PurgeResult {
  final int count;
  final int totalSizeBytes;

  const PurgeResult({required this.count, required this.totalSizeBytes});

  String get formattedSize {
    if (totalSizeBytes < 1024 * 1024) {
      return '${(totalSizeBytes / 1024).toStringAsFixed(1)}KB';
    }
    return '${(totalSizeBytes / (1024 * 1024)).toStringAsFixed(1)}MB';
  }
}

const List<String> _purgeableTags = ['#Junk', '#Memes', '#To-Do', '#Meme', '#Junk', '#Todo'];
const int _purgeAgeDays = 30;

@riverpod
class PurgeService extends _$PurgeService {
  @override
  FutureOr<PurgeResult?> build() async {
    return _queryPurgeable();
  }

  Future<PurgeResult?> _queryPurgeable() async {
    final isar = await ref.read(isarProvider.future);
    final cutoff = DateTime.now().subtract(const Duration(days: _purgeAgeDays));

    final all = await isar.screenshots
        .filter()
        .isProcessedEqualTo(true)
        .timestampLessThan(cutoff)
        .findAll();

    final purgeable = all.where((s) {
      if (s.tags == null) return false;
      return s.tags!.any((t) =>
          _purgeableTags.any((pt) => t.toLowerCase() == pt.toLowerCase()));
    }).toList();

    if (purgeable.isEmpty) return null;

    int totalBytes = 0;
    for (final s in purgeable) {
      totalBytes += s.fileSizeBytes ?? 0;
      if (s.fileSizeBytes == null || s.fileSizeBytes == 0) {
        try {
          final f = File(s.filePath);
          if (f.existsSync()) totalBytes += await f.length();
        } catch (_) {}
      }
    }

    return PurgeResult(count: purgeable.length, totalSizeBytes: totalBytes);
  }

  Future<int> executePurge() async {
    final isar = await ref.read(isarProvider.future);
    final cutoff = DateTime.now().subtract(const Duration(days: _purgeAgeDays));

    final all = await isar.screenshots
        .filter()
        .isProcessedEqualTo(true)
        .timestampLessThan(cutoff)
        .findAll();

    final purgeable = all.where((s) {
      if (s.tags == null) return false;
      return s.tags!.any((t) =>
          _purgeableTags.any((pt) => t.toLowerCase() == pt.toLowerCase()));
    }).toList();

    int deleted = 0;
    for (final s in purgeable) {
      try {
        final file = File(s.filePath);
        if (file.existsSync()) {
          await file.delete();
        }
      } catch (e) {
        debugPrint('Failed to delete file ${s.filePath}: $e');
      }
      deleted++;
    }

    await isar.writeTxn(() async {
      await isar.screenshots
          .deleteAll(purgeable.map((s) => s.id).toList());
    });

    debugPrint('Purge complete. Deleted $deleted screenshots.');

    // Refresh state
    state = AsyncValue.data(await _queryPurgeable());
    return deleted;
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _queryPurgeable());
  }
}
