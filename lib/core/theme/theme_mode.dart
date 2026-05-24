import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeControl {
  static final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.light);
  static String? _currentUserId;

  static Future<void> loadTheme(String userId) async {
    _currentUserId = userId;
    final prefs = await SharedPreferences.getInstance();
    final isDark = prefs.getBool('theme_dark_$userId') ?? false;
    themeNotifier.value = isDark ? ThemeMode.dark : ThemeMode.light;
  }

  static Future<void> toggleTheme() async {
    final isDark = themeNotifier.value == ThemeMode.light;
    themeNotifier.value = isDark ? ThemeMode.dark : ThemeMode.light;
    
    if (_currentUserId != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('theme_dark_$_currentUserId', isDark);
    }
  }

  static void resetTheme() {
    _currentUserId = null;
    themeNotifier.value = ThemeMode.light;
  }
}
