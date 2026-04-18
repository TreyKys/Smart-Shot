import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ── Color tokens ─────────────────────────────────────────────────────────────

class SiftColors {
  SiftColors._();

  static const background = Color(0xFF090909);
  static const surface = Color(0xFF111111);
  static const surfaceElevated = Color(0xFF1A1A1A);
  static const border = Color(0xFF242424);
  static const accent = Color(0xFF00FFD1); // neon cyan
  static const accentDim = Color(0xFF00B894);
  static const textPrimary = Color(0xFFFFFFFF);
  static const textSecondary = Color(0xFF8A8A8A);
  static const textTertiary = Color(0xFF4A4A4A);
  static const danger = Color(0xFFFF4757);
  static const warning = Color(0xFFFFA502);
  static const success = Color(0xFF2ED573);
  static const proGold = Color(0xFFFFD700);

  // Tag palette
  static const tagFinance = Color(0xFF2ED573);
  static const tagMemes = Color(0xFFAE6EFD);
  static const tagJunk = Color(0xFFFF4757);
  static const tagToDo = Color(0xFFFFA502);
  static const tagTravel = Color(0xFF1E90FF);
  static const tagWeb3 = Color(0xFFFF6B81);
  static const tagCode = Color(0xFF00D2FF);
  static const tagSocial = Color(0xFFFC5C7D);
  static const tagDefault = Color(0xFF8A8A8A);

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

// ── Theme builders ────────────────────────────────────────────────────────────

ThemeData buildSiftLightTheme() {
  const colorScheme = ColorScheme(
    brightness: Brightness.light,
    primary: Color(0xFF00A381),
    onPrimary: Colors.white,
    secondary: Color(0xFF00B894),
    onSecondary: Colors.white,
    error: SiftColors.danger,
    onError: Colors.white,
    surface: Colors.white,
    onSurface: Color(0xFF111111),
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: const Color(0xFFF2F2F7),
    canvasColor: const Color(0xFFF2F2F7),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFFF2F2F7),
      foregroundColor: Color(0xFF111111),
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        color: Color(0xFF111111),
        fontSize: 20,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
      ),
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: Color(0xFFF2F2F7),
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFFE0E0E0), width: 0.5),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF00A381),
        foregroundColor: Colors.white,
        elevation: 0,
        textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, letterSpacing: 0.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: const Color(0xFF00A381),
        textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      ),
    ),
    dividerTheme: const DividerThemeData(color: Color(0xFFE0E0E0), thickness: 0.5, space: 1),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: const Color(0xFF1A1A1A),
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
