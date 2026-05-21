// lib/features/auth/providers/auth_provider.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pbl_kyu/core/network/supabase_provider.dart';

// 1. Notifier Modern untuk Status Loading
class AuthLoadingNotifier extends Notifier<bool> {
  @override
  bool build() => false; // Nilai awal default = false

  void setWith(bool value) {
    state = value;
  }
}

final authLoadingProvider = NotifierProvider<AuthLoadingNotifier, bool>(
  AuthLoadingNotifier.new,
);

// 2. Provider untuk Mengakses Controller Auth
final authControllerProvider = Provider((ref) => AuthController(ref));

class AuthController {
  final Ref _ref;
  AuthController(this._ref);

  SupabaseClient get _supabase => _ref.read(supabaseClientProvider);

  // Fungsi Registrasi Akun Baru
  Future<void> registerWithEmail({
    required BuildContext context,
    required String email,
    required String password,
    required String nama,
  }) async {
    _ref.read(authLoadingProvider.notifier).setWith(true);
    try {
      await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {'nama': nama},
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Registrasi Berhasil! Silakan Login.')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Registrasi Gagal: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      _ref.read(authLoadingProvider.notifier).setWith(false);
    }
  }

  // Fungsi Login Akun
  Future<void> loginWithEmail({
    required BuildContext context,
    required String email,
    required String password,
  }) async {
    _ref.read(authLoadingProvider.notifier).setWith(true);
    try {
      await _supabase.auth.signInWithPassword(email: email, password: password);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Login Gagal: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      _ref.read(authLoadingProvider.notifier).setWith(false);
    }
  }

  // Fungsi Keluar Sistem
  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }
}