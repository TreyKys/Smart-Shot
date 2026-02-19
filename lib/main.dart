import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'package:smart_shot/features/gallery/presentation/gallery_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
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
    // Future expansion: Ingest these files into the gallery/OCR pipeline.
  }

  @override
  void dispose() {
    _intentDataStreamSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SmartShot',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const GalleryScreen(),
    );
  }
}
