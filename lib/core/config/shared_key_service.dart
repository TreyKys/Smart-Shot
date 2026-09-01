import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';
import 'package:sift/core/diagnostics/diagnostic_log.dart';

/// Serves the shared Mistral AI API key, fetched from Firebase Remote Config
/// rather than compiled into the app.
///
/// The key is stored as a Remote Config parameter and delivered at runtime.
/// App Check enforcement is switched on for Remote Config in the Firebase
/// Console, so a build that can't attest — a repackaged APK, an emulator with
/// no registered debug token — gets nothing back and the shared path stays
/// off.
///
/// Worth being clear about what this does and doesn't buy: the key does reach
/// the device, so someone running an instrumented build can read it out of
/// memory. What it gives up in absolute secrecy against a determined attacker
/// it makes back in operational control — the key is never in the APK, never
/// in this repo, and can be rotated or revoked from the console without
/// shipping an update.
///
/// The Remote Config parameter name below (`mistral_api_key`) must be
/// created in the Firebase Console — third name this parameter has had
/// (`gemini_api_key` → `qwen_api_key` → this one) as the AI provider has
/// changed. Each switch needs the new parameter added fresh; the old ones
/// are just dead config, not automatically renamed.
class SharedKeyService {
  const SharedKeyService._();

  /// Remote Config parameter name. Must match the key in the Firebase Console
  /// exactly — a typo here reads as "no key configured" rather than an error.
  static const String kMistralKeyParam = 'mistral_api_key';

  /// Makes a missing key a hard failure instead of a silent no-op. Off by
  /// default so local and CI builds still run without Remote Config reachable;
  /// pass `--dart-define=REQUIRE_SHARED_AI_KEY=true` for release builds that
  /// must not ship with the shared quota quietly disabled.
  static const bool requireSharedKey =
      bool.fromEnvironment('REQUIRE_SHARED_AI_KEY');

  static String _cached = '';

  /// The fetched key, or empty when Remote Config had nothing for us.
  static String get apiKey => _cached;

  static bool get isConfigured => _cached.isNotEmpty;

  /// Describes a build that fetched no key but was told it must have one, or
  /// null when the combination is coherent.
  ///
  /// Pure over its inputs so the decision can be tested without standing up
  /// Firebase.
  static String? configError({
    required String key,
    required bool mustExist,
  }) {
    if (key.isNotEmpty || !mustExist) return null;
    return 'No "$kMistralKeyParam" came back from Remote Config but '
        'REQUIRE_SHARED_AI_KEY is set. This build would skip every shared-quota '
        'AI call. Check that the parameter is published in the Firebase '
        'Console and that App Check is not rejecting this build.';
  }

  /// Fetches and caches the key. Safe to call before Firebase is up — a
  /// failure leaves the key empty and the shared path simply stays off.
  ///
  /// Must run *after* App Check activation, so the fetch carries an attestation
  /// token; called that way from main().
  static Future<void> initialize() async {
    try {
      final remoteConfig = FirebaseRemoteConfig.instance;
      await remoteConfig.setConfigSettings(
        RemoteConfigSettings(
          fetchTimeout: const Duration(seconds: 10),
          // Startup shouldn't re-fetch on every launch, but a rotated key
          // should reach users the same day rather than whenever the app
          // happens to be reinstalled.
          minimumFetchInterval: const Duration(hours: 1),
        ),
      );
      await remoteConfig.setDefaults(const {kMistralKeyParam: ''});
      await remoteConfig.fetchAndActivate();
      _cached = remoteConfig.getString(kMistralKeyParam).trim();

      if (_cached.isEmpty) {
        debugPrint(
            'SharedKeyService: Remote Config returned no "$kMistralKeyParam" '
            '— shared AI is off (BYOK still works).');
        DiagnosticLog.warn(
            'SharedKeyService: Remote Config returned no shared key. Shared '
            'AI is off — either the parameter isn\'t published, or App Check '
            'rejected this build. Add your own key in Settings (BYOK) to '
            'keep AI tagging working.');
      } else {
        DiagnosticLog.info(
            'SharedKeyService: shared key fetched from Remote Config '
            '(${_cached.length} chars) — shared AI is on.');
      }
    } catch (e) {
      // Offline launches land here, which must not block startup.
      debugPrint('SharedKeyService: Remote Config fetch failed: $e');
      DiagnosticLog.error('SharedKeyService: Remote Config fetch failed: $e');
    }

    final error = configError(key: _cached, mustExist: requireSharedKey);
    if (error != null) throw StateError(error);
  }

  @visibleForTesting
  static void debugSetKey(String value) => _cached = value;
}
