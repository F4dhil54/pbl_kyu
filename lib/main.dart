import 'package:flutter/material.dart';
import 'screens/views/onboarding_screen.dart';
import 'theme/colors.dart';
import 'theme/theme_mode.dart';
void main() {
  runApp(const MyApp());
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