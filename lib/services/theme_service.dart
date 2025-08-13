import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service for managing app themes and colors
class ThemeService extends ChangeNotifier {
  static const String _themeKey = 'app_theme_color';
  static const String _darkModeKey = 'dark_mode_enabled';

  // Predefined color schemes
  static const Map<String, Color> availableColors = {
    'Blue': Color(0xFF2196F3),
    'Green': Color(0xFF4CAF50),
    'Purple': Color(0xFF9C27B0),
    'Orange': Color(0xFFFF9800),
    'Red': Color(0xFFF44336),
    'Teal': Color(0xFF009688),
    'Indigo': Color(0xFF3F51B5),
    'Pink': Color(0xFFE91E63),
    'Brown': Color(0xFF795548),
    'Deep Orange': Color(0xFFFF5722),
  };

  Color _primaryColor = availableColors['Red']!;
  bool _isDarkMode = false;
  SharedPreferences? _prefs;

  // Getters
  Color get primaryColor => _primaryColor;
  bool get isDarkMode => _isDarkMode;

  String get currentColorName {
    return availableColors.entries
        .firstWhere((entry) => entry.value == _primaryColor)
        .key;
  }

  /// Initialize the theme service
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    await _loadThemeSettings();
  }

  /// Load saved theme settings
  Future<void> _loadThemeSettings() async {
    if (_prefs == null) return;

    // Load primary color
    final colorValue = _prefs!.getInt(_themeKey);
    if (colorValue != null) {
      _primaryColor = Color(colorValue);
    }

    // Load dark mode setting
    _isDarkMode = _prefs!.getBool(_darkModeKey) ?? false;

    notifyListeners();
  }

  /// Save theme settings
  Future<void> _saveThemeSettings() async {
    if (_prefs == null) return;

    await _prefs!.setInt(_themeKey, _primaryColor.value);
    await _prefs!.setBool(_darkModeKey, _isDarkMode);
  }

  /// Change the primary color
  Future<void> setPrimaryColor(Color color) async {
    _primaryColor = color;
    await _saveThemeSettings();
    notifyListeners();
  }

  /// Change the primary color by name
  Future<void> setPrimaryColorByName(String colorName) async {
    final color = availableColors[colorName];
    if (color != null) {
      await setPrimaryColor(color);
    }
  }

  /// Toggle dark mode
  Future<void> toggleDarkMode() async {
    _isDarkMode = !_isDarkMode;
    await _saveThemeSettings();
    notifyListeners();
  }

  /// Set dark mode
  Future<void> setDarkMode(bool enabled) async {
    _isDarkMode = enabled;
    await _saveThemeSettings();
    notifyListeners();
  }

  /// Generate light theme data
  ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: _primaryColor,
        brightness: Brightness.light,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: _primaryColor,
        foregroundColor: Colors.white,
        elevation: 2,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _primaryColor,
          foregroundColor: Colors.white,
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: _primaryColor,
        foregroundColor: Colors.white,
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return _primaryColor;
          }
          return null;
        }),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return _primaryColor;
          }
          return null;
        }),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: _primaryColor),
    );
  }

  /// Generate dark theme data
  ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: _primaryColor,
        brightness: Brightness.dark,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: _primaryColor.withOpacity(0.8),
        foregroundColor: Colors.white,
        elevation: 2,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _primaryColor,
          foregroundColor: Colors.white,
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: _primaryColor,
        foregroundColor: Colors.white,
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return _primaryColor;
          }
          return null;
        }),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return _primaryColor;
          }
          return null;
        }),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: _primaryColor),
    );
  }

  /// Get the appropriate theme based on dark mode setting
  ThemeData get currentTheme => _isDarkMode ? darkTheme : lightTheme;

  /// Reset to default theme
  Future<void> resetToDefault() async {
    _primaryColor = availableColors['Blue']!;
    _isDarkMode = false;
    await _saveThemeSettings();
    notifyListeners();
  }
}
