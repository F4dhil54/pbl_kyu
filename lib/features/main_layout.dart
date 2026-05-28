import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:pbl_kyu/core/network/supabase_provider.dart';
import 'package:pbl_kyu/features/project/presentation/views/manager_dashboard.dart';
import 'package:pbl_kyu/features/project/presentation/views/project_list_screen.dart';
import 'package:pbl_kyu/features/project/presentation/views/team_dashboard.dart';
import 'package:pbl_kyu/features/notification/presentation/views/inbox_screen.dart';
import 'package:pbl_kyu/features/kudos/presentation/views/collab_view.dart';
import 'package:pbl_kyu/shared/providers/navigation_provider.dart';

class MainLayout extends ConsumerStatefulWidget {
  final String role;
  
  const MainLayout({super.key, required this.role});

  @override
  ConsumerState<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends ConsumerState<MainLayout> {
  @override
  void initState() {
    super.initState();
    _simpanTokenFCM();
  }

  Future<void> _simpanTokenFCM() async {
    try {
      // 1. Meminta izin notifikasi (diperlukan untuk iOS dan Android 13+)
      final messaging = FirebaseMessaging.instance;
      final settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      
      debugPrint('User granted permission: ${settings.authorizationStatus}');
      
      if (settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional) {
        // 2. Ambil token unik dari perangkat HP ini
        String? token = await messaging.getToken();
        
        if (token != null) {
          await _uploadTokenToSupabase(token);
        }

        // 3. Dengarkan jika token diperbarui
        messaging.onTokenRefresh.listen((newToken) async {
          if (mounted) {
            await _uploadTokenToSupabase(newToken);
          }
        });
      }
    } catch (e) {
      debugPrint("Gagal menginisialisasi atau menyimpan token FCM: $e");
    }
  }

  Future<void> _uploadTokenToSupabase(String token) async {
    final supabase = ref.read(supabaseClientProvider);
    final user = supabase.auth.currentUser;

    if (user != null) {
      // Simpan atau update ke tabel user_tokens di Supabase
      try {
        await supabase.from('user_tokens').upsert({
          'user_id': user.id,
          'fcm_token': token,
          'updated_at': DateTime.now().toIso8601String(),
        });
        debugPrint("Token FCM berhasil disimpan ke Supabase!");
      } catch (e) {
        debugPrint("Gagal mengunggah token FCM ke Supabase: $e");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = ref.watch(navigationIndexProvider);

    final views = [
      widget.role == 'Tim' ? const TeamDashboard() : const ManagerDashboard(), // Beranda
      const InboxScreen(),      // Kotak Masuk
      CollabView(role: widget.role),       // Kolaborasi
      ProjectListScreen(role: widget.role), // Proyek (for both Manajer and Tim)
    ];

    return Scaffold(
      body: IndexedStack(
        index: currentIndex,
        children: views,
      ),
    );
  }
}
