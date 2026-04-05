import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:smart_shot/features/gallery/data/gallery_repository.dart';
import 'package:smart_shot/features/gallery/domain/screenshot.dart';

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
  // Watch all screenshots (no filter)
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
