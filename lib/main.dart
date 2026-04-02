import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'package:smart_shot/features/gallery/data/gallery_repository.dart';
import 'package:smart_shot/features/gallery/presentation/gallery_screen.dart';
import 'package:smart_shot/core/theme/theme_provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  runApp(const ProviderScope(child: SmartShotApp()));
}

class SmartShotApp extends ConsumerStatefulWidget {
  const SmartShotApp({super.key});

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
      title: 'SmartShot',
      themeMode: themeMode,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple, brightness: Brightness.light),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple, brightness: Brightness.dark),
        useMaterial3: true,
      ),
      home: const GalleryScreen(),
    );
  }
}
