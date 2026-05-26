import 'dart:async'; // Tambahkan untuk StreamSubscription
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/theme_mode.dart';
import 'login_screen.dart';
import '../../../main_layout.dart'; // Tambahkan import MainLayout
import '../../../../core/network/supabase_provider.dart'; 
import '../../providers/auth_provider.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Key khusus untuk validasi peran saat Daftar dengan Google
  final _roleFieldKey = GlobalKey<FormFieldState<String>>();
  
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  String? selectedRole; 
  
  bool _isGoogleLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  // Flag untuk mendeteksi alur Google OAuth
  bool _isGoogleAuthFlowActive = false;
  StreamSubscription<AuthState>? _authStateSubscription;

  @override
  void initState() {
    super.initState();
    _nameController.clear();
    _emailController.clear();
    _passwordController.clear();
    _confirmPasswordController.clear();

    // Dengarkan perubahan sesi untuk menangani kembalinya pengguna dari halaman Google OAuth
    _authStateSubscription = ref.read(supabaseClientProvider).auth.onAuthStateChange.listen((data) async {
      final AuthChangeEvent event = data.event;
      final Session? session = data.session;

      if (event == AuthChangeEvent.signedIn && session != null) {
        // Arahkan langsung ke Beranda jika login dipicu oleh alur Google dan peran sudah dipilih
        if (mounted && selectedRole != null && _isGoogleAuthFlowActive) {
          _isGoogleAuthFlowActive = false;
          
          try {
            final supabase = ref.read(supabaseClientProvider);
            final response = await supabase
                .from('profiles')
                .select('role')
                .eq('id', session.user.id)
                .single();
            
            final dbRole = response['role'] as String? ?? '';
            
            if (!dbRole.contains(selectedRole!)) {
              final newRole = dbRole.isEmpty ? selectedRole! : '$dbRole, $selectedRole';
              await supabase.from('profiles').update({'role': newRole}).eq('id', session.user.id);
            }
            
            await supabase.auth.updateUser(UserAttributes(data: {'role': selectedRole}));
          } catch (e) {
            debugPrint('Gagal memperbarui peran pada daftar dengan Google: $e');
          }

          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => MainLayout(role: selectedRole!),
              ),
            );
          }
        }
      }
    });
  }

  @override
  void dispose() {
    _authStateSubscription?.cancel(); // Bersihkan listener
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // Logika pengiriman data registrasi ke Supabase dengan Email
  Future<void> _handleRegister() async {
    FocusScope.of(context).unfocus();

    // Validasi Form (Otomatis memvalidasi Nama, Email, Sandi, dan Peran)
    if (_formKey.currentState!.validate()) {
      final authController = ref.read(authControllerProvider);
      
      final success = await authController.registerWithEmail(
        context: context,
        email: _emailController.text.trim(),
        password: _passwordController.text,
        nama: _nameController.text.trim(),
        role: selectedRole!, 
      );

      // Jika registrasi sukses, kembalikan user ke halaman Login
      if (success && mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
    }
  }

  // Otorisasi Pendaftaran berbasis Google OAuth
  Future<void> _handleGoogleRegister() async {
    FocusScope.of(context).unfocus();

    // Hanya validasi kolom Peran
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
          _isGoogleAuthFlowActive = false;
        });
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
    final isAuthLoading = ref.watch(authLoadingProvider);
    final bool isDark = ThemeControl.themeNotifier.value == ThemeMode.dark;

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

                      // Nama Field
                      _buildFieldLabel('NAMA LENGKAP', isDark),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _nameController,
                        keyboardType: TextInputType.name,
                        textInputAction: TextInputAction.next,
                        autofillHints: const [AutofillHints.name],
                        enabled: !isAuthLoading && !_isGoogleLoading,
                        style: TextStyle(color: isDark ? AppDarkColors.textMain : AppColors.textMain),
                        decoration: _buildInputDecoration(
                          hint: 'Masukkan nama lengkap Anda',
                          fallbackIcon: Icons.person_outline_rounded,
                          isDark: isDark,
                          buildBorder: buildBorder,
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Nama lengkap tidak boleh kosong';
                          }
                          if (value.trim().length < 3) {
                            return 'Nama lengkap minimal berisi 3 karakter';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Email Field
                      _buildFieldLabel('ALAMAT EMAIL', isDark),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        autofillHints: const [AutofillHints.email],
                        enabled: !isAuthLoading && !_isGoogleLoading,
                        style: TextStyle(color: isDark ? AppDarkColors.textMain : AppColors.textMain),
                        decoration: _buildInputDecoration(
                          hint: 'nama@organisasi.com',
                          fallbackIcon: Icons.mail_outline_rounded,
                          isDark: isDark,
                          buildBorder: buildBorder,
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
                      const SizedBox(height: 16),

                      // Password Field
                      _buildFieldLabel('KATA SANDI', isDark),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        textInputAction: TextInputAction.next,
                        autofillHints: const [AutofillHints.newPassword],
                        enabled: !isAuthLoading && !_isGoogleLoading,
                        style: TextStyle(color: isDark ? AppDarkColors.textMain : AppColors.textMain),
                        decoration: _buildInputDecoration(
                          hint: '••••••••',
                          fallbackIcon: Icons.lock_outline_rounded,
                          isDark: isDark,
                          buildBorder: buildBorder,
                          suffix: IconButton(
                            icon: Icon(
                              _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                              color: isDark ? AppDarkColors.textSecondary : AppColors.textSecondary,
                              size: 20,
                            ),
                            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
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
                      const SizedBox(height: 16),

                      // Password Confirm Field
                      _buildFieldLabel('KONFIRMASI KATA SANDI', isDark),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _confirmPasswordController,
                        obscureText: _obscureConfirmPassword,
                        textInputAction: TextInputAction.done,
                        autofillHints: const [AutofillHints.newPassword],
                        onEditingComplete: _handleRegister, 
                        enabled: !isAuthLoading && !_isGoogleLoading,
                        style: TextStyle(color: isDark ? AppDarkColors.textMain : AppColors.textMain),
                        decoration: _buildInputDecoration(
                          hint: 'Ulangi kata sandi Anda',
                          fallbackIcon: Icons.sync_lock_rounded,
                          isDark: isDark,
                          buildBorder: buildBorder,
                          suffix: IconButton(
                            icon: Icon(
                              _obscureConfirmPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                              color: isDark ? AppDarkColors.textSecondary : AppColors.textSecondary,
                              size: 20,
                            ),
                            onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Konfirmasi kata sandi tidak boleh kosong';
                          }
                          if (value != _passwordController.text) {
                            return 'Kata sandi yang Anda masukkan tidak cocok';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),

                      // Peran Selektor
                      _buildFieldLabel('PILIH PERAN', isDark),
                      const SizedBox(height: 12),
                      FormField<String>(
                        key: _roleFieldKey, // Tambahkan Key untuk validasi mandiri
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
                                          padding: const EdgeInsets.symmetric(vertical: 14),
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
                                          padding: const EdgeInsets.symmetric(vertical: 14),
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
                      const SizedBox(height: 32),

                      // Registrasi Button
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: (isAuthLoading || _isGoogleLoading) ? null : _handleRegister,
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

                      // Opsi Sign-In Google OAuth
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: OutlinedButton.icon(
                          onPressed: (_isGoogleLoading || isAuthLoading) ? null : _handleGoogleRegister,
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
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),

                      // S&K dan Kebijakan Privasi
                      RichText(
                        textAlign: TextAlign.center,
                        text: TextSpan(
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? AppDarkColors.textSecondary : AppColors.textSecondary,
                            height: 1.5,
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

                      // Link Kembali ke Login Screen
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
                                MaterialPageRoute(builder: (context) => const LoginScreen()),
                              );
                            },
                            child: const Text(
                              'Masuk',
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
            ),
          ),
        );
  }

  Widget _buildFieldLabel(String label, bool isDark) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          fontSize: 12, 
          fontWeight: FontWeight.bold,
          color: isDark ? AppDarkColors.textSecondary : AppColors.textMain
        ),
      ),
    );
  }

  InputDecoration _buildInputDecoration({
    required String hint,
    required IconData fallbackIcon,
    required bool isDark,
    required OutlineInputBorder Function(Color, {double width}) buildBorder,
    Widget? suffix,
  }) {
    return InputDecoration(
      hintText: hint,
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
      suffixIcon: suffix,
    );
  }
}
