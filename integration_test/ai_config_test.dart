// Guards the shared AI path against failing quietly.
//
// Before this, an app built with no GEMINI_PROXY_URL behaved exactly like one
// whose model had nothing to say: LLMService logged a line to debugPrint and
// returned {}, the gallery filled in OCR and local tags, and every test
// passed. The emulator CI job was in precisely that state — green, with AI
// entirely inert. These tests make the two cases distinguishable and assert
// whichever one the build actually claims to be in.
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:integration_test/integration_test.dart';
import 'package:sift/core/config/app_config.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  test('the build never both requires the proxy and lacks a URL', () {
    // Mirrors the startup check in main(). Running it here too means the
    // contradiction is reported as a named test failure rather than as a
    // StateError thrown from inside app startup, where it reads like a crash.
    expect(
      AppConfig.aiConfigError(
        proxyUrl: AppConfig.geminiProxyUrl,
        requireProxy: AppConfig.requireAiProxy,
      ),
      isNull,
      reason: 'This build sets REQUIRE_AI_PROXY but has no GEMINI_PROXY_URL, '
          'so every AI call would silently return nothing.',
    );
  });

  test('an unconfigured build is explicitly disabled, not ambiguously quiet',
      () {
    if (AppConfig.isSharedAiConfigured) {
      markTestSkipped('Proxy is configured; reachability test covers it.');
      return;
    }
    // Asserting the negative on purpose: this is the state CI runs in, and
    // the value of pinning it is that setting GEMINI_PROXY_URL flips which of
    // these two tests does the real work. Whichever one stands down says so
    // via markTestSkipped, so neither can go quiet without it showing up in
    // the run output.
    expect(AppConfig.geminiProxyUrl, isEmpty);
    expect(AppConfig.isSharedAiConfigured, isFalse,
        reason: 'No proxy URL, so the shared AI path is off. Analysis falls '
            'back to OCR and local tags by design — deploy '
            'server/gemini-proxy/ and set GEMINI_PROXY_URL to enable it.');
  });

  test('a configured proxy is reachable and rejects unauthenticated calls',
      () async {
    if (!AppConfig.isSharedAiConfigured) {
      markTestSkipped('No GEMINI_PROXY_URL; nothing deployed to probe yet.');
      return;
    }

    // Deliberately sent with no App Check token. Two things are checked at
    // once: that the URL resolves and answers at all (a typo'd or undeployed
    // Worker fails here), and that it refuses to reach Gemini without
    // attestation. A 200 would mean the shared key is reachable by anyone who
    // reads the URL out of the APK.
    final response = await http.post(
      Uri.parse(AppConfig.geminiProxyUrl),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({
        'contents': [
          {
            'parts': [
              {'text': 'ping'}
            ]
          }
        ]
      }),
    );

    expect(
      response.statusCode,
      401,
      reason: 'Unauthenticated request to ${AppConfig.geminiProxyUrl} '
          'returned ${response.statusCode}, expected 401. If this is 200 the '
          'proxy is forwarding to Gemini without verifying App Check — stop '
          'and fix the Worker before shipping.',
    );
  }, timeout: const Timeout(Duration(seconds: 30)));
}
