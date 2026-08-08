import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sift/core/theme/app_theme.dart';

void main() {
  group('SiftColors.forTag', () {
    test('maps known keywords to their tag color', () {
      expect(SiftColors.forTag('Receipt'), SiftColors.tagFinance);
      expect(SiftColors.forTag('#funny meme'), SiftColors.tagMemes);
      expect(SiftColors.forTag('junk'), SiftColors.tagJunk);
      expect(SiftColors.forTag('todo'), SiftColors.tagToDo);
      expect(SiftColors.forTag('flight booking'), SiftColors.tagTravel);
      expect(SiftColors.forTag('crypto/nft'), SiftColors.tagWeb3);
      expect(SiftColors.forTag('git commit'), SiftColors.tagCode);
      expect(SiftColors.forTag('instagram post'), SiftColors.tagSocial);
    });

    test('falls back to the default color for unrecognized tags', () {
      expect(SiftColors.forTag('random-unmatched-tag'), SiftColors.tagDefault);
    });

    test('is case-insensitive and ignores a leading #', () {
      expect(SiftColors.forTag('#TODO'), SiftColors.tagToDo);
      expect(SiftColors.forTag('TODO'), SiftColors.tagToDo);
    });
  });

  group('buildSiftTheme / buildSiftLightTheme', () {
    test('dark theme uses Material 3 and a dark color scheme', () {
      final theme = buildSiftTheme();
      expect(theme.useMaterial3, isTrue);
      expect(theme.colorScheme.brightness, Brightness.dark);
    });

    test('light theme uses Material 3 and a light color scheme', () {
      final theme = buildSiftLightTheme();
      expect(theme.useMaterial3, isTrue);
      expect(theme.colorScheme.brightness, Brightness.light);
    });
  });
}
