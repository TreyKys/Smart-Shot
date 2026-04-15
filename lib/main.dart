import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:workmanager/workmanager.dart';
import 'package:sift/core/theme/app_theme.dart';
import 'package:sift/features/gallery/data/gallery_repository.dart';
import 'package:sift/features/gallery/presentation/gallery_screen.dart';
import 'package:sift/features/gallery/services/background_service.dart';
import 'package:sift/features/onboarding/onboarding_screen.dart';
import 'package:sift/features/economy/economy_service.dart';
import 'package:sift/services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load env first (API keys needed by everything)
  await dotenv.load(fileName: '.env');

  // AdMob
  await MobileAds.instance.initialize();

  // Background tasks
  Workmanager().initialize(callbackDispatcher);

  // Notifications
  await NotificationService.instance.init();

  runApp(const ProviderScope(child: SiftApp()));
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

    return MaterialApp(
      title: 'Sift',
      debugShowCheckedModeBanner: false,
      theme: buildSiftTheme(),
      // Always dark — system utility aesthetic
      themeMode: ThemeMode.dark,
      darkTheme: buildSiftTheme(),
      home: _onboardingComplete
          ? const GalleryScreen()
          : const OnboardingScreen(),
    );
  }
}
