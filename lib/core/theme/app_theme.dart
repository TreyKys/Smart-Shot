import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ── Color tokens ─────────────────────────────────────────────────────────────

class SiftColors {
  SiftColors._();

  // Dark theme — deep navy, not pure black, so the blue accent has room to breathe.
  static const background = Color(0xFF0A0F1E);
  static const surface = Color(0xFF111827);
  static const surfaceElevated = Color(0xFF1A2436);
  static const border = Color(0xFF243044);
  static const accent = Color(0xFF4C8DFF); // electric blue
  static const accentDim = Color(0xFF2F6FED);
  static const textPrimary = Color(0xFFF5F7FC);
  static const textSecondary = Color(0xFF8C9BB5);
  static const textTertiary = Color(0xFF4E5C74);
  static const danger = Color(0xFFFF4757);
  static const warning = Color(0xFFFFA502);
  static const success = Color(0xFF2ED573);
  static const proGold = Color(0xFFFFD700);

  // Light theme — soft, cool blue-tinted surfaces rather than stark white.
  static const lightBackground = Color(0xFFEFF4FC);
  static const lightSurface = Color(0xFFFFFFFF);
  static const lightBorder = Color(0xFFD9E3F5);
  static const lightPrimary = Color(0xFF2563EB);
  static const lightSecondary = Color(0xFF3B82F6);
  static const lightTextPrimary = Color(0xFF0F172A);
  static const lightTextSecondary = Color(0xFF5B6B85);

  // Tag palette
  static const tagFinance = Color(0xFF2ED573);
  static const tagMemes = Color(0xFFAE6EFD);
  static const tagJunk = Color(0xFFFF4757);
  static const tagToDo = Color(0xFFFFA502);
  static const tagTravel = Color(0xFF4C8DFF);
  static const tagWeb3 = Color(0xFFFF6B81);
  static const tagCode = Color(0xFF38BDF8);
  static const tagSocial = Color(0xFFFC5C7D);
  static const tagDefault = Color(0xFF8C9BB5);

  static Color forTag(String tag) {
    final t = tag.toLowerCase().replaceAll('#', '');
    if (t.contains('finance') || t.contains('receipt') || t.contains('money')) return tagFinance;
    if (t.contains('meme') || t.contains('funny')) return tagMemes;
    if (t.contains('junk') || t.contains('trash')) return tagJunk;
    if (t.contains('todo') || t.contains('to-do') || t.contains('task')) return tagToDo;
    if (t.contains('travel') || t.contains('flight') || t.contains('hotel')) return tagTravel;
    if (t.contains('web3') || t.contains('crypto') || t.contains('nft') || t.contains('btc')) return tagWeb3;
    if (t.contains('code') || t.contains('dev') || t.contains('git')) return tagCode;
    if (t.contains('social') || t.contains('instagram') || t.contains('twitter')) return tagSocial;
    return tagDefault;
  }
}

// ── Shared motion ─────────────────────────────────────────────────────────────

/// Smoother, more "fluid" cross-screen transitions than the Android default
/// (which snaps between screens). Used by both the light and dark themes.
final _fluidPageTransitions = PageTransitionsTheme(
  builders: {
    TargetPlatform.android: const FadeForwardsPageTransitionsBuilder(),
    TargetPlatform.iOS: const CupertinoPageTransitionsBuilder(),
  },
);

// ── Theme builders ────────────────────────────────────────────────────────────

ThemeData buildSiftLightTheme() {
  const colorScheme = ColorScheme(
    brightness: Brightness.light,
    primary: SiftColors.lightPrimary,
    onPrimary: Colors.white,
    secondary: SiftColors.lightSecondary,
    onSecondary: Colors.white,
    error: SiftColors.danger,
    onError: Colors.white,
    surface: SiftColors.lightSurface,
    onSurface: SiftColors.lightTextPrimary,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: SiftColors.lightBackground,
    canvasColor: SiftColors.lightBackground,
    pageTransitionsTheme: _fluidPageTransitions,
    appBarTheme: const AppBarTheme(
      backgroundColor: SiftColors.lightBackground,
      foregroundColor: SiftColors.lightTextPrimary,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        color: SiftColors.lightTextPrimary,
        fontSize: 20,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
      ),
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: SiftColors.lightBackground,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    ),
    cardTheme: CardThemeData(
      color: SiftColors.lightSurface,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: SiftColors.lightBorder, width: 0.5),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: SiftColors.lightPrimary,
        foregroundColor: Colors.white,
        elevation: 0,
        textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, letterSpacing: 0.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: SiftColors.lightPrimary,
        textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      ),
    ),
    dividerTheme: const DividerThemeData(color: SiftColors.lightBorder, thickness: 0.5, space: 1),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: SiftColors.lightTextPrimary,
      contentTextStyle: const TextStyle(color: Colors.white),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      behavior: SnackBarBehavior.floating,
    ),
  );
}

ThemeData buildSiftTheme() {
  const colorScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: SiftColors.accent,
    onPrimary: SiftColors.background,
    secondary: SiftColors.accentDim,
    onSecondary: SiftColors.background,
    error: SiftColors.danger,
    onError: SiftColors.textPrimary,
    surface: SiftColors.surface,
    onSurface: SiftColors.textPrimary,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: SiftColors.background,
    canvasColor: SiftColors.background,
    pageTransitionsTheme: _fluidPageTransitions,

    // AppBar
    appBarTheme: const AppBarTheme(
      backgroundColor: SiftColors.background,
      foregroundColor: SiftColors.textPrimary,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        color: SiftColors.textPrimary,
        fontSize: 20,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
      ),
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: SiftColors.background,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    ),

    // Cards
    cardTheme: CardThemeData(
      color: SiftColors.surface,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: SiftColors.border, width: 0.5),
      ),
    ),

    // Chips
    chipTheme: ChipThemeData(
      backgroundColor: SiftColors.surfaceElevated,
      labelStyle: const TextStyle(
        color: SiftColors.textPrimary,
        fontSize: 11,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.2,
      ),
      side: const BorderSide(color: SiftColors.border, width: 0.5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
    ),

    // Search bar
    searchBarTheme: SearchBarThemeData(
      backgroundColor: WidgetStateProperty.all(SiftColors.surfaceElevated),
      elevation: WidgetStateProperty.all(0),
      textStyle: WidgetStateProperty.all(
        const TextStyle(color: SiftColors.textPrimary, fontSize: 15),
      ),
      hintStyle: WidgetStateProperty.all(
        const TextStyle(color: SiftColors.textSecondary, fontSize: 15),
      ),
      shape: WidgetStateProperty.all(
        RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: SiftColors.border),
        ),
      ),
    ),

    // Elevated button
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: SiftColors.accent,
        foregroundColor: SiftColors.background,
        elevation: 0,
        textStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      ),
    ),

    // Text button
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: SiftColors.accent,
        textStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.3,
        ),
      ),
    ),

    // Divider
    dividerTheme: const DividerThemeData(
      color: SiftColors.border,
      thickness: 0.5,
      space: 1,
    ),

    // Icon
    iconTheme: const IconThemeData(color: SiftColors.textSecondary, size: 22),

    // Input decoration
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: SiftColors.surfaceElevated,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: SiftColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: SiftColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: SiftColors.accent, width: 1.5),
      ),
      labelStyle: const TextStyle(color: SiftColors.textSecondary),
      hintStyle: const TextStyle(color: SiftColors.textTertiary),
    ),

    // List tile
    listTileTheme: const ListTileThemeData(
      textColor: SiftColors.textPrimary,
      iconColor: SiftColors.textSecondary,
      tileColor: Colors.transparent,
    ),

    // Bottom sheet
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: Colors.transparent,
      elevation: 0,
    ),

    // Progress indicator
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: SiftColors.accent,
      linearTrackColor: SiftColors.border,
    ),

    // Snack bar
    snackBarTheme: SnackBarThemeData(
      backgroundColor: SiftColors.surfaceElevated,
      contentTextStyle: const TextStyle(color: SiftColors.textPrimary),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      behavior: SnackBarBehavior.floating,
    ),
  );
}
