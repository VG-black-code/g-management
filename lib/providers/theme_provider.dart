import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';

class ThemeProvider extends ChangeNotifier {
  static const String _themeKey = "selected_theme";
  ThemeData _currentTheme = AppTheme.lavenderTheme;
  String _currentThemeName = "Lavender";

  ThemeProvider() {
    _loadTheme();
  }

  ThemeData get currentTheme => _currentTheme;
  String get themeName => _currentThemeName;

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final savedTheme = prefs.getString(_themeKey) ?? "Lavender";
    setTheme(savedTheme, save: false);
  }

  void setTheme(String name, {bool save = true}) {
    _currentThemeName = name;
    switch (name) {
      case 'Lavender':
        _currentTheme = AppTheme.lavenderTheme;
        break;
      case 'Dark':
        _currentTheme = AppTheme.darkTheme;
        break;
      case 'Blue':
        _currentTheme = AppTheme.blueTheme;
        break;
      case 'Orange':
        _currentTheme = AppTheme.orangeTheme;
        break;
      default:
        _currentTheme = AppTheme.lavenderTheme;
        break;
    }
    notifyListeners();
    if (save) {
      SharedPreferences.getInstance().then((prefs) {
        prefs.setString(_themeKey, name);
      });
    }
  }
}
