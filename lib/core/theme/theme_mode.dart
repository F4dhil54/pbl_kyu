import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ThemeControl {
  static final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.light);
  static String? _currentUserId;

  static Future<void> loadTheme(String userId) async {
    _currentUserId = userId;
    
    // Cek metadata Supabase
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null && user.userMetadata != null && user.userMetadata!['theme'] != null) {
      final isDark = user.userMetadata!['theme'] == 'dark';
      themeNotifier.value = isDark ? ThemeMode.dark : ThemeMode.light;
      
      // Simpan cache lokal
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('theme_dark_$userId', isDark);
      return;
    }

    // Fallback ke lokal
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

      // Simpan ke metadata Supabase
      try {
        await Supabase.instance.client.auth.updateUser(
          UserAttributes(
            data: {'theme': isDark ? 'dark' : 'light'},
          ),
        );
      } catch (e) {
        debugPrint("Gagal menyimpan preferensi tema ke Supabase: $e");
      }
    }
  }

  static void resetTheme() {
    _currentUserId = null;
    themeNotifier.value = ThemeMode.light;
  }
}
