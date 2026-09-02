import 'package:flutter_test/flutter_test.dart';
import 'package:sift/core/config/app_config.dart';

void main() {
  test('rewardedAdUnitId falls back to the Google test ID without --dart-define',
      () {
    // Tests always run outside release mode, so this exercises the same
    // "not configured" path a debug build would take.
    expect(AppConfig.rewardedAdUnitId, 'ca-app-pub-3940256099942544/5224354917');
  });

  test('secrets default to empty (never a hardcoded placeholder)', () {
    expect(AppConfig.mistralApiKey, isEmpty);
    expect(AppConfig.revenueCatAndroidApiKey, isEmpty);
    expect(AppConfig.revenueCatIosApiKey, isEmpty);
  });
}
