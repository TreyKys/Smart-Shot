import 'dart:io';
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
      final RecognizedText recognizedText = await _textRecognizer.processImage(inputImage);
      return recognizedText.text;
    } catch (e) {
      return "";
    }
  }

  void dispose() {
    _textRecognizer.close();
  }
}
