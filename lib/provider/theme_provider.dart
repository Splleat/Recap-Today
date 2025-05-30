import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider with ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;
  ThemeMode get themeMode => _themeMode;

  ThemeProvider() {
    _loadTheme();
  }

  void setTheme(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    prefs.setString('themeMode', _themeMode.name);
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final theme = prefs.getString('themeMode');

    if (theme != null) {
      _themeMode = ThemeMode.values.firstWhere(
        (e) => e.name == theme,
        orElse: () => ThemeMode.system,
      );
      notifyListeners();
    }
  }
}