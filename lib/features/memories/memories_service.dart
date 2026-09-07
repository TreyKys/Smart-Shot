import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import 'package:sift/core/database/isar_service.dart';
import 'package:sift/features/gallery/domain/screenshot.dart';

/// One "on this day" memory — every screenshot whose real timestamp falls on
/// today's month/day in a past year, grouped by how many years ago that was.
/// No fabricated location, no curated-highlight scoring — just the
/// timestamp every screenshot already has from ingestion.
@immutable
class Memory {
  final int yearsAgo;
  final List<Screenshot> shots;
  const Memory({required this.yearsAgo, required this.shots});
}

/// Groups screenshots whose timestamp falls on [today]'s month/day in a past
/// year — pure, no Isar dependency, so it's directly testable against plain
/// in-memory Screenshot objects rather than needing a real open database.
///
/// A Feb 29 memory only resurfaces on an actual Feb 29 (once every four
/// years) rather than nearby dates in non-leap years — exact month/day
/// matching only, same as how most "on this day" features behave; not
/// worth the edge-case complexity of fuzzy-matching a date that occurs on
/// 1/1461 days.
@visibleForTesting
List<Memory> groupMemories(List<Screenshot> all, DateTime today) {
  final byYearsAgo = <int, List<Screenshot>>{};
  for (final shot in all) {
    final t = shot.timestamp;
    if (t.month == today.month && t.day == today.day && t.year < today.year) {
      byYearsAgo.putIfAbsent(today.year - t.year, () => []).add(shot);
    }
  }
  return byYearsAgo.entries
      .map((e) => Memory(yearsAgo: e.key, shots: e.value))
      .toList()
    ..sort((a, b) => a.yearsAgo.compareTo(b.yearsAgo));
}

/// Runs [groupMemories] against a real Isar handle — the only two callers
/// are the UI isolate's [memoriesProvider] below and the WorkManager
/// background isolate's own bare Isar handle (background_service.dart),
/// which has no Riverpod container to read a provider from at all, so this
/// takes a plain Isar rather than a Ref.
Future<List<Memory>> findMemories(Isar isar, {DateTime? now}) async {
  final all = await isar.screenshots.where().findAll();
  return groupMemories(all, now ?? DateTime.now());
}

/// autoDispose — today's memories are only worth holding while Discover is
/// actually open, not kept alive across the whole app session the way
/// something like the tag counts (watched from several screens) are.
final memoriesProvider = FutureProvider.autoDispose<List<Memory>>((ref) async {
  final isar = await ref.watch(isarProvider.future);
  return findMemories(isar);
});
