import 'package:flutter_test/flutter_test.dart';
import 'package:sift/features/gallery/services/dedup_service.dart';

// The hash comparison runs once per stored hash per ingested image, so it was
// rewritten from bit-string comparison to packed-int XOR + popcount. These pin
// the behaviour so the fast path stays equivalent to the obvious slow one.
void main() {
  // Reference implementation: the original bit-string walk.
  int slowHamming(String a, String b) {
    String toBits(String hex) => hex
        .split('')
        .map((c) => int.parse(c, radix: 16).toRadixString(2).padLeft(4, '0'))
        .join();
    final bitsA = toBits(a);
    final bitsB = toBits(b);
    var d = 0;
    for (var i = 0; i < bitsA.length; i++) {
      if (bitsA[i] != bitsB[i]) d++;
    }
    return d;
  }

  group('pack', () {
    test('splits a 64-bit hex hash into two 32-bit halves', () {
      expect(DedupService.pack('00000000ffffffff'), [0, 0xffffffff]);
      expect(DedupService.pack('ffffffff00000000'), [0xffffffff, 0]);
    });

    test('rejects malformed input instead of throwing', () {
      expect(DedupService.pack('abc'), isNull);
      expect(DedupService.pack(''), isNull);
      expect(DedupService.pack('zzzzzzzzzzzzzzzz'), isNull);
    });
  });

  group('areDuplicates', () {
    test('identical hashes are duplicates', () {
      expect(DedupService.areDuplicates('a1b2c3d4e5f60718', 'a1b2c3d4e5f60718'),
          isTrue);
    });

    test('all-bits-different hashes are not duplicates', () {
      expect(DedupService.areDuplicates('0000000000000000', 'ffffffffffffffff'),
          isFalse);
    });

    test('honours the threshold boundary', () {
      // 0x1 flips one bit; four flipped bits is still under the threshold of 5.
      expect(DedupService.areDuplicates('0000000000000000', '0000000000000001'),
          isTrue);
      expect(DedupService.areDuplicates('0000000000000000', '000000000000000f'),
          isTrue);
      // Five flipped bits reaches the threshold and is no longer a duplicate.
      expect(DedupService.areDuplicates('0000000000000000', '000000000000001f'),
          isFalse);
    });

    test('malformed input is never a duplicate', () {
      expect(DedupService.areDuplicates('abc', 'a1b2c3d4e5f60718'), isFalse);
    });

    test('matches the reference implementation across sample pairs', () {
      const samples = [
        '0000000000000000',
        'ffffffffffffffff',
        'a1b2c3d4e5f60718',
        '123456789abcdef0',
        'fedcba9876543210',
        '8000000000000001',
        '0f0f0f0f0f0f0f0f',
      ];
      for (final a in samples) {
        for (final b in samples) {
          expect(
            DedupService.areDuplicates(a, b),
            slowHamming(a, b) < 5,
            reason: 'mismatch for $a vs $b',
          );
        }
      }
    });
  });
}
