import 'dart:async'; // Tambahkan untuk StreamSubscription
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/theme/colors.dart';
import '../../../../core/theme/theme_mode.dart';
import '../../../../core/network/supabase_provider.dart';
import 'package:pbl_kyu/features/auth/providers/auth_provider.dart';

import 'register_screen.dart';
import 'onboarding_screen.dart';
import 'forgot_password_screen.dart';
import '../../../main_layout.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Key khusus untuk memvalidasi peran secara terpisah saat Google Sign-In
  final _roleFieldKey = GlobalKey<FormFieldState<String>>(); 
  
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  String? selectedRole; 
  
  bool _isGoogleLoading = false;
  bool _obscurePassword = true;
  
  // Flag untuk mendeteksi apakah kita sedang menunggu alur Google Sign-In
  bool _isGoogleAuthFlowActive = false; 
  StreamSubscription<AuthState>? _authStateSubscription;

  @override
  void initState() {
    super.initState();
    _emailController.clear();
    _passwordController.clear();

    // Dengarkan perubahan sesi untuk menangani kembalinya pengguna dari halaman Google OAuth
    _authStateSubscription = ref.read(supabaseClientProvider).auth.onAuthStateChange.listen((data) {
      final AuthChangeEvent event = data.event;
      final Session? session = data.session;

      if (event == AuthChangeEvent.signedIn && session != null) {
        // Hanya arahkan langsung jika login dipicu oleh alur Google dan peran sudah dipilih
        if (mounted && selectedRole != null && _isGoogleAuthFlowActive) {
          _isGoogleAuthFlowActive = false;
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => MainLayout(role: selectedRole!),
            ),
          );
        }
      }
    });
  }

  @override
  void dispose() {
    _authStateSubscription?.cancel(); // Bersihkan listener saat halaman ditutup
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Fungsi penanganan login dengan validasi formulir dan integrasi Supabase
  Future<void> _handleLogin() async {
    FocusScope.of(context).unfocus();

    // Validasi Form (Otomatis akan memvalidasi Peran, Email, dan Password sekaligus)
    if (_formKey.currentState!.validate()) {
      final authController = ref.read(authControllerProvider);
      
      final success = await authController.loginWithEmail(
        context: context,
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      // Jika login sukses, arahkan ke halaman Layout Utama sesuai Role
      if (success && mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => MainLayout(role: selectedRole!),
          ),
        );
      }
    }
  }

  // Otorisasi Google Sign-In via OAuth
  Future<void> _handleGoogleSignIn() async {
    FocusScope.of(context).unfocus();

    // Hanya validasi kolom Peran. Jika email/password kosong, mereka tidak akan di-highlight merah
    if (!(_roleFieldKey.currentState?.validate() ?? false)) {
      return;
    }

    setState(() {
      _isGoogleLoading = true;
      _isGoogleAuthFlowActive = true; // Tandai bahwa Google Auth sedang berjalan
    });

    try {
      final supabase = ref.read(supabaseClientProvider);
      await supabase.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: 'io.supabase.pblkyu://login-callback/',
      );
      // Pindah halaman akan ditangani oleh _authStateSubscription di initState
    } catch (e) {
      if (mounted) {
        setState(() {
          _isGoogleAuthFlowActive = false; // Reset jika terjadi kegagalan sebelum pindah
        });
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
    final isAuthLoading = ref.watch(authLoadingProvider);

    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeControl.themeNotifier,
      builder: (context, currentMode, child) {
        bool isDark = currentMode == ThemeMode.dark;

        OutlineInputBorder buildBorder(Color borderColor, {double width = 1.0}) {
          return OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: borderColor, width: width),
          );
        }

        return Scaffold(
          backgroundColor: isDark ? AppDarkColors.background : AppColors.background,
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: AutofillGroup(
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Tombol Kembali
                      Align(
                        alignment: Alignment.centerLeft,
                        child: GestureDetector(
                          onTap: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(builder: (context) => const OnboardingScreen()),
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
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: isDark ? AppDarkColors.surface : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isDark ? AppDarkColors.border : AppColors.border,
                            width: 0.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
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
                          color: isDark ? AppDarkColors.textSecondary : AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 40),

                      // Peran Selector (Dibungkus FormField untuk Validasi bersamaan)
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
                      FormField<String>(
                        key: _roleFieldKey, // Menggunakan key agar bisa divalidasi tersendiri oleh Google Sign In
                        validator: (value) {
                          if (selectedRole == null) {
                            return 'Peran harus dipilih terlebih dahulu';
                          }
                          return null;
                        },
                        builder: (FormFieldState<String> state) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: isDark ? AppDarkColors.surface : const Color(0xFFEAEAEA),
                                  borderRadius: BorderRadius.circular(12),
                                  // Garis tepi merah menyala jika error
                                  border: Border.all(
                                    color: state.hasError ? Colors.redAccent : Colors.transparent,
                                    width: 1.5,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: GestureDetector(
                                        onTap: () {
                                          setState(() => selectedRole = 'Manajer');
                                          state.didChange('Manajer');
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(vertical: 12),
                                          decoration: BoxDecoration(
                                            color: selectedRole == 'Manajer'
                                                ? (isDark ? Colors.white : AppColors.textMain)
                                                : Colors.transparent,
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(
                                              color: selectedRole == 'Manajer' 
                                                  ? Colors.transparent 
                                                  : (isDark ? Colors.white12 : Colors.black12),
                                              width: 0.5,
                                            ),
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
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: GestureDetector(
                                        onTap: () {
                                          setState(() => selectedRole = 'Tim');
                                          state.didChange('Tim');
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(vertical: 12),
                                          decoration: BoxDecoration(
                                            color: selectedRole == 'Tim'
                                                ? (isDark ? Colors.white : AppColors.textMain)
                                                : Colors.transparent,
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(
                                              color: selectedRole == 'Tim' 
                                                  ? Colors.transparent 
                                                  : (isDark ? Colors.white12 : Colors.black12),
                                              width: 0.5,
                                            ),
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
                              if (state.hasError)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8, left: 12),
                                  child: Text(
                                    state.errorText!,
                                    style: const TextStyle(color: Colors.redAccent, fontSize: 12),
                                  ),
                                ),
                            ],
                          );
                        },
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
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        autofillHints: const [AutofillHints.email],
                        enabled: !isAuthLoading && !_isGoogleLoading,
                        style: TextStyle(color: isDark ? AppDarkColors.textMain : AppColors.textMain),
                        decoration: InputDecoration(
                          hintText: 'name@organisasi.com',
                          hintStyle: TextStyle(
                            color: isDark ? AppDarkColors.textSecondary : AppColors.textSecondary,
                            fontSize: 14,
                          ),
                          filled: true,
                          fillColor: isDark ? AppDarkColors.surface : Colors.white,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          enabledBorder: buildBorder(isDark ? AppDarkColors.border : AppColors.border),
                          focusedBorder: buildBorder(AppColors.primary),
                          errorBorder: buildBorder(Colors.redAccent),
                          focusedErrorBorder: buildBorder(Colors.red, width: 1.5),
                          errorStyle: const TextStyle(color: Colors.redAccent, fontSize: 12),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Alamat email tidak boleh kosong';
                          }
                          final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                          if (!emailRegex.hasMatch(value.trim())) {
                            return 'Masukkan format email yang valid';
                          }
                          return null;
                        },
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
                          GestureDetector(
                            onTap: () {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(builder: (context) => const ForgotPasswordScreen()),
                              );
                            },
                            child: Text(
                              'Lupa Kata Sandi?',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.primary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        textInputAction: TextInputAction.done,
                        autofillHints: const [AutofillHints.password],
                        onEditingComplete: _handleLogin, 
                        enabled: !isAuthLoading && !_isGoogleLoading,
                        style: TextStyle(color: isDark ? AppDarkColors.textMain : AppColors.textMain),
                        decoration: InputDecoration(
                          hintText: '••••••••',
                          hintStyle: TextStyle(
                            color: isDark ? AppDarkColors.textSecondary : AppColors.textSecondary,
                            fontSize: 14,
                          ),
                          filled: true,
                          fillColor: isDark ? AppDarkColors.surface : Colors.white,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          enabledBorder: buildBorder(isDark ? AppDarkColors.border : AppColors.border),
                          focusedBorder: buildBorder(AppColors.primary),
                          errorBorder: buildBorder(Colors.redAccent),
                          focusedErrorBorder: buildBorder(Colors.red, width: 1.5),
                          errorStyle: const TextStyle(color: Colors.redAccent, fontSize: 12),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                              color: isDark ? AppDarkColors.textSecondary : AppColors.textSecondary,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Kata sandi tidak boleh kosong';
                          }
                          if (value.length < 6) {
                            return 'Kata sandi minimal berisi 6 karakter';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 32),

                      // Login Button
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: (isAuthLoading || _isGoogleLoading) ? null : _handleLogin,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isDark ? Colors.white : AppColors.textMain,
                            foregroundColor: isDark ? AppDarkColors.background : Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: isAuthLoading
                              ? SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      isDark ? Colors.black : Colors.white,
                                    ),
                                  ),
                                )
                              : const Text(
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
                                fontSize: 14,
                              ),
                            ),
                          ),
                          Expanded(child: Divider(color: isDark ? AppDarkColors.border : AppColors.border)),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Opsi Sign-In Google OAuth
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: OutlinedButton.icon(
                          onPressed: (_isGoogleLoading || isAuthLoading) ? null : _handleGoogleSignIn,
                          icon: _isGoogleLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : Image.asset(
                                  'image/google.png',
                                  width: 20,
                                  height: 20,
                                  errorBuilder: (context, error, stackTrace) => Icon(
                                    Icons.g_mobiledata_rounded,
                                    color: isDark ? Colors.white : AppColors.primary,
                                    size: 24,
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

                      // Link Pindah ke Register Screen
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Belum punya akun? ',
                            style: TextStyle(
                              color: isDark ? AppDarkColors.textSecondary : AppColors.textSecondary,
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(builder: (context) => const RegisterScreen()),
                              );
                            },
                            child: const Text(
                              'Daftar',
                              style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
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
            ),
          ),
        );
      },
    );
  }
}
