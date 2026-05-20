import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/theme_mode.dart';
import 'login_screen.dart';
import '../../../../core/network/supabase_provider.dart'; 

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  String selectedRole = 'Anggota Tim';
  bool _isGoogleLoading = false;

  Future<void> _handleGoogleRegister() async {
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
            content: Text('Gagal mendaftar dengan Google: $e'),
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
                            builder: (context) => const LoginScreen(),
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
                          color: isDark ? AppDarkColors.textSecondary : AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Logo Box Adaptif
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: isDark ? AppDarkColors.surface : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark ? AppDarkColors.border : AppColors.border,
                        width: 0.5,
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
                        width: 36,
                        height: 36,
                        errorBuilder: (context, error, stackTrace) => Icon(
                          Icons.business_center,
                          color: AppColors.primary,
                          size: 32,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Buat Akun',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: isDark ? AppDarkColors.textMain : AppColors.textMain,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Bergabunglah dengan komunitas untuk\nkeunggulan pembelajaran berbasis proyek.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? AppDarkColors.textSecondary : AppColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Form fields
                  _buildFieldLabel('Nama Lengkap', isDark),
                  _buildTextField(
                    'Masukkan nama lengkap Anda',
                    'image/ic_user.png',
                    Icons.person_outline,
                    isDark,
                  ),
                  const SizedBox(height: 16),

                  _buildFieldLabel('Alamat Email', isDark),
                  _buildTextField(
                    'nama@universitas.ac.id',
                    'image/ic_email.png',
                    Icons.mail_outline,
                    isDark,
                  ),
                  const SizedBox(height: 16),

                  _buildFieldLabel('Kata Sandi', isDark),
                  _buildTextField(
                    'Min. 8 karakter',
                    'image/ic_lock.png',
                    Icons.lock_outline,
                    isDark,
                    isPassword: true,
                  ),
                  const SizedBox(height: 16),

                  _buildFieldLabel('Konfirmasi Kata Sandi', isDark),
                  _buildTextField(
                    'Ulangi kata sandi Anda',
                    'image/ic_sync_lock.png',
                    Icons.sync_lock,
                    isDark,
                    isPassword: false,
                  ),
                  const SizedBox(height: 24),

                  _buildFieldLabel('Pilih Peran', isDark),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => selectedRole = 'Manajer'),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              color: selectedRole == 'Manajer' 
                                  ? (isDark ? Colors.white : AppColors.textMain) 
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: selectedRole == 'Manajer'
                                    ? (isDark ? Colors.white : AppColors.textMain)
                                    : (isDark ? AppDarkColors.border : AppColors.border),
                                width: 1,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                'Manajer',
                                style: TextStyle(
                                  color: selectedRole == 'Manajer'
                                      ? (isDark ? AppDarkColors.background : Colors.white)
                                      : (isDark ? AppDarkColors.textSecondary : AppColors.textMain),
                                  fontWeight: selectedRole == 'Manajer'
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => selectedRole = 'Anggota Tim'),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              color: selectedRole == 'Anggota Tim' 
                                  ? (isDark ? Colors.white : AppColors.textMain) 
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: selectedRole == 'Anggota Tim'
                                    ? (isDark ? Colors.white : AppColors.textMain)
                                    : (isDark ? AppDarkColors.border : AppColors.border),
                                width: 1,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                'Anggota Tim',
                                style: TextStyle(
                                  color: selectedRole == 'Anggota Tim'
                                      ? (isDark ? AppDarkColors.background : Colors.white)
                                      : (isDark ? AppDarkColors.textSecondary : AppColors.textMain),
                                  fontWeight: selectedRole == 'Anggota Tim'
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Register Button Manual
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const LoginScreen(),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isDark ? Colors.white : AppColors.textMain,
                        foregroundColor: isDark ? AppDarkColors.background : Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Daftar',
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

                  // OPSI SIGN-UP GOOGLE ADAPTIF
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: OutlinedButton.icon(
                      onPressed: _isGoogleLoading ? null : _handleGoogleRegister,
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
                        'Daftar dengan Google',
                        style: TextStyle(
                          color: isDark ? AppDarkColors.textMain : AppColors.textMain,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: isDark ? AppDarkColors.border : AppColors.border),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Terms & Privacy
                  RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? AppDarkColors.textSecondary : AppColors.textSecondary,
                        height: 1.5,
                        fontFamily: 'Inter',
                      ),
                      children: [
                        const TextSpan(text: 'Dengan mendaftar, Anda menyetujui '),
                        TextSpan(
                          text: 'Ketentuan\nLayanan',
                          style: TextStyle(
                            color: isDark ? AppDarkColors.textMain : AppColors.textMain,
                            decoration: TextDecoration.underline,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const TextSpan(text: ' dan '),
                        TextSpan(
                          text: 'Kebijakan Privasi',
                          style: TextStyle(
                            color: isDark ? AppDarkColors.textMain : AppColors.textMain,
                            decoration: TextDecoration.underline,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const TextSpan(text: ' kami.'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Login Link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Sudah punya akun? ',
                        style: TextStyle(color: isDark ? AppDarkColors.textSecondary : AppColors.textSecondary),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const LoginScreen(),
                            ),
                          );
                        },
                        child: const Text(
                          'Masuk',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Dots Indikator (Garis Panjang di Tengah)
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

  Widget _buildFieldLabel(String label, bool isDark) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8.0),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12, 
            fontWeight: FontWeight.w600,
            color: isDark ? AppDarkColors.textMain : AppColors.textMain
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
    String hint,
    String iconAsset,
    IconData fallbackIcon,
    bool isDark, {
    bool isPassword = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppDarkColors.surface : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: isDark ? AppDarkColors.border : AppColors.border),
      ),
      child: TextField(
        obscureText: isPassword,
        style: TextStyle(color: isDark ? AppDarkColors.textMain : AppColors.textMain),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(
            color: isDark ? AppDarkColors.textSecondary : AppColors.textSecondary,
            fontSize: 14,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
          prefixIcon: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Image.asset(
              iconAsset,
              width: 20,
              height: 20,
              color: isDark ? AppDarkColors.textSecondary : AppColors.textSecondary,
              errorBuilder: (context, error, stackTrace) => Icon(
                fallbackIcon, 
                size: 20, 
                color: isDark ? AppDarkColors.textSecondary : AppColors.textSecondary
              ),
            ),
          ),
          suffixIcon: isPassword
              ? Icon(
                  Icons.visibility_outlined,
                  color: isDark ? AppDarkColors.textSecondary : AppColors.textSecondary,
                  size: 20,
                )
              : null,
        ),
      ),
    );
  }
}