import 'package:flutter/foundation.dart';

/// Build-time secrets and IDs, supplied via `--dart-define-from-file` (see
/// dart_define.example.json). Nothing here ships as a readable asset inside
/// the compiled app the way a bundled `.env` file would.
class AppConfig {
  const AppConfig._();

  static const String geminiApiKey = String.fromEnvironment('GEMINI_API_KEY');

  static const String revenueCatAndroidApiKey =
      String.fromEnvironment('REVENUECAT_ANDROID_API_KEY');
  static const String revenueCatIosApiKey =
      String.fromEnvironment('REVENUECAT_IOS_API_KEY');

  static const String _rewardedAdUnitId =
      String.fromEnvironment('ADMOB_REWARDED_AD_UNIT_ID');

  /// Google's public test rewarded ad unit ID. Always used outside release
  /// builds so local development never serves real ads.
  static const String _testRewardedAdUnitId =
      'ca-app-pub-3940256099942544/5224354917';

  static String get rewardedAdUnitId {
    if (!kReleaseMode || _rewardedAdUnitId.isEmpty) {
      return _testRewardedAdUnitId;
    }
    return _rewardedAdUnitId;
  }
}
