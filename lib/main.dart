import 'package:flutter/material.dart';
import 'package:pbl_kyu/features/auth/presentation/views/onboarding_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'core/theme/colors.dart';
import 'core/theme/theme_mode.dart';
import 'core/services/notification_service.dart';
import 'features/main_layout.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint("Menangani pesan latar belakang: ${message.messageId}");
}

void main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();
    debugPrint("=== DEBUG: [1/4] Binding Flutter Berhasil ===");

    await Firebase.initializeApp();
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    debugPrint("=== DEBUG: Firebase Berhasil Diinisialisasi ===");

    // Tangani pesan foreground
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint("Menangani pesan di foreground: ${message.notification?.title}");
      if (message.notification != null) {
        LocalNotificationService.showNotification(
          id: message.hashCode,
          title: message.notification!.title ?? '',
          body: message.notification!.body ?? '',
        );
      }
    });

    await dotenv.load(fileName: ".env");
    debugPrint("=== DEBUG: [2/4] File .env Berhasil Dimuat ===");

    await LocalNotificationService.initialize();
    debugPrint("=== DEBUG: LocalNotificationService Berhasil Dimuat ===");

    await Supabase.initialize(
      url: dotenv.env['SUPABASE_URL'] ?? '',
      anonKey: dotenv.env['SUPABASE_ANON_KEY'] ?? '',
    );
    debugPrint("=== DEBUG: [3/4] Jembatan Supabase Berhasil Terhubung! ===");

    final currentUser = Supabase.instance.client.auth.currentUser;
    if (currentUser != null) {
      await ThemeControl.loadTheme(currentUser.id);
    }

    debugPrint("=== DEBUG: [4/4] Menjalankan Aplikasi KYU ===");
    runApp(
      const ProviderScope(
        child: MyApp(),
      ),
    );
  } catch (e) {
    // Tangkap error konfigurasi/kunci
    debugPrint("=== ERROR CRITICAL: Gagal memuat konfigurasi -> $e ===");
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeControl.themeNotifier,
      builder: (context, currentMode, child) {
        return MaterialApp(
          title: 'KYU App',
          debugShowCheckedModeBanner: false,
          
          // Tema Terang
          theme: ThemeData(
            fontFamily: 'Inter',
            colorScheme: ColorScheme.fromSeed(
              seedColor: AppColors.primary,
              brightness: Brightness.light,
            ),
            scaffoldBackgroundColor: AppColors.background,
            useMaterial3: true,
          ),
          
          // Tema Gelap
          darkTheme: ThemeData(
            fontFamily: 'Inter',
            colorScheme: ColorScheme.fromSeed(
              seedColor: AppColors.primary,
              brightness: Brightness.dark,
              surface: AppDarkColors.surface,
            ),
            scaffoldBackgroundColor: AppDarkColors.background,
            useMaterial3: true,
          ),
          
          themeMode: currentMode,
          
          home: Supabase.instance.client.auth.currentSession != null 
              ? MainLayout(role: Supabase.instance.client.auth.currentUser?.userMetadata?['role'] ?? 'Tim')
              : const OnboardingScreen(),
        );
      },
    );
  }
}
