import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sift/features/gallery/data/gallery_repository.dart';
import 'package:sift/features/gallery/domain/screenshot.dart';

/// How many unreviewed #Junk screenshots one sitting shows at once — keeps a
/// single review session bounded even if thousands have piled up, and
/// matches the threshold the background scan uses to decide when a
/// notification is actually warranted (see background_service.dart).
const int kJunkBatchSize = 40;

/// Reactive count of #Junk screenshots nobody has swiped on yet (kept or
/// deleted, either resolves it). Drives the drawer's badge. The background
/// scan's own notification-cadence check queries Isar directly instead of
/// this provider — it runs in a separate isolate with no Riverpod container
/// of the UI's to read from.
final unreviewedJunkCountProvider = StreamProvider<int>((ref) {
  final repository = ref.watch(galleryRepositoryProvider);
  return repository
      .watchScreenshots(tag: '#Junk')
      .map((shots) => shots.where((s) => !s.junkReviewed).length);
});

/// One sitting's worth of unreviewed #Junk screenshots, newest first —
/// matches every other list in the app. A plain one-shot fetch rather than a
/// live stream: the point of a review sitting is working through a fixed
/// batch, not having cards shuffle or grow while mid-swipe as background
/// tagging adds more.
Future<List<Screenshot>> loadJunkBatch(GalleryRepository repository) async {
  final all = await repository.allScreenshots();
  return all
      .where((s) =>
          !s.junkReviewed && (s.tags?.contains('#Junk') ?? false))
      .take(kJunkBatchSize)
      .toList();
}
