import 'package:flutter/material.dart';

class AppColors {
  // Main colors
  static const Color primary = Color(0xFF1E50FF); // The vibrant blue used in buttons, progress bars, and highlights
  static const Color background = Color(0xFFFAFAFA); // Very light grey background for the app
  static const Color surface = Colors.white; // White color for cards and containers
  static const Color onboardingBackground = Color(0xFF031634); // Deep dark blue for onboarding screen

  // Text colors
  static const Color textMain = Color(0xFF1A1A1A); // Dark text for headings
  static const Color textSecondary = Color(0xFF757575); // Grey text for subtitles and unselected items
  static const Color textLight = Colors.white; // White text

  // Status colors
  static const Color successBackground = Color(0xFFE8F5E9); // Light green for active/success tag
  static const Color successText = Color(0xFF2E7D32); // Dark green text/dot
  static const Color warningBackground = Color(0xFFFFF3E0); // Light orange for busy tag
  static const Color warningText = Color(0xFFE65100); // Dark orange text/dot
  static const Color offlineBackground = Color(0xFFF5F5F5); // Grey for offline tag
  static const Color offlineText = Color(0xFF9E9E9E); // Grey text/dot for offline
  static const Color alertText = Color(0xFFD32F2F); // Red for error messages

  // Legacy Status colors (for older screens)
  static const Color success = Color(0xFF2E7D32);
  static const Color pending = Color(0xFFEBB4F6);
  static const Color pendingText = Color(0xFF8E24AA);

  // New specific colors (Phase 2)
  static const Color rank1Background = Color(0xFF021C34); // Dark navy for Rank 1 card
  static const Color buttonDark = Color(0xFF02162B); // Very dark blue for primary buttons (Buat Proyek)
  static const Color lightBlueSelection = Color(0xFFE5EEFF); // For selected labels like 'Urgent'


  // Inputs & borders
  static const Color inputBackground = Colors.white; // White input fields
  static const Color border = Color(0xFFE0E0E0); // Light grey border
}

class AppDarkColors {
  static const Color background = Color(0xFF0F172A);
  static const Color surface = Color(0xFF1E293B);
  static const Color textMain = Colors.white; 
  static const Color textSecondary = Color(0xFF94A3B8);
  static const Color border = Color(0xFF334155);
}
