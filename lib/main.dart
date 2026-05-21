// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

// Import jalur bento grid yang sudah kita rapikan
import 'package:pbl_kyu/core/network/supabase_provider.dart';
import 'package:pbl_kyu/features/main_layout.dart';
import 'package:pbl_kyu/features/auth/presentation/views/login_screen.dart';

void main() async {
  try {
    // 1. Memastikan binding Flutter siap dengan OS HP
    WidgetsFlutterBinding.ensureInitialized();
    debugPrint("=== DEBUG: [1/4] Binding Flutter Berhasil ===");

    // 2. Memuat file rahasia .env
    await dotenv.load(fileName: ".env");
    debugPrint("=== DEBUG: [2/4] File .env Berhasil Dimuat ===");

    // 3. Mengaktifkan jembatan cloud Supabase
    await Supabase.initialize(
      url: dotenv.env['SUPABASE_URL'] ?? '',
      anonKey: dotenv.env['SUPABASE_ANON_KEY'] ?? '',
    );
    debugPrint("=== DEBUG: [3/4] Jembatan Supabase Berhasil Terhubung! ===");

    // 4. Menyalakan aplikasi di dalam ProviderScope (Wajib untuk Riverpod)
    debugPrint("=== DEBUG: [4/4] Menjalankan Aplikasi KYU ===");
    runApp(
      const ProviderScope(
        child: MyApp(),
      ),
    );
  } catch (e) {
    // Menangkap error jika ada kegagalan setup di langkah 1-3
    debugPrint("=== ERROR CRITICAL: Gagal memuat aplikasi -> $e ===");
  }
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Memantau status login pengguna secara realtime dari Supabase
    final authState = ref.watch(authStateChangesProvider);

    return MaterialApp(
      title: 'KYU App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1E3A8A)),
        useMaterial3: true,
      ),
      // Pintu Gerbang Otomatis Aplikasi
      home: authState.when(
        data: (authData) {
          // Jika Supabase mendeteksi ada sesi token login yang aktif di HP
          if (authData.session != null) {
            // Langsung lempar ke halaman utama (Sesi Peran default: 'Tim')
            return const MainLayout(role: 'Tim');
          }
          
          // Jika tidak ada sesi atau sudah logout, arahkan ke halaman Login
          return const LoginScreen();
        },
        // Tampilan layar loading berputar saat aplikasi sedang mengecek sesi token
        loading: () => const Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        ),
        // Tampilan jika terjadi eror koneksi internet internet saat cek sesi
        error: (error, stackTrace) => Scaffold(
          body: Center(
            child: Text('Terjadi Kesalahan Koneksi: $error'),
          ),
        ),
      ),
    );
  }
}