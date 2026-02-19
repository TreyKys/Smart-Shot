import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:smart_shot/features/gallery/data/gallery_repository.dart';
import 'package:smart_shot/features/gallery/domain/screenshot.dart';

part 'gallery_provider.g.dart';

@riverpod
Stream<List<Screenshot>> galleryStream(GalleryStreamRef ref) async* {
  final repository = ref.watch(galleryRepositoryProvider);
  yield* repository.watchScreenshots();
}
