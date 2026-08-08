import 'package:flutter_test/flutter_test.dart';
import 'package:sift/features/ingestion/services/ocr_service.dart';

// Routing decides whether a screenshot's image is worth uploading. Getting it
// wrong in the textOnly direction silently costs accuracy, so these pin the
// boundaries — especially that a caption-style result never routes textOnly.
OcrResult result(int chars, int blocks) => OcrResult(
      text: 'x' * chars,
      blockCount: blocks,
      lineCount: blocks,
    );

void main() {
  test('almost no text means the image carries the signal', () {
    expect(result(0, 0).route, AnalysisRoute.vision);
    expect(result(10, 1).route, AnalysisRoute.vision);
    expect(result(39, 2).route, AnalysisRoute.vision);
  });

  test('lots of text across many blocks is document-like', () {
    expect(result(220, 5).route, AnalysisRoute.textOnly);
    expect(result(5000, 40).route, AnalysisRoute.textOnly);
  });

  test('a long caption in few blocks still needs the image', () {
    // This is the meme case: plenty of characters, but one or two blocks.
    // Routing it textOnly would classify the caption's subject and miss that
    // the screenshot is a meme.
    expect(result(400, 1).route, AnalysisRoute.dual);
    expect(result(400, 4).route, AnalysisRoute.dual);
  });

  test('moderate text falls back to the pre-routing behaviour', () {
    expect(result(120, 8).route, AnalysisRoute.dual);
    expect(result(219, 6).route, AnalysisRoute.dual);
  });

  test('empty result is well formed', () {
    expect(OcrResult.empty.charCount, 0);
    expect(OcrResult.empty.route, AnalysisRoute.vision);
  });

  test('charCount ignores surrounding whitespace', () {
    expect(const OcrResult(text: '  hi  ', blockCount: 1, lineCount: 1).charCount, 2);
  });
}
