import 'package:flutter_test/flutter_test.dart';
import 'package:sift/features/ingestion/domain/tag_vocabulary.dart';

void main() {
  group('canonical', () {
    test('accepts vocabulary tags and fixes casing', () {
      expect(TagVocabulary.canonical('#Finance'), '#Finance');
      expect(TagVocabulary.canonical('#finance'), '#Finance');
      expect(TagVocabulary.canonical('#FINANCE'), '#Finance');
    });

    test('adds a missing hash', () {
      expect(TagVocabulary.canonical('Finance'), '#Finance');
    });

    test('folds the near-duplicates the old prompt shipped', () {
      // The previous guidance list contained both of these as separate tags.
      expect(TagVocabulary.canonical('#Receipt'), '#Receipts');
      expect(TagVocabulary.canonical('#Invoice'), '#Receipts');
      // Four overlapping crypto tags collapse to one filter.
      expect(TagVocabulary.canonical('#Crypto'), '#Web3');
      expect(TagVocabulary.canonical('#NFT'), '#Web3');
      expect(TagVocabulary.canonical('#DeFi'), '#Web3');
    });

    test('maps the banned blank-image variants onto Junk', () {
      for (final t in ['#BlankImage', '#Empty', '#NoContent', '#Unknown']) {
        expect(TagVocabulary.canonical(t), '#Junk', reason: t);
      }
    });

    test('drops tags that carry no information', () {
      // Every image in this app is a screenshot.
      expect(TagVocabulary.canonical('#Screenshot'), '');
    });

    test('drops invented tags rather than passing them through', () {
      expect(TagVocabulary.canonical('#ArtisanalSourdough'), '');
      expect(TagVocabulary.canonical(''), '');
      expect(TagVocabulary.canonical('   '), '');
    });
  });

  group('canonicalize', () {
    test('deduplicates after mapping and preserves order', () {
      expect(
        TagVocabulary.canonicalize(['#Crypto', '#NFT', '#Finance']),
        ['#Web3', '#Finance'],
      );
    });

    test('drops unmappable entries without failing the rest', () {
      expect(
        TagVocabulary.canonicalize(['#Nonsense', '#Food', '#Screenshot']),
        ['#Food'],
      );
    });

    test('empty in, empty out', () {
      expect(TagVocabulary.canonicalize(const []), isEmpty);
    });
  });

  test('bareNames strips the hash for schema enums', () {
    expect(TagVocabulary.bareNames, isNot(contains(startsWith('#'))));
    expect(TagVocabulary.bareNames.length, TagVocabulary.tags.length);
    expect(TagVocabulary.bareNames, contains('Finance'));
  });

  test('every vocabulary tag survives a canonical round trip', () {
    for (final t in TagVocabulary.tags) {
      expect(TagVocabulary.canonical(t), t, reason: t);
    }
  });
}
