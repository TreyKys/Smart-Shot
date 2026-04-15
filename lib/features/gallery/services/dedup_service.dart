import 'dart:io';
import 'dart:typed_data';
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

  /// Returns true if two hash strings are perceptually similar (duplicates).
  static bool areDuplicates(String hashA, String hashB) {
    if (hashA.length != hashB.length) return false;
    return _hammingDistance(hashA, hashB) < _hammingThreshold;
  }

  static int _hammingDistance(String a, String b) {
    int distance = 0;
    final bitsA = _hexToBits(a);
    final bitsB = _hexToBits(b);
    for (int i = 0; i < bitsA.length; i++) {
      if (bitsA[i] != bitsB[i]) distance++;
    }
    return distance;
  }

  static String _hexToBits(String hex) {
    return hex.split('').map((c) {
      final val = int.parse(c, radix: 16);
      return val.toRadixString(2).padLeft(4, '0');
    }).join();
  }
}
