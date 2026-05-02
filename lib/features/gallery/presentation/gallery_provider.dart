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

@riverpod
Stream<List<String>> uniqueTags(UniqueTagsRef ref) async* {
  final repository = ref.watch(galleryRepositoryProvider);
  final stream = repository.watchScreenshots();

  await for (final screenshots in stream) {
      final Set<String> tags = {};
      for (var s in screenshots) {
        if (s.tags != null) {
           for (var t in s.tags!) {
             tags.add(t);
           }
        }
      }
      final sorted = tags.toList()..sort();
      yield sorted;
  }
}

/// Persisted set of pinned screenshot IDs. Populated from SharedPreferences on app start.
final pinnedIdsProvider = StateProvider<Set<int>>((ref) => {});

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
