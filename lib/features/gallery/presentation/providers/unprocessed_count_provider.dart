import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sift/features/gallery/data/gallery_repository.dart';

/// Reactive count of screenshots still waiting on their first OCR/AI pass —
/// see [GalleryRepository.watchUnprocessedCount]. Kept in its own file
/// rather than alongside [processingProgressProvider] (a natural-looking
/// home, thematically) to avoid a circular import: gallery_repository.dart
/// already imports that file to report live progress while it runs.
final unprocessedCountProvider = StreamProvider<int>((ref) {
  final repository = ref.watch(galleryRepositoryProvider);
  return repository.watchUnprocessedCount();
});
