import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'package:sift/features/gallery/data/gallery_repository.dart';
import 'package:sift/features/gallery/presentation/gallery_screen.dart';
import 'package:sift/features/gallery/services/background_service.dart';
import 'package:sift/core/theme/theme_provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:workmanager/workmanager.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sift/features/onboarding/onboarding_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await MobileAds.instance.initialize();
  await dotenv.load(fileName: ".env");
  Workmanager().initialize(callbackDispatcher);

  final prefs = await SharedPreferences.getInstance();
  final hasSeenOnboarding = prefs.getBool('has_seen_onboarding') ?? false;

  runApp(ProviderScope(child: SmartShotApp(hasSeenOnboarding: hasSeenOnboarding)));
}

class SmartShotApp extends ConsumerStatefulWidget {
  final bool hasSeenOnboarding;
  const SmartShotApp({super.key, this.hasSeenOnboarding = false});

  @override
  ConsumerState<SmartShotApp> createState() => _SmartShotAppState();
}

class _SmartShotAppState extends ConsumerState<SmartShotApp> {
  late StreamSubscription _intentDataStreamSubscription;

  @override
  void initState() {
    super.initState();
    _intentDataStreamSubscription = ReceiveSharingIntent.instance.getMediaStream().listen((List<SharedMediaFile> value) {
        _handleSharedFiles(value);
    }, onError: (err) {
      debugPrint("getIntentDataStream error: $err");
    });

    ReceiveSharingIntent.instance.getInitialMedia().then((List<SharedMediaFile> value) {
        _handleSharedFiles(value);
    });
  }

  void _handleSharedFiles(List<SharedMediaFile> files) {
    if (files.isEmpty) return;
    debugPrint("Shared files received: ${files.length}");

    final galleryRepo = ref.read(galleryRepositoryProvider);
    for (final file in files) {
      // Ingest into gallery
      galleryRepo.addFile(File(file.path));
    }
  }

  @override
  void dispose() {
    _intentDataStreamSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeNotifierProvider);

    return MaterialApp(
      title: 'Sift',
      themeMode: themeMode,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple, brightness: Brightness.light),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple, brightness: Brightness.dark),
        useMaterial3: true,
      ),
      home: widget.hasSeenOnboarding ? const GalleryScreen() : const OnboardingScreen(),
    );
  }
}
