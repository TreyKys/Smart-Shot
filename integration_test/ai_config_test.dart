// Guards the shared AI path against failing quietly.
//
// An app that can't get a key behaves exactly like one whose model found
// nothing to say: LLMService logs a line to debugPrint and returns {}, the
// gallery fills in OCR and local tags, and every test passes. The emulator CI
// job was in precisely that state — green, with AI entirely inert. These make
// the two cases distinguishable and assert whichever one is real.
//
// Unlike the unit tests, this runs the actual Remote Config fetch against a
// real device, so it also catches a project where the parameter was never
// published or App Check is rejecting the build.
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:sift/core/config/shared_key_service.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    try {
      await Firebase.initializeApp();
      await SharedKeyService.initialize();
    } catch (e) {
      // initialize() only throws when REQUIRE_SHARED_AI_KEY is set and no key
      // came back — the first test below reports that as a named failure
      // rather than letting it abort the whole suite from setUpAll.
      debugPrintSynchronously('SharedKeyService.initialize threw: $e');
    }
  });

  test('the build never both requires a shared key and lacks one', () {
    expect(
      SharedKeyService.configError(
        key: SharedKeyService.geminiApiKey,
        mustExist: SharedKeyService.requireSharedKey,
      ),
      isNull,
      reason: 'This build sets REQUIRE_SHARED_AI_KEY but Remote Config '
          'returned no key, so every shared-quota call would silently return '
          'nothing.',
    );
  });

  test('an unconfigured build is explicitly disabled, not ambiguously quiet',
      () {
    if (SharedKeyService.isConfigured) {
      markTestSkipped('Shared key present; the configured test covers it.');
      return;
    }
    // Asserting the negative on purpose: this is the state CI runs in, and
    // pinning it means publishing the parameter flips which of these two tests
    // does the real work. Whichever stands down says so via markTestSkipped,
    // so neither can go quiet without it showing in the run output.
    expect(SharedKeyService.geminiApiKey, isEmpty);
    expect(SharedKeyService.isConfigured, isFalse,
        reason: 'No shared key, so the shared AI path is off. Analysis falls '
            'back to OCR and local tags by design — publish '
            '"${SharedKeyService.kGeminiKeyParam}" in Remote Config and '
            'register an App Check debug token to enable it.');
  });

  test('a fetched key looks like a real Gemini key', () {
    if (!SharedKeyService.isConfigured) {
      markTestSkipped('No shared key fetched; nothing to validate yet.');
      return;
    }
    final key = SharedKeyService.geminiApiKey;
    // Catches the two ways this goes wrong in practice: a placeholder left in
    // the console, or a value that arrived with whitespace or quotes around it
    // from a copy-paste. Both would fail at call time with an opaque 400.
    expect(key, startsWith('AIza'),
        reason: 'Remote Config returned "$key", which is not a Google API '
            'key. Check the parameter value in the Firebase Console.');
    expect(key, equals(key.trim()));
    expect(key.length, greaterThan(30));
  });
}
