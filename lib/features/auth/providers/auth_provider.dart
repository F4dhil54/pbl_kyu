import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pbl_kyu/core/network/supabase_provider.dart';

// Notifier Status Loading
class AuthLoadingNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void setWith(bool value) {
    state = value;
  }
}

final authLoadingProvider = NotifierProvider<AuthLoadingNotifier, bool>(
  AuthLoadingNotifier.new,
);

// Provider untuk mengakses Controller Auth
final authControllerProvider = Provider((ref) => AuthController(ref));

class AuthController {
  final Ref _ref;
  AuthController(this._ref);

  // Getter untuk memanggil Supabase Client
  SupabaseClient get _supabase => _ref.read(supabaseClientProvider);

  // Fungsi Registrasi Akun Baru
  Future<bool> registerWithEmail({
    required BuildContext context,
    required String email,
    required String password,
    required String nama,
    required String role,
  }) async {
    _ref.read(authLoadingProvider.notifier).setWith(true);
    try {
      await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {
          'nama': nama,
          'role': role,
        },
      );
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Registrasi Berhasil! Silakan cek email atau langsung Login.'),
            backgroundColor: Colors.green,
          ),
        );
      }
      return true;
    } on AuthException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Registrasi Gagal: ${e.message}'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return false;
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Terjadi kesalahan tidak terduga: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return false;
    } finally {
      _ref.read(authLoadingProvider.notifier).setWith(false);
    }
  }

  // Fungsi Login Akun
  Future<bool> loginWithEmail({
    required BuildContext context,
    required String email,
    required String password,
  }) async {
    _ref.read(authLoadingProvider.notifier).setWith(true);
    try {
      await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      return true;
    } on AuthException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Login Gagal: ${e.message}'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return false;
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Koneksi bermasalah: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return false;
    } finally {
      _ref.read(authLoadingProvider.notifier).setWith(false);
    }
  }

  // Fungsi Mengirimkan Tautan Pemulihan Kata Sandi ke Email User
  Future<bool> sendPasswordResetEmail({
    required BuildContext context,
    required String email,
  }) async {
    _ref.read(authLoadingProvider.notifier).setWith(true);
    try {
      await _supabase.auth.resetPasswordForEmail(
        email,
        redirectTo: 'io.supabase.pblkyu://reset-password/',
      );
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tautan pemulihan berhasil dikirim! Silakan periksa kotak masuk email Anda.'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 5),
          ),
        );
      }
      return true;
    } on AuthException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mengirim pemulihan: ${e.message}'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return false;
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Terjadi masalah koneksi: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return false;
    } finally {
      _ref.read(authLoadingProvider.notifier).setWith(false);
    }
  }

  // Fungsi Keluar Sistem
  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }
}