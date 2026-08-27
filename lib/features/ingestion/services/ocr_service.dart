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

/// How a screenshot should be sent to the model.
///
/// The cost of a vision call is dominated by image tokens — a screenshot at
/// this size is easily several times the ~100–500 tokens its OCR text would
/// cost instead. So the useful question is not "AI or not" but "does this
/// image carry signal the text doesn't". Text-dominant screenshots (receipts, chats, articles,
/// code) lose nothing by being sent as text. Image-dominant ones — memes,
/// photos, charts, which are exactly the cases OCR handles badly — need the
/// pixels.
enum AnalysisRoute {
  /// OCR text alone, no image. Cheap, fast, and batchable.
  textOnly,

  /// Image only — OCR found too little to be worth sending.
  vision,

  /// Image plus OCR text. The safe default when the signal is ambiguous.
  dual,
}

/// OCR output plus the structural signal ML Kit already computes.
///
/// The previous implementation returned only [text] and discarded the block
/// and line geometry, which is the cheapest available evidence for whether a
/// screenshot is a document or a picture with a caption.
@immutable
class OcrResult {
  final String text;

  /// Number of distinct text blocks ML Kit found.
  final int blockCount;

  /// Total lines across all blocks.
  final int lineCount;

  const OcrResult({
    required this.text,
    required this.blockCount,
    required this.lineCount,
  });

  static const empty = OcrResult(text: '', blockCount: 0, lineCount: 0);

  int get charCount => text.trim().length;

  /// Below this, OCR effectively found nothing — send the image.
  static const int _kMinChars = 40;

  /// Above these, the screenshot is confidently document-like.
  static const int _kStrongChars = 220;
  static const int _kStrongBlocks = 5;

  /// Chooses how this screenshot should be analysed.
  ///
  /// Deliberately conservative: [AnalysisRoute.textOnly] requires *both* a lot
  /// of text and many separate blocks, because a meme with a long caption has
  /// the former but not the latter, and dropping its image would misclassify
  /// it. Everything that isn't clearly one case or the other falls through to
  /// [AnalysisRoute.dual], which is exactly the behaviour that shipped before
  /// routing existed — so the accuracy floor is unchanged.
  AnalysisRoute get route {
    if (charCount < _kMinChars) return AnalysisRoute.vision;
    if (charCount >= _kStrongChars && blockCount >= _kStrongBlocks) {
      return AnalysisRoute.textOnly;
    }
    return AnalysisRoute.dual;
  }
}

class OcrService {
  final TextRecognizer _textRecognizer =
      TextRecognizer(script: TextRecognitionScript.latin);

  Future<OcrResult> processImage(File imageFile) async {
    final InputImage inputImage = InputImage.fromFile(imageFile);
    try {
      final RecognizedText recognized =
          await _textRecognizer.processImage(inputImage);

      var lines = 0;
      for (final block in recognized.blocks) {
        lines += block.lines.length;
      }

      final result = OcrResult(
        text: recognized.text,
        blockCount: recognized.blocks.length,
        lineCount: lines,
      );
      debugPrint(
          'OCR: ${result.charCount} chars, ${result.blockCount} blocks, '
          'route=${result.route.name} — ${imageFile.path}');
      return result;
    } catch (e) {
      debugPrint('OCR error for ${imageFile.path}: $e');
      return OcrResult.empty;
    }
  }

  void dispose() {
    _textRecognizer.close();
  }
}
