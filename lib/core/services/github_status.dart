import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GitHubStatus {
  static bool isConnected = false;
  static String username = "";
  static String repoName = "kyu-org/core-engine";
  static bool isSyncActive = false;

  // Simpan status ke perangkat
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

  // Muat status dari perangkat
  static Future<void> loadStatus() async {
    final prefs = await SharedPreferences.getInstance();
    isConnected = prefs.getBool('isConnected') ?? false;
    username = prefs.getString('username') ?? "";
    isSyncActive = prefs.getBool('isSyncActive') ?? false;
  }

  // Hapus status saat logout
  static Future<void> clearStatus() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('isConnected');
    await prefs.remove('username');
    await prefs.remove('isSyncActive');
    
    isConnected = false;
    username = "";
    isSyncActive = false;
  }
}
