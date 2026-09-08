import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The user's actual choice — "System" is its own state, not just "whatever
/// Brightness the OS reports right now," so the app can tell "the user
/// picked Dark" apart from "the user picked System and the OS happens to be
/// dark" when deciding what to show as selected in Settings.
enum SiftThemeMode { dark, light, system }

const String _kPrefsKey = 'sift_theme_mode';

/// Persists to SharedPreferences on every change and loads the saved choice
/// on startup — defaults to [SiftThemeMode.dark] (this app's original,
/// only-ever-shipped look) until that load resolves, so a fresh install
/// never flashes an unstyled or wrong-looking frame while prefs are read.
class ThemeModeNotifier extends StateNotifier<SiftThemeMode> {
  ThemeModeNotifier() : super(SiftThemeMode.dark) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kPrefsKey);
    for (final mode in SiftThemeMode.values) {
      if (mode.name == raw) {
        state = mode;
        return;
      }
    }
  }

  Future<void> setMode(SiftThemeMode mode) async {
    state = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kPrefsKey, mode.name);
  }
}

final themeModeProvider =
    StateNotifierProvider<ThemeModeNotifier, SiftThemeMode>((ref) {
  return ThemeModeNotifier();
});

/// Resolves the user's [SiftThemeMode] choice against the OS's current
/// brightness for the "System" case — the one place that actually needs to
/// know what the device is set to, so nothing else in the app has to.
Brightness resolveBrightness(SiftThemeMode mode, Brightness platform) {
  switch (mode) {
    case SiftThemeMode.dark:
      return Brightness.dark;
    case SiftThemeMode.light:
      return Brightness.light;
    case SiftThemeMode.system:
      return platform;
  }
}
