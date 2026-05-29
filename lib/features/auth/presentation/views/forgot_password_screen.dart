import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/theme/colors.dart';
import '../../providers/auth_provider.dart';
import 'login_screen.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _newPasswordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _newPasswordController.dispose();
    super.dispose();
  }

  // Eksekusi reset kata sandi langsung lewat provider (RPC Supabase)
  Future<void> _handleSubmit() async {
    if (_formKey.currentState!.validate()) {
      final authController = ref.read(authControllerProvider);
      
      final success = await authController.resetPasswordDirectly(
        context: context,
        email: _emailController.text.trim(),
        newPassword: _newPasswordController.text,
      );

      // Jika berhasil, kembalikan user secara otomatis ke halaman Login
      if (success && mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAuthLoading = ref.watch(authLoadingProvider);
    const bool isDark = false; // Patenkan mode terang untuk halaman Auth

    // Base styling border input adaptif konsisten dengan Kyu
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
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Tombol Kembali ke LoginScreen
                    Align(
                      alignment: Alignment.centerLeft,
                      child: GestureDetector(
                        onTap: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (context) => const LoginScreen()),
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

                    // Logo
                    Image.asset(
                      'image/logoSemua.png',
                      width: 64,
                      height: 64,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => Icon(
                        Icons.business_center,
                        color: AppColors.primary,
                        size: 64,
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    Text(
                      'Reset Kata Sandi',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: isDark ? AppDarkColors.textMain : AppColors.textMain,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Masukkan alamat email yang terdaftar beserta kata sandi baru Anda. Kata sandi lama akan langsung digantikan.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark ? AppDarkColors.textSecondary : AppColors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 40),

                    // Alamat Email
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
                      enabled: !isAuthLoading,
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

                    // Kata Sandi Baru
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'KATA SANDI BARU',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isDark ? AppDarkColors.textSecondary : AppColors.textMain,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _newPasswordController,
                      obscureText: _obscurePassword,
                      enabled: !isAuthLoading,
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

                    // Tombol Reset Kata Sandi
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: isAuthLoading ? null : _handleSubmit,
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
                                'Reset Kata Sandi',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        );
  }
}
