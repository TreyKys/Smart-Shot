import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'ocr_service.g.dart';

@Riverpod(keepAlive: true)
OcrService ocrService(OcrServiceRef ref) {
  final service = OcrService();
  ref.onDispose(service.dispose);
  return service;
}

class OcrService {
  final TextRecognizer _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

  Future<String> processImage(File imageFile) async {
    final InputImage inputImage = InputImage.fromFile(imageFile);
    try {
      debugPrint("Processing image for OCR: ${imageFile.path}");
      final RecognizedText recognizedText = await _textRecognizer.processImage(inputImage);
      debugPrint("OCR completed. Text length: ${recognizedText.text.length}");
      return recognizedText.text;
    } catch (e) {
      debugPrint("Error processing image: $e");
      return "";
    }
  }

  void dispose() {
    _textRecognizer.close();
  }
}
