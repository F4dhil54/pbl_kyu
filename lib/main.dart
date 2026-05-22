import 'package:flutter/material.dart';
import 'package:pbl_kyu/features/auth/presentation/views/onboarding_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'features/main_layout.dart';
import 'core/theme/colors.dart';
import 'core/theme/theme_mode.dart';

void main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();
    debugPrint("=== DEBUG: [1/4] Binding Flutter Berhasil ===");

    await dotenv.load(fileName: ".env");
    debugPrint("=== DEBUG: [2/4] File .env Berhasil Dimuat ===");

    await Supabase.initialize(
      url: dotenv.env['SUPABASE_URL'] ?? '',
      anonKey: dotenv.env['SUPABASE_ANON_KEY'] ?? '',
    );
    debugPrint("=== DEBUG: [3/4] Jembatan Supabase Berhasil Terhubung! ===");

    debugPrint("=== DEBUG: [4/4] Menjalankan Aplikasi KYU ===");
    runApp(
      const ProviderScope(
        child: MyApp(),
      ),
    );
  } catch (e) {
    // Menangkap error jika lupa daftarkan aset di pubspec atau salah ketik key
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
          
          // Tema terang
          theme: ThemeData(
            fontFamily: 'Inter',
            colorScheme: ColorScheme.fromSeed(
              seedColor: AppColors.primary,
              brightness: Brightness.light,
            ),
            scaffoldBackgroundColor: AppColors.background,
            useMaterial3: true,
          ),
          
          // Tema gelap
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
          
          home: const OnboardingScreen(),
        );
      },
    );
  }
}
