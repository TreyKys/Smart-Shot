import 'package:flutter_test/flutter_test.dart';
import 'package:sift/features/gallery/data/gallery_repository.dart';

void main() {
  group('clusterDuplicateHashes', () {
    test('two hashes within the Hamming threshold form a cluster', () {
      // Last byte 0x00 vs 0x01 — 1 bit different, well under the threshold
      // of 5 DedupService.areDuplicatesPacked already enforces.
      final result = clusterDuplicateHashes({
        '/a.jpg': '0000000000000000',
        '/b.jpg': '0000000000000001',
      });
      expect(result, hasLength(1));
      expect(result.single, unorderedEquals(['/a.jpg', '/b.jpg']));
    });

    test('a hash with nothing else nearby forms no cluster (singletons are '
        'dropped, not returned as a group of one)', () {
      final result = clusterDuplicateHashes({
        '/a.jpg': '0000000000000000',
        '/lonely.jpg': 'ffffffffffffffff', // maximally different
      });
      expect(result, isEmpty);
    });

    test('transitive grouping: A-B close, B-C close, A-C far apart on their '
        'own still end up in the same cluster through B', () {
      // Last byte only: A=0x0f (00001111), B=0x00 (00000000), C=0xf0
      // (11110000). distance(A,B) = popcount(0x0f) = 4 (< 5, close).
      // distance(B,C) = popcount(0xf0) = 4 (< 5, close).
      // distance(A,C) = popcount(0xff) = 8 (>= 5, NOT close on their own) —
      // so A and C can only land in the same group if the union-find is
      // actually following the B connection transitively, not just
      // comparing every pair independently.
      final result = clusterDuplicateHashes({
        '/a.jpg': '000000000000000f',
        '/b.jpg': '0000000000000000',
        '/c.jpg': '00000000000000f0',
      });
      expect(result, hasLength(1));
      expect(result.single, unorderedEquals(['/a.jpg', '/b.jpg', '/c.jpg']));
    });

    test('two separate clusters stay separate', () {
      final result = clusterDuplicateHashes({
        '/a1.jpg': '0000000000000000',
        '/a2.jpg': '0000000000000001',
        '/b1.jpg': 'fffffffffffffffe',
        '/b2.jpg': 'ffffffffffffffff',
      });
      expect(result, hasLength(2));
      final asSets = result.map((g) => g.toSet()).toSet();
      expect(
        asSets,
        equals({
          {'/a1.jpg', '/a2.jpg'},
          {'/b1.jpg', '/b2.jpg'},
        }),
      );
    });

    test('a malformed hash is skipped rather than crashing or falsely '
        'matching everything', () {
      final result = clusterDuplicateHashes({
        '/a.jpg': '0000000000000000',
        '/b.jpg': '0000000000000001',
        '/bad.jpg': 'not-a-real-hash',
      });
      expect(result, hasLength(1));
      expect(result.single, unorderedEquals(['/a.jpg', '/b.jpg']));
    });

    test('an empty index produces no clusters', () {
      expect(clusterDuplicateHashes({}), isEmpty);
    });
  });
}
