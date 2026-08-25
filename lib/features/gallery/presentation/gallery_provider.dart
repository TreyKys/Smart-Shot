import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
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

/// Stream of (tag, count) pairs sorted by count descending, for the drawer.
final tagCountsProvider = StreamProvider<List<({String tag, int count})>>((ref) {
  final repository = ref.watch(galleryRepositoryProvider);
  return repository.watchScreenshots().map((screenshots) {
    final map = <String, int>{};
    for (final s in screenshots) {
      for (final t in s.tags ?? []) {
        map[t] = (map[t] ?? 0) + 1;
      }
    }
    return (map.entries
        .map((e) => (tag: e.key, count: e.value))
        .toList()
      ..sort((a, b) => b.count.compareTo(a.count)));
  });
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

/// Total number of screenshots in the library, independent of any tag
/// filter — unlike [galleryStreamProvider], which follows
/// [selectedTagProvider] and therefore reflects the filtered count once a
/// tag is selected.
final totalScreenshotCountProvider = StreamProvider<int>((ref) {
  final repository = ref.watch(galleryRepositoryProvider);
  return repository.watchScreenshots().map((list) => list.length);
});
