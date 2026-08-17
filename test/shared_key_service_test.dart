import 'package:flutter_test/flutter_test.dart';
import 'package:sift/core/config/shared_key_service.dart';

void main() {
  group('configError', () {
    // The failure this guards against is a quiet one: no key means every
    // shared-quota call returns nothing, which looks exactly like the model
    // having nothing to say. These pin the combinations so that silence can't
    // come back by accident.

    test('a fetched key is fine whether or not one was required', () {
      expect(
        SharedKeyService.configError(key: 'AIza-test', mustExist: true),
        isNull,
      );
      expect(
        SharedKeyService.configError(key: 'AIza-test', mustExist: false),
        isNull,
      );
    });

    test('no key is tolerated when the build does not require one', () {
      // Local dev and CI both run this way: Remote Config unreachable or
      // App Check unregistered, AI degrades to OCR and local tags on purpose.
      expect(SharedKeyService.configError(key: '', mustExist: false), isNull);
    });

    test('no key is an error when the build requires one', () {
      final error = SharedKeyService.configError(key: '', mustExist: true);
      expect(error, isNotNull);
      // This surfaces at launch, potentially far from whoever configured the
      // build, so the message has to name the parameter and both likely causes.
      expect(error, contains(SharedKeyService.kGeminiKeyParam));
      expect(error, contains('Remote Config'));
      expect(error, contains('App Check'));
    });
  });

  test('the parameter name matches what the Firebase Console expects', () {
    // A typo here reads as "no key configured" rather than an error, so it is
    // worth pinning literally.
    expect(SharedKeyService.kGeminiKeyParam, 'gemini_api_key');
  });

  test('defaults to unconfigured, so nothing is assumed before a fetch', () {
    expect(SharedKeyService.requireSharedKey, isFalse);
    expect(SharedKeyService.geminiApiKey, isEmpty);
    expect(SharedKeyService.isConfigured, isFalse);
  });

  test('isConfigured tracks the cached key', () {
    addTearDown(() => SharedKeyService.debugSetKey(''));

    SharedKeyService.debugSetKey('AIza-test');
    expect(SharedKeyService.isConfigured, isTrue);
    expect(SharedKeyService.geminiApiKey, 'AIza-test');

    SharedKeyService.debugSetKey('');
    expect(SharedKeyService.isConfigured, isFalse);
  });
}
