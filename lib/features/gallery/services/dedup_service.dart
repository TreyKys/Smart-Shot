import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

/// Perceptual hashing (dHash) for near-duplicate screenshot detection.
/// A 64-bit fingerprint is computed from a 9×8 grayscale thumbnail.
/// Two images with Hamming distance < 5 are considered duplicates.
class DedupService {
  static const int _hammingThreshold = 5;

  /// Compute dHash for a given file path. Designed to run inside compute().
  static Future<String?> computeHash(String filePath) async {
    try {
      final bytes = await File(filePath).readAsBytes();
      return _computeHashFromBytes(bytes);
    } catch (e) {
      debugPrint('DedupService: hash error for $filePath: $e');
      return null;
    }
  }

  /// Entry point for compute() isolate — takes filePath string, returns hash string or null.
  static Future<String?> hashIsolateEntry(String filePath) => computeHash(filePath);

  static String? _computeHashFromBytes(Uint8List bytes) {
    final decoded = img.decodeImage(bytes);
    if (decoded == null) return null;

    // Resize to 9×8 for dHash (9 wide gives 8 horizontal comparisons per row)
    final small = img.copyResize(decoded, width: 9, height: 8,
        interpolation: img.Interpolation.average);

    // Convert to grayscale and compute left-to-right gradient differences
    final bits = StringBuffer();
    for (int y = 0; y < 8; y++) {
      for (int x = 0; x < 8; x++) {
        final left = img.getLuminance(small.getPixel(x, y));
        final right = img.getLuminance(small.getPixel(x + 1, y));
        bits.write(left < right ? '1' : '0');
      }
    }

    // Convert 64-bit binary string to hex for compact storage
    final bitStr = bits.toString();
    final buffer = StringBuffer();
    for (int i = 0; i < 64; i += 4) {
      final nibble = int.parse(bitStr.substring(i, i + 4), radix: 2);
      buffer.write(nibble.toRadixString(16));
    }
    return buffer.toString(); // 16 hex chars = 64 bits
  }

  /// Packs a 16-char hex dHash into two 32-bit ints.
  ///
  /// Comparisons happen O(n) times per ingested image, so hashes are parsed
  /// once here rather than re-parsed inside every distance check. Split into
  /// two halves because a full 64-bit hash doesn't fit in a positive Dart int.
  /// Returns null for malformed input.
  static List<int>? pack(String hex) {
    if (hex.length != 16) return null;
    try {
      return [
        int.parse(hex.substring(0, 8), radix: 16),
        int.parse(hex.substring(8, 16), radix: 16),
      ];
    } catch (_) {
      return null;
    }
  }

  /// Returns true if two packed hashes are perceptually similar.
  static bool areDuplicatesPacked(List<int> a, List<int> b) {
    final distance =
        _popcount32(a[0] ^ b[0]) + _popcount32(a[1] ^ b[1]);
    return distance < _hammingThreshold;
  }

  /// Returns true if two hash strings are perceptually similar (duplicates).
  static bool areDuplicates(String hashA, String hashB) {
    final a = pack(hashA);
    final b = pack(hashB);
    if (a == null || b == null) return false;
    return areDuplicatesPacked(a, b);
  }

  /// SWAR population count over a 32-bit value.
  static int _popcount32(int v) {
    v -= (v >> 1) & 0x55555555;
    v = (v & 0x33333333) + ((v >> 2) & 0x33333333);
    v = (v + (v >> 4)) & 0x0F0F0F0F;
    return ((v * 0x01010101) >> 24) & 0xFF;
  }
}
