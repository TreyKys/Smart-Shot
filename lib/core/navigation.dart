import 'package:flutter/material.dart';

/// App-wide navigator key, set on the MaterialApp in main.dart.
///
/// Exists for exactly one reason right now: a tapped notification needs
/// somewhere to push a screen from, and NotificationService — a plain
/// singleton, not a widget — has no BuildContext of its own to do that with.
/// Only useful from the UI isolate; a background isolate (WorkManager) has
/// no widget tree at all, so this stays null/unattached there regardless.
final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();
