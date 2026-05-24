import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GitHubStatus {
  static bool isConnected = false;
  static String username = "";
  static String repoName = "kyu-org/core-engine";
  static bool isSyncActive = false;

  // Fungsi untuk menyimpan status ke HP
  static Future<void> saveStatus(bool connected, String user, bool sync) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isConnected', connected);
    await prefs.setString('username', user);
    await prefs.setBool('isSyncActive', sync);
    
    isConnected = connected;
    username = user;
    isSyncActive = sync;

    debugPrint("DEBUG: Status disimpan! Connected: $connected, User: $user");
  }

  // Fungsi untuk memanggil status dari HP
  static Future<void> loadStatus() async {
    final prefs = await SharedPreferences.getInstance();
    isConnected = prefs.getBool('isConnected') ?? false;
    username = prefs.getString('username') ?? "";
    isSyncActive = prefs.getBool('isSyncActive') ?? false;
  }
}
