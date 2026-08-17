import 'package:flutter/foundation.dart';

/// Build-time secrets and IDs, supplied via `--dart-define-from-file` (see
/// dart_define.example.json). Nothing here ships as a readable asset inside
/// the compiled app the way a bundled `.env` file would.
class AppConfig {
  const AppConfig._();

  /// Only used for the BYOK (bring-your-own-key) path, where the user
  /// supplies their own Gemini key in Settings — their key, their cost, their
  /// risk to accept. The app's own shared quota no longer uses a client-side
  /// key at all: see [geminiProxyUrl].
  static const String geminiApiKey = String.fromEnvironment('GEMINI_API_KEY');

  /// URL of the Cloudflare Worker (server/gemini-proxy/) that fronts Gemini
  /// for the shared/free-tier quota. The real Gemini key lives only as a
  /// Worker secret — never compiled into this app. Requests are authorized
  /// with a Firebase App Check token instead of an embedded API key, so
  /// there's nothing here for `strings` on the APK or a MITM proxy to find.
  static const String geminiProxyUrl =
      String.fromEnvironment('GEMINI_PROXY_URL');

  /// Turns an unconfigured shared-AI path from a silent no-op into a hard
  /// failure. Off by default so local/CI debug builds still run without a
  /// deployed Worker; pass `--dart-define=REQUIRE_AI_PROXY=true` for release
  /// builds and any job that must not ship AI silently disabled.
  static const bool requireAiProxy =
      bool.fromEnvironment('REQUIRE_AI_PROXY');

  /// Whether the shared (non-BYOK) AI path has anywhere to go at all.
  static bool get isSharedAiConfigured => geminiProxyUrl.isNotEmpty;

  /// Describes a build whose AI path would silently do nothing, or null when
  /// the build is coherent.
  ///
  /// Kept as a pure function over its inputs rather than reading the consts
  /// directly, because [geminiProxyUrl] is a compile-time `String.fromEnvironment`
  /// — a test can't vary it, so the decision logic has to be reachable
  /// without it.
  static String? aiConfigError({
    required String proxyUrl,
    required bool requireProxy,
  }) {
    if (proxyUrl.isNotEmpty || !requireProxy) return null;
    return 'GEMINI_PROXY_URL is empty but REQUIRE_AI_PROXY is set. This build '
        'would silently skip every AI analysis call. Deploy '
        'server/gemini-proxy/ and pass --dart-define-from-file=dart_define.json '
        '(see dart_define.example.json).';
  }

  /// Throws when the build is configured to require the proxy but has no URL.
  ///
  /// Called at startup so a build that must have AI fails at launch, where
  /// it's obvious, instead of degrading to local-tags-only and looking like
  /// the model simply found nothing.
  static void assertAiConfigured() {
    final error = aiConfigError(
      proxyUrl: geminiProxyUrl,
      requireProxy: requireAiProxy,
    );
    if (error != null) throw StateError(error);
  }

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
