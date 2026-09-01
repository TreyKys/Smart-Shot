import 'dart:async';
import 'dart:io';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';
import 'package:sift/core/config/shared_key_service.dart';
import 'package:sift/core/theme/app_theme.dart';
import 'package:sift/core/theme/theme_provider.dart';
import 'package:sift/features/gallery/data/gallery_repository.dart';
import 'package:sift/features/gallery/presentation/gallery_screen.dart';
import 'package:sift/features/gallery/services/background_service.dart';
import 'package:sift/features/monetization/consent_service.dart';
import 'package:sift/features/onboarding/onboarding_screen.dart';
import 'package:sift/features/economy/economy_service.dart';
import 'package:sift/services/notification_service.dart';

// Set once Firebase is up. Guards every reporting call, so a failed init
// degrades to debugPrint instead of throwing from inside an error handler.
var _crashlyticsReady = false;

Future<void> main() async {
  await runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    // No explicit options: on Android the google-services Gradle plugin bakes
    // android/app/google-services.json into the native config, which
    // initializeApp() reads. Run `flutterfire configure` to generate
    // firebase_options.dart if/when iOS is added to the Firebase project.
    try {
      await Firebase.initializeApp();
      // Debug-run crashes are noise in the dashboard — only report from
      // release/profile builds.
      await FirebaseCrashlytics.instance
          .setCrashlyticsCollectionEnabled(!kDebugMode);
      _crashlyticsReady = true;
    } catch (e, st) {
      debugPrint('Firebase init failed: $e\n$st');
    }

    try {
      // Play Integrity attests to Google that this is a real, unmodified
      // build of the app — that's what Remote Config checks before handing
      // over the shared Mistral key. The debug provider replaces that with a
      // token registered manually in Firebase Console, since Play Integrity
      // attestation isn't available for local/CI debug builds.
      await FirebaseAppCheck.instance.activate(
        providerAndroid: kDebugMode
            ? const AndroidDebugProvider()
            : const AndroidPlayIntegrityProvider(),
      );
    } catch (e, st) {
      debugPrint('App Check init failed: $e\n$st');
    }

    // After App Check, so the fetch carries an attestation token — that's what
    // lets Remote Config refuse to hand the shared key to a repackaged build.
    // Throws only when REQUIRE_SHARED_AI_KEY is set and no key came back, so
    // this is a no-op for local and CI debug runs.
    await SharedKeyService.initialize();

    FlutterError.onError = (details) {
      FlutterError.presentError(details);
      debugPrint('FlutterError: ${details.exceptionAsString()}');
      if (_crashlyticsReady) {
        FirebaseCrashlytics.instance.recordFlutterError(details);
      }
    };

    // Errors thrown outside the Flutter framework (platform channels, async
    // gaps the zone below doesn't cover).
    PlatformDispatcher.instance.onError = (error, stack) {
      debugPrint('PlatformDispatcher error: $error\n$stack');
      if (_crashlyticsReady) {
        FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      }
      return true;
    };

    // Each startup step is isolated: a single SDK failing to initialize
    // (ads, notifications, background tasks) must not blank the whole app.
    try {
      // Runs the GDPR/UK consent flow (where applicable) before ads init.
      await ConsentService.instance.requestConsentAndInitAds();
    } catch (e, st) {
      debugPrint('Ads/consent init failed: $e\n$st');
    }

    try {
      // Was previously fire-and-forget: initialize() returns a real Future
      // backed by a platform-channel round trip to native WorkManager setup,
      // not a Future that resolves immediately. Without this await, runApp()
      // — and therefore the onboarding screen, which can call
      // scheduleBackgroundSync() as soon as its first dialog is tapped — could
      // render before native init actually finished, so registerPeriodicTask
      // hit "WorkManager Package... not properly initialized" on a fast tap.
      // Exactly this race is what an integration test caught once Live Mode
      // started calling scheduleBackgroundSync() too.
      await Workmanager().initialize(callbackDispatcher);
    } catch (e, st) {
      debugPrint('Workmanager init failed: $e\n$st');
    }

    try {
      await NotificationService.instance.init();
    } catch (e, st) {
      debugPrint('NotificationService init failed: $e\n$st');
    }

    runApp(const ProviderScope(child: SiftApp()));
  }, (error, stack) {
    debugPrint('Uncaught error: $error\n$stack');
    if (_crashlyticsReady) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    }
  });
}

class SiftApp extends ConsumerStatefulWidget {
  const SiftApp({super.key});

  @override
  ConsumerState<SiftApp> createState() => _SiftAppState();
}

class _SiftAppState extends ConsumerState<SiftApp> {
  late StreamSubscription _intentSubscription;
  bool _onboardingComplete = false;
  bool _initDone = false;

  @override
  void initState() {
    super.initState();
    _init();

    _intentSubscription =
        ReceiveSharingIntent.instance.getMediaStream().listen(
      (List<SharedMediaFile> value) => _handleSharedFiles(value),
      onError: (err) => debugPrint('getIntentDataStream error: $err'),
    );

    ReceiveSharingIntent.instance
        .getInitialMedia()
        .then(_handleSharedFiles);
  }

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    _onboardingComplete = prefs.getBool('onboarding_complete') ?? false;

    // Pre-load rewarded ad after Riverpod is ready
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(economyServiceProvider.notifier).loadRewardedAd();
    });

    setState(() => _initDone = true);
  }

  void _handleSharedFiles(List<SharedMediaFile> files) {
    if (files.isEmpty) return;
    debugPrint('Shared files: ${files.length}');
    final galleryRepo = ref.read(galleryRepositoryProvider);
    for (final file in files) {
      galleryRepo.addFile(File(file.path));
    }
  }

  @override
  void dispose() {
    _intentSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_initDone) {
      return MaterialApp(
        theme: buildSiftTheme(),
        home: const Scaffold(
          backgroundColor: SiftColors.background,
          body: Center(
            child: CircularProgressIndicator(color: SiftColors.accent),
          ),
        ),
      );
    }

    final themeMode = ref.watch(themeModeNotifierProvider);

    return MaterialApp(
      title: 'Sift',
      debugShowCheckedModeBanner: false,
      theme: buildSiftLightTheme(),
      darkTheme: buildSiftTheme(),
      themeMode: themeMode,
      home: _onboardingComplete
          ? const GalleryScreen()
          : const OnboardingScreen(),
    );
  }
}
