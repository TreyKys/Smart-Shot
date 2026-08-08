// Runs the real app on a device/emulator — plugins (Isar, photo_manager,
// notifications) are backed by their real platform implementations here,
// unlike widget_test.dart which can't boot SiftApp at all.
import 'package:flutter_riverpod/flutter_riverpod.dart';
// patrol_finders supplies the $ finder API but not flutter_test's matchers,
// so expect/findsOneWidget need this import explicitly.
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:patrol_finders/patrol_finders.dart';
import 'package:sift/features/gallery/presentation/gallery_screen.dart';
import 'package:sift/main.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  patrolWidgetTest(
    'fresh install: skip onboarding via Live Mode reaches the gallery',
    ($) async {
      await $.pumpWidgetAndSettle(const ProviderScope(child: SiftApp()));

      await $('Skip').tap();
      await $.pumpAndSettle();

      await $('Live Mode').tap();
      await $.pumpAndSettle();

      expect($(GalleryScreen), findsOneWidget);
    },
  );
}
