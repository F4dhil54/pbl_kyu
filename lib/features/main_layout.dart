import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pbl_kyu/features/project/presentation/views/manager_dashboard.dart';
import 'package:pbl_kyu/features/project/presentation/views/project_list_screen.dart';
import 'package:pbl_kyu/features/project/presentation/views/team_dashboard.dart';
import 'package:pbl_kyu/features/notification/presentation/views/inbox_screen.dart';
import 'package:pbl_kyu/features/kudos/presentation/views/collab_view.dart';
import 'package:pbl_kyu/shared/providers/navigation_provider.dart';

class MainLayout extends ConsumerWidget {
  final String role;
  
  const MainLayout({super.key, required this.role});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = ref.watch(navigationIndexProvider);

    final views = [
      role == 'Tim' ? const TeamDashboard() : const ManagerDashboard(), // Beranda
      const InboxScreen(),      // Kotak Masuk
      const CollabView(),       // Kolaborasi
      ProjectListScreen(role: role), // Proyek (for both Manajer and Tim)
    ];

    return Scaffold(
      body: IndexedStack(
        index: currentIndex,
        children: views,
      ),
    );
  }
}
