import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pbl_kyu/core/network/supabase_provider.dart';
import 'package:pbl_kyu/core/theme/theme_mode.dart';
import 'package:pbl_kyu/features/project/presentation/providers/project_provider.dart';
import 'package:pbl_kyu/features/profile/presentation/providers/profile_provider.dart';
import 'package:pbl_kyu/features/task/presentation/providers/task_provider.dart';
import 'package:pbl_kyu/features/notification/presentation/providers/notification_provider.dart';
import 'package:pbl_kyu/features/kudos/presentation/providers/kudos_provider.dart';

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
      if (e.message.toLowerCase().contains('already registered') || e.message.toLowerCase().contains('already exists')) {
        try {
          final response = await _supabase.auth.signInWithPassword(email: email, password: password);
          if (response.user != null) {
            final userId = response.user!.id;
            final profile = await _supabase.from('profiles').select('role').eq('id', userId).single();
            final dbRole = profile['role'] as String? ?? '';
            
            if (!dbRole.contains(role)) {
              final newRole = dbRole.isEmpty ? role : '$dbRole, $role';
              await _supabase.from('profiles').update({'role': newRole}).eq('id', userId);
            }
            
            await _supabase.auth.signOut();
            
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Peran berhasil ditambahkan ke akun Anda! Silakan Login.'),
                  backgroundColor: Colors.green,
                ),
              );
            }
            return true;
          }
        } catch (loginError) {
           if (context.mounted) {
             ScaffoldMessenger.of(context).showSnackBar(
               const SnackBar(
                 content: Text('Akun sudah terdaftar. Jika Anda ingin menambah peran, pastikan kata sandi yang Anda masukkan benar.'),
                 backgroundColor: Colors.red,
               ),
             );
           }
           return false;
        }
      }
      
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
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      if (response.user != null) {
        await ThemeControl.loadTheme(response.user!.id);
      }
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
    ThemeControl.resetTheme();

    // Flush/invalidate all active workspace providers to prevent cross-account cache leakage
    _ref.invalidate(projectListProvider);
    _ref.invalidate(projectSearchQueryProvider);
    _ref.invalidate(allProfilesProvider);
    _ref.invalidate(managerActiveColleaguesProvider);
    _ref.invalidate(managerTeamsProvider);
    _ref.invalidate(managerInvitationsProvider);
    _ref.invalidate(myTasksProvider);
    _ref.invalidate(taskFilterProvider);
    _ref.invalidate(collabActivitiesProvider);
    _ref.invalidate(kudosActionNotifierProvider);
    _ref.invalidate(notificationNotifierProvider);
    _ref.invalidate(notificationFilterProvider);
    _ref.invalidate(notificationSearchProvider);
  }
}
