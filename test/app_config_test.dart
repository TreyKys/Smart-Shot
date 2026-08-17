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
    expect(AppConfig.geminiApiKey, isEmpty);
    expect(AppConfig.revenueCatAndroidApiKey, isEmpty);
    expect(AppConfig.revenueCatIosApiKey, isEmpty);
  });

  test('proxy URL defaults to empty, so an unconfigured build never guesses',
      () {
    // The shared Gemini key lives only in the Cloudflare Worker; the app
    // reaches it through this URL. Empty means "no proxy configured", which
    // LLMService treats as "skip the AI call" rather than falling back to
    // some baked-in default endpoint.
    expect(AppConfig.geminiProxyUrl, isEmpty);
  });

  group('aiConfigError', () {
    // The whole point of this seam: an unconfigured build used to be
    // indistinguishable from a working one that found nothing to tag. These
    // pin the four combinations so that silence can never come back by
    // accident.

    test('a configured proxy is fine whether or not it is required', () {
      expect(
        AppConfig.aiConfigError(
            proxyUrl: 'https://proxy.workers.dev', requireProxy: true),
        isNull,
      );
      expect(
        AppConfig.aiConfigError(
            proxyUrl: 'https://proxy.workers.dev', requireProxy: false),
        isNull,
      );
    });

    test('an empty proxy URL is tolerated when it is not required', () {
      // Local development and the emulator CI job both run this way — no
      // Worker deployed, AI degrades to OCR and local tags on purpose.
      expect(
        AppConfig.aiConfigError(proxyUrl: '', requireProxy: false),
        isNull,
      );
    });

    test('an empty proxy URL is an error when the build requires it', () {
      final error =
          AppConfig.aiConfigError(proxyUrl: '', requireProxy: true);
      expect(error, isNotNull);
      // The message has to name the missing define and the fix — this fires
      // at launch, potentially far from whoever configured the build.
      expect(error, contains('GEMINI_PROXY_URL'));
      expect(error, contains('dart_define'));
    });
  });

  test('assertAiConfigured passes on a default (proxy-optional) build', () {
    // REQUIRE_AI_PROXY is unset here, matching a plain `flutter test` run.
    expect(AppConfig.requireAiProxy, isFalse);
    expect(AppConfig.assertAiConfigured, returnsNormally);
  });

  test('isSharedAiConfigured tracks the proxy URL', () {
    expect(AppConfig.isSharedAiConfigured, AppConfig.geminiProxyUrl.isNotEmpty);
  });
}
