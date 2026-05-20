import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/theme_mode.dart';
import 'register_screen.dart';
import 'onboarding_screen.dart';
import '../../../main_layout.dart';
import '../../../../core/network/supabase_provider.dart'; 

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  String selectedRole = 'Tim';
  bool _isGoogleLoading = false;

  void _handleLogin() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => MainLayout(role: selectedRole)),
    );
  }

  // Otorisasi Google
  Future<void> _handleGoogleSignIn() async {
    setState(() {
      _isGoogleLoading = true;
    });

    try {
      final supabase = ref.read(supabaseClientProvider);

      await supabase.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: 'io.supabase.pblkyu://login-callback/', 
      );
      
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menautkan akun Google: $e'),
            backgroundColor: AppColors.alertText,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isGoogleLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeControl.themeNotifier,
      builder: (context, currentMode, child) {
        bool isDark = currentMode == ThemeMode.dark;

        return Scaffold(
          backgroundColor: isDark ? AppDarkColors.background : AppColors.background,
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Kembali
                  Align(
                    alignment: Alignment.centerLeft,
                    child: GestureDetector(
                      onTap: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const OnboardingScreen(),
                          ),
                        );
                      },
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isDark ? AppDarkColors.surface : Colors.white,
                          border: Border.all(
                            color: isDark ? AppDarkColors.border : AppColors.border,
                            width: 1,
                          ),
                        ),
                        child: Icon(
                          Icons.arrow_back_rounded,
                          size: 20,
                          // Warna abu-abu redup selaras dengan teks sekunder / border form
                          color: isDark ? AppDarkColors.textSecondary : AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Logo Box Adaptif
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: isDark ? AppDarkColors.surface : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark ? AppDarkColors.border : AppColors.border, 
                        width: 0.5
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Image.asset(
                        'image/logoSemua.png',
                        width: 44,
                        height: 44,
                        errorBuilder: (context, error, stackTrace) => Icon(
                          Icons.business_center,
                          color: AppColors.primary,
                          size: 40,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Masuk',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: isDark ? AppDarkColors.textMain : AppColors.textMain,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Akses ruang kerja proyek Anda',
                    style: TextStyle(
                      fontSize: 14, 
                      color: isDark ? AppDarkColors.textSecondary : AppColors.textSecondary
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Peran Selector
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'PILIH PERAN',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isDark ? AppDarkColors.textSecondary : AppColors.textMain,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: isDark ? AppDarkColors.surface : const Color(0xFFEAEAEA),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => selectedRole = 'Manajer'),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: selectedRole == 'Manajer'
                                    ? (isDark ? Colors.white : AppColors.textMain)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Center(
                                child: Text(
                                  'Manajer',
                                  style: TextStyle(
                                    color: selectedRole == 'Manajer'
                                        ? (isDark ? AppDarkColors.background : Colors.white)
                                        : (isDark ? AppDarkColors.textSecondary : AppColors.textSecondary),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => selectedRole = 'Tim'),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: selectedRole == 'Tim'
                                    ? (isDark ? Colors.white : AppColors.textMain)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Center(
                                child: Text(
                                  'Tim',
                                  style: TextStyle(
                                    color: selectedRole == 'Tim'
                                        ? (isDark ? AppDarkColors.background : Colors.white)
                                        : (isDark ? AppDarkColors.textSecondary : AppColors.textSecondary),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Email Field
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'ALAMAT EMAIL',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isDark ? AppDarkColors.textSecondary : AppColors.textMain,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: isDark ? AppDarkColors.surface : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: isDark ? AppDarkColors.border : AppColors.border),
                    ),
                    child: TextField(
                      style: TextStyle(color: isDark ? AppDarkColors.textMain : AppColors.textMain),
                      decoration: InputDecoration(
                        hintText: 'name@organisasi.com',
                        hintStyle: TextStyle(
                          color: isDark ? AppDarkColors.textSecondary : AppColors.textSecondary,
                          fontSize: 14,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Password Field
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'KATA SANDI',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isDark ? AppDarkColors.textSecondary : AppColors.textMain,
                        ),
                      ),
                      Text(
                        'Lupa Kata Sandi?',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: isDark ? AppDarkColors.surface : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: isDark ? AppDarkColors.border : AppColors.border),
                    ),
                    child: TextField(
                      obscureText: true,
                      style: TextStyle(color: isDark ? AppDarkColors.textMain : AppColors.textMain),
                      decoration: InputDecoration(
                        hintText: '••••••••',
                        hintStyle: TextStyle(
                          color: isDark ? AppDarkColors.textSecondary : AppColors.textSecondary,
                          fontSize: 14,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Login Button Manual
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _handleLogin,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isDark ? Colors.white : AppColors.textMain,
                        foregroundColor: isDark ? AppDarkColors.background : Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Masuk',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Divider Pembatas "atau"
                  Row(
                    children: [
                      Expanded(child: Divider(color: isDark ? AppDarkColors.border : AppColors.border)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'atau',
                          style: TextStyle(
                            color: isDark ? AppDarkColors.textSecondary : AppColors.textSecondary, 
                            fontSize: 14
                          ),
                        ),
                      ),
                      Expanded(child: Divider(color: isDark ? AppDarkColors.border : AppColors.border)),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // OPSI SIGN-IN GOOGLE ADAPTIF
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: OutlinedButton.icon(
                      onPressed: _isGoogleLoading ? null : _handleGoogleSignIn,
                      icon: _isGoogleLoading 
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                          : Image.asset(
                              'image/google.png',
                              width: 20,
                              height: 20,
                              errorBuilder: (context, error, stackTrace) => Icon(
                                Icons.g_mobiledata_rounded, 
                                color: isDark ? Colors.white : AppColors.primary, 
                                size: 24
                              ),
                            ),
                      label: Text(
                        'Masuk dengan Google',
                        style: TextStyle(
                          color: isDark ? AppDarkColors.textMain : AppColors.textMain,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: isDark ? AppDarkColors.border : AppColors.border),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Register Link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Belum punya akun? ',
                        style: TextStyle(color: isDark ? AppDarkColors.textSecondary : AppColors.textSecondary),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const RegisterScreen(),
                            ),
                          );
                        },
                        child: const Text(
                          'Daftar',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Dots Indikator
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 8,
                        height: 4,
                        decoration: BoxDecoration(
                          color: isDark ? AppDarkColors.border : AppColors.border,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        width: 24,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        width: 8,
                        height: 4,
                        decoration: BoxDecoration(
                          color: isDark ? AppDarkColors.border : AppColors.border,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}