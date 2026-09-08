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

/// Was GalleryDrawer's own private _getIconForTag — pulled out here once the
/// Organize hub needed the exact same tag -> icon mapping for its cluster
/// cards, rather than that logic existing twice.
IconData iconForTag(String tag) {
  final lower = tag.toLowerCase().replaceAll('#', '');
  if (lower.contains('finance') ||
      lower.contains('receipt') ||
      lower.contains('money')) return CupertinoIcons.money_dollar;
  if (lower.contains('travel') || lower.contains('flight')) {
    return CupertinoIcons.airplane;
  }
  if (lower.contains('web3') ||
      lower.contains('crypto') ||
      lower.contains('btc') ||
      lower.contains('eth')) return CupertinoIcons.bitcoin;
  if (lower.contains('code') ||
      lower.contains('dev') ||
      lower.contains('git')) {
    return CupertinoIcons.chevron_left_slash_chevron_right;
  }
  if (lower.contains('social') ||
      lower.contains('instagram') ||
      lower.contains('twitter')) return CupertinoIcons.person_2;
  if (lower.contains('meme') || lower.contains('funny')) {
    return CupertinoIcons.smiley;
  }
  if (lower.contains('chem') ||
      lower.contains('science') ||
      lower.contains('lab')) return CupertinoIcons.lab_flask;
  if (lower.contains('date') ||
      lower.contains('calendar') ||
      lower.contains('schedule')) return CupertinoIcons.calendar;
  if (lower.contains('chart') ||
      lower.contains('trading') ||
      lower.contains('stock')) return CupertinoIcons.graph_circle;
  if (lower.contains('news') || lower.contains('article')) {
    return CupertinoIcons.news;
  }
  if (lower.contains('shop') || lower.contains('buy')) {
    return CupertinoIcons.shopping_cart;
  }
  if (lower.contains('music') || lower.contains('song')) {
    return CupertinoIcons.music_note;
  }
  if (lower.contains('video') || lower.contains('movie')) {
    return CupertinoIcons.film;
  }
  if (lower.contains('book') ||
      lower.contains('read') ||
      lower.contains('edu')) return CupertinoIcons.book;
  if (lower.contains('sport') ||
      lower.contains('football') ||
      lower.contains('soccer')) return CupertinoIcons.sportscourt;
  if (lower.contains('food') || lower.contains('restaurant')) {
    return CupertinoIcons.cart;
  }
  return CupertinoIcons.tag;
}

// ── Candy Pillowy palette — RETIRED, now an alias for SiftColors ───────────
//
// This used to be a second, self-contained light palette ("Candy Pillowy
// UI": Plus Jakarta Sans, warm-cream ground, coral/violet/aqua accents),
// wired into Discover, Organize, Collections' bottom-nav bar, the assistant,
// duplicate review, junk review, and the memory grid — while every other
// screen (the gallery grid, image detail, Settings, onboarding, the paywall,
// Collections' own list) ran on the dark [SiftColors] palette instead. Two
// unrelated palettes active in the same app is exactly what read as "two
// different apps" to anyone tapping from one tab to the next — a jarring
// light/dark seam with a second typography voice on top of it.
//
// Every field below now just points at the real [SiftColors] dark palette
// instead of an independent light one. That fixes every screen that
// references `SiftPillowyColors`/`SiftPillowyText` without having to touch
// each screen's actual layout code — same widgets, same shadows, real
// tokens. New code should reach for [SiftColors] directly; these aliases
// exist only so the screens still written against the old names keep
// working, and can be deleted once nothing references them anymore.
class SiftPillowyColors {
  SiftPillowyColors._();

  static const surface = SiftColors.background;
  static const surfaceContainerLowest = SiftColors.surface;
  static const surfaceContainerLow = SiftColors.surfaceElevated;
  static const surfaceContainer = SiftColors.surfaceElevated;
  static const surfaceContainerHigh = SiftColors.surfaceElevated;
  static const surfaceContainerHighest = SiftColors.border;
  static const surfaceVariant = SiftColors.surfaceElevated;
  static const surfaceDim = SiftColors.border;
  static const outline = SiftColors.border;
  static const outlineVariant = SiftColors.border;

  static const onSurface = SiftColors.textPrimary;
  static const onSurfaceVariant = SiftColors.textSecondary;

  static const primary = SiftColors.accent;
  static const onPrimary = SiftColors.background;
  static const primaryContainer = SiftColors.accentDim;
  static const onPrimaryContainer = SiftColors.background;

  static const secondary = SiftColors.tagMemes;
  static const onSecondary = SiftColors.background;
  static const secondaryContainer = SiftColors.tagMemes;
  static const onSecondaryContainer = SiftColors.background;
  static const secondaryFixed = SiftColors.surfaceElevated;
  static const onSecondaryFixed = SiftColors.tagMemes;

  static const tertiary = SiftColors.success;
  static const onTertiary = SiftColors.background;
  static const tertiaryContainer = SiftColors.success;
  static const tertiaryFixed = SiftColors.success;

  static const error = SiftColors.danger;
  static const onError = SiftColors.textPrimary;

  /// The primary send-button / user-bubble gradient — both stops are now
  /// the app's real blue accent rather than the old red-to-coral pair.
  static const primaryGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [primary, primaryContainer],
  );

  /// The assistant-avatar gradient — violet to blue, both drawn from
  /// [SiftColors] instead of the old violet-to-coral pair.
  static const assistantAvatarGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [secondary, primary],
  );
}

class SiftPillowyText {
  SiftPillowyText._();

  // No fontFamily override anymore — this used to pin every Pillowy screen
  // to Plus Jakarta Sans while the rest of the app used the system default,
  // which was its own quiet "two interfaces" tell alongside the color
  // mismatch. Falling through to the default lines these screens up
  // typographically with everything else.
  static const headlineSm = TextStyle(
    fontSize: 18,
    height: 24 / 18,
    fontWeight: FontWeight.w600,
    color: SiftPillowyColors.onSurface,
  );
  static const headlineMd = TextStyle(
    fontSize: 22,
    height: 28 / 22,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.2,
    color: SiftPillowyColors.onSurface,
  );
  static const bodyMd = TextStyle(
    fontSize: 14,
    height: 20 / 14,
    fontWeight: FontWeight.w400,
    color: SiftPillowyColors.onSurface,
  );
  static const bodySm = TextStyle(
    fontSize: 12,
    height: 16 / 12,
    fontWeight: FontWeight.w400,
    color: SiftPillowyColors.onSurfaceVariant,
  );
  static const labelLg = TextStyle(
    fontSize: 14,
    height: 18 / 14,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.1,
  );
  static const labelMd = TextStyle(
    fontSize: 12,
    height: 16 / 12,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.2,
  );
  static const labelSm = TextStyle(
    fontSize: 10,
    height: 12 / 10,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.4,
  );
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
