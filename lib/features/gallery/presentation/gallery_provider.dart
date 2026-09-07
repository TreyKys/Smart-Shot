import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sift/features/gallery/data/gallery_repository.dart';
import 'package:sift/features/gallery/domain/screenshot.dart';

part 'gallery_provider.g.dart';

@riverpod
class SelectedTag extends _$SelectedTag {
  @override
  String? build() => null;

  void select(String? tag) => state = tag;
}

@riverpod
Stream<List<Screenshot>> galleryStream(GalleryStreamRef ref) async* {
  final repository = ref.watch(galleryRepositoryProvider);
  final tag = ref.watch(selectedTagProvider);
  yield* repository.watchScreenshots(tag: tag);
}

/// One tag's aggregate view — real count plus a representative cover shot
/// (its most recently added screenshot). Backs both the drawer's plain list
/// and the Organize hub's cluster cards, which need the cover the drawer
/// doesn't.
class TagCluster {
  final String tag;
  final int count;
  final Screenshot cover;
  const TagCluster(
      {required this.tag, required this.count, required this.cover});
}

/// Single source of truth for both — one watchScreenshots() subscription
/// covers the drawer's plain (tag, count) list (tagCountsProvider, derived
/// below) and the Organize hub's cluster cards (which also need a cover
/// image) instead of each maintaining its own separate Isar watch over the
/// same underlying data.
final tagClustersProvider = StreamProvider<List<TagCluster>>((ref) {
  final repository = ref.watch(galleryRepositoryProvider);
  return repository.watchScreenshots().map((screenshots) {
    final counts = <String, int>{};
    final covers = <String, Screenshot>{};
    for (final s in screenshots) {
      for (final t in s.tags ?? const []) {
        counts[t] = (counts[t] ?? 0) + 1;
        // watchScreenshots() with no tag filter sorts newest-first, so the
        // first screenshot seen carrying a given tag is that tag's most
        // recent one — exactly the cover a "what's in here lately" card
        // should show.
        covers.putIfAbsent(t, () => s);
      }
    }
    final clusters = counts.entries
        .map((e) =>
            TagCluster(tag: e.key, count: e.value, cover: covers[e.key]!))
        .toList()
      ..sort((a, b) => b.count.compareTo(a.count));
    return clusters;
  });
});

/// Stream of (tag, count) pairs sorted by count descending, for the drawer.
final tagCountsProvider = StreamProvider<List<({String tag, int count})>>((ref) {
  return ref.watch(tagClustersProvider.stream).map((clusters) =>
      clusters.map((c) => (tag: c.tag, count: c.count)).toList());
});

/// Unique tag names, derived from [tagCountsProvider] rather than watching
/// the gallery a second time — a separate `watchScreenshots()` subscription
/// here would duplicate the same Isar watch query tagCountsProvider already
/// maintains.
@riverpod
Stream<List<String>> uniqueTags(UniqueTagsRef ref) {
  return ref.watch(tagCountsProvider.stream).map(
        (counts) => counts.map((e) => e.tag).toList()..sort(),
      );
}

/// Persisted set of pinned screenshot IDs. Populated from SharedPreferences on app start.
final pinnedIdsProvider = StateProvider<Set<int>>((ref) => {});

/// Toggles [screenshotId]'s pinned state and persists it under the same
/// 'pinned_ids' key every reader of [pinnedIdsProvider] expects — pulled out
/// so ImageDetailScreen and AssistantScreen's thumbnail hearts don't each
/// carry their own copy of this read-flip-write.
Future<void> togglePinned(WidgetRef ref, int screenshotId) async {
  final pinnedIds = ref.read(pinnedIdsProvider);
  final newIds = Set<int>.from(pinnedIds);
  if (!newIds.remove(screenshotId)) {
    newIds.add(screenshotId);
  }
  ref.read(pinnedIdsProvider.notifier).state = newIds;
  final prefs = await SharedPreferences.getInstance();
  await prefs.setStringList(
      'pinned_ids', newIds.map((e) => e.toString()).toList());
}

/// Total number of screenshots in the library, independent of any tag
/// filter — unlike [galleryStreamProvider], which follows
/// [selectedTagProvider] and therefore reflects the filtered count once a
/// tag is selected.
final totalScreenshotCountProvider = StreamProvider<int>((ref) {
  final repository = ref.watch(galleryRepositoryProvider);
  return repository.watchScreenshots().map((list) => list.length);
});
