/// Theme state model using ChangeNotifier.
///
/// Exposes [isDarkMode] and [toggleTheme()] so any widget
/// can read the current mode or switch between light / dark.
import 'package:flutter/material.dart';

class ThemeModel extends ChangeNotifier {
  bool _isDarkMode = false;

  /// Whether the current theme is dark.
  bool get isDarkMode => _isDarkMode;

  /// Current [ThemeMode] derived from [isDarkMode].
  ThemeMode get themeMode => _isDarkMode ? ThemeMode.dark : ThemeMode.light;

  /// Toggle between light and dark theme and notify listeners.
  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
  }
}
