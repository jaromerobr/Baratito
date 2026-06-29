/// Theme state model using ChangeNotifier, persisted with SharedPreferences.
///
/// Exposes [isDarkMode] and [toggleTheme()] so any widget can read the current
/// mode or switch between light / dark. The choice is saved on device and
/// restored on the next app launch.
library;

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeModel extends ChangeNotifier {
  static const _prefsKey = 'baratito_dark_mode';

  bool _isDarkMode = false;

  ThemeModel() {
    _load();
  }

  /// Whether the current theme is dark.
  bool get isDarkMode => _isDarkMode;

  /// Current [ThemeMode] derived from [isDarkMode].
  ThemeMode get themeMode => _isDarkMode ? ThemeMode.dark : ThemeMode.light;

  /// Load the saved preference at startup.
  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool(_prefsKey) ?? false;
    notifyListeners();
  }

  /// Toggle between light and dark theme, notify listeners and persist.
  Future<void> toggleTheme() async {
    await setDarkMode(!_isDarkMode);
  }

  /// Set the dark mode flag, notify listeners and persist it.
  Future<void> setDarkMode(bool value) async {
    if (_isDarkMode == value) return;
    _isDarkMode = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefsKey, value);
  }
}
