import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Controls Alpha Plus appearance across the whole app.
///
/// A fresh install follows the device. An explicit Light/Dark/System choice is
/// stored locally and restored the next time Alpha Plus starts.
abstract final class AppThemeController {
  static const String _preferenceKey = 'alpha_plus_theme_mode';

  static final ValueNotifier<ThemeMode> themeMode = ValueNotifier<ThemeMode>(
    ThemeMode.system,
  );

  static Future<void> initialize() async {
    try {
      final SharedPreferences preferences =
          await SharedPreferences.getInstance();
      final String? storedMode = preferences.getString(_preferenceKey);

      themeMode.value = switch (storedMode) {
        'light' => ThemeMode.light,
        'dark' => ThemeMode.dark,
        _ => ThemeMode.system,
      };
    } on Object {
      // A preference read failure must never stop Alpha Plus from launching.
      themeMode.value = ThemeMode.system;
    }
  }

  static void setThemeMode(ThemeMode mode) {
    if (themeMode.value == mode) return;

    themeMode.value = mode;
    unawaited(_persist(mode));
  }

  static Future<void> _persist(ThemeMode mode) async {
    try {
      final SharedPreferences preferences =
          await SharedPreferences.getInstance();

      final String value = switch (mode) {
        ThemeMode.system => 'system',
        ThemeMode.light => 'light',
        ThemeMode.dark => 'dark',
      };

      await preferences.setString(_preferenceKey, value);
    } on Object {
      // Keep the in-memory choice active even if persistence is unavailable.
    }
  }
}
