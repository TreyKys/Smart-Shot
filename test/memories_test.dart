import 'package:flutter_test/flutter_test.dart';
import 'package:sift/features/gallery/domain/screenshot.dart';
import 'package:sift/features/memories/memories_service.dart';

Screenshot _shot(DateTime timestamp, {String path = ''}) {
  return Screenshot()
    ..filePath = path.isEmpty ? '/${timestamp.toIso8601String()}.jpg' : path
    ..timestamp = timestamp;
}

void main() {
  group('groupMemories', () {
    final today = DateTime(2026, 9, 7);

    test('a screenshot from exactly one year ago on the same month/day '
        'groups as "1 year ago"', () {
      final result = groupMemories([_shot(DateTime(2025, 9, 7, 14, 30))], today);
      expect(result, hasLength(1));
      expect(result.single.yearsAgo, 1);
      expect(result.single.shots, hasLength(1));
    });

    test('multiple screenshots on the same past date group together', () {
      final result = groupMemories([
        _shot(DateTime(2024, 9, 7, 9), path: '/a.jpg'),
        _shot(DateTime(2024, 9, 7, 18), path: '/b.jpg'),
      ], today);
      expect(result, hasLength(1));
      expect(result.single.yearsAgo, 2);
      expect(result.single.shots, hasLength(2));
    });

    test('different past years produce separate, ascending-sorted memories',
        () {
      final result = groupMemories([
        _shot(DateTime(2022, 9, 7), path: '/four.jpg'),
        _shot(DateTime(2025, 9, 7), path: '/one.jpg'),
        _shot(DateTime(2023, 9, 7), path: '/three.jpg'),
      ], today);
      expect(result.map((m) => m.yearsAgo).toList(), [1, 3, 4]);
    });

    test('today itself is not a memory of itself (0 years ago is excluded)',
        () {
      final result = groupMemories([_shot(DateTime(2026, 9, 7, 8))], today);
      expect(result, isEmpty);
    });

    test('a future date is excluded even if the month/day matches', () {
      final result = groupMemories([_shot(DateTime(2027, 9, 7))], today);
      expect(result, isEmpty);
    });

    test('a different month or day, even close by, does not match', () {
      final result = groupMemories([
        _shot(DateTime(2025, 9, 6)), // one day off
        _shot(DateTime(2025, 8, 7)), // one month off
      ], today);
      expect(result, isEmpty);
    });

    test('an empty library produces no memories', () {
      expect(groupMemories([], today), isEmpty);
    });

    test('Feb 29 only matches Feb 29, not Feb 28 or Mar 1, in a non-leap '
        'year lookup', () {
      final leapDayShot = _shot(DateTime(2024, 2, 29));
      expect(groupMemories([leapDayShot], DateTime(2026, 2, 28)), isEmpty);
      expect(groupMemories([leapDayShot], DateTime(2026, 3, 1)), isEmpty);
      // But it does match on an actual Feb 29 in a later leap year.
      expect(
          groupMemories([leapDayShot], DateTime(2028, 2, 29)), hasLength(1));
    });
  });
}
