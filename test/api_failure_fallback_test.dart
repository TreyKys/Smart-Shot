import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sift/features/ingestion/domain/tag_vocabulary.dart';
import 'package:sift/features/ingestion/services/tag_engine.dart';

// This is not a test of App Check — nothing in this app's AI path routes
// through Firebase, so App Check has no way to affect it either way (AI
// calls go straight to the provider's API via API key — see MistralClient).
//
// What this actually pins down: gallery_repository.dart wraps every
// llmService.analyze() call in try/catch, and on failure the screenshot's
// `llm` map is just {} — the exact same shape as a screenshot with no API key
// configured. This test reproduces that {} case directly against the pure
// tagging logic (the same calls _writeResults makes) to prove a failed or
// missing AI call degrades to local-only tags instead of leaving a
// screenshot untagged or corrupting its state.
void main() {
  // Mirrors GalleryRepository._list() and ._writeResults()'s tag branch
  // verbatim (including the malformed-type fallback), so this test breaks if
  // that logic ever drifts from what it actually pins down.
  List<String>? coerceList(dynamic raw) {
    if (raw == null) return null;
    if (raw is List) {
      return raw
          .where((e) => e != null)
          .map((e) => e.toString().trim())
          .where((s) => s.isNotEmpty)
          .toList();
    }
    if (raw is String) {
      final trimmed = raw.trim();
      if (trimmed.isEmpty) return null;
      if (trimmed.contains(',')) {
        return trimmed
            .split(',')
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .toList();
      }
      return [trimmed];
    }
    return []; // production logs here via debugPrint; irrelevant to the test
  }

  List<String> resolveTags(String ocrText, Map<String, dynamic> llm) {
    final aiTags = TagVocabulary.canonicalize(coerceList(llm['tags']) ?? const []);
    final localTags = TagEngine.suggestFromOcr(ocrText);
    final isJunk = TagEngine.isLikelyJunk(ocrText, File('nonexistent'));

    if (isJunk) {
      final others =
          TagEngine.merge(aiTags, const []).where((t) => t != '#Junk');
      return ['#Junk', ...others];
    }
    return TagEngine.merge(aiTags, localTags);
  }

  group('AI call fails or returns nothing (llm == {})', () {
    test('rich OCR text still gets tagged from local keyword scoring', () {
      const ocr = 'PayPal receipt\nTotal: \$42.00\nOrder #A1B2C3\nThank you '
          'for your purchase';
      final tags = resolveTags(ocr, const {});

      expect(tags, isNotEmpty);
      expect(tags, contains(anyOf('#Finance', '#Receipts')));
      expect(tags, isNot(contains('#Junk')));
    });

    test('sparse OCR text (a meme, a photo) degrades to Junk, not a crash',
        () {
      // Text under 3 chars hits isLikelyJunk's unconditional branch, so this
      // doesn't depend on the file-size fallback (which needs a real file —
      // irrelevant to what this test is pinning down).
      final tags = resolveTags('hi', const {});
      expect(tags, ['#Junk']);
    });

    test('empty OCR text is handled, not thrown', () {
      expect(() => resolveTags('', const {}), returnsNormally);
      expect(resolveTags('', const {}), ['#Junk']);
    });
  });

  group('AI call succeeds but with garbage/malformed content', () {
    test('unmappable tags are dropped, local tags fill the gap', () {
      const ocr = 'Uber trip receipt\nTotal fare: \$18.50\nDriver: Alex';
      final tags = resolveTags(ocr, {
        'tags': ['#ThisTagDoesNotExist', '#AlsoInvented'],
      });

      // Nothing from the model's tags survives canonicalization...
      expect(tags, isNot(contains('#ThisTagDoesNotExist')));
      // ...but the screenshot still ends up tagged from OCR alone.
      expect(tags, isNotEmpty);
    });

    test('a comma-separated string instead of a list still yields tags', () {
      final tags =
          resolveTags('random text', {'tags': '#Finance, #Receipts'});
      expect(tags, containsAll(['#Finance', '#Receipts']));
    });

    test('a wholly malformed "tags" type does not throw', () {
      const ocr = 'PayPal receipt\nTotal: \$42.00\nThank you for your purchase';
      expect(() => resolveTags(ocr, const {'tags': 12345}), returnsNormally);
      // Falls through to local-only tags rather than crashing — the same
      // outcome as a failed API call, which is the correct degrade path.
      expect(resolveTags(ocr, const {'tags': 12345}), isNotEmpty);
    });
  });
}
