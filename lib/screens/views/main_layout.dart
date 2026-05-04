import 'package:flutter/material.dart';
import '../../widgets/app_bottom_nav.dart';
import 'manager_dashboard.dart';
import 'team_dashboard.dart';
import 'inbox_screen.dart';
import 'collab_view.dart';
import 'profile_view_manager.dart';
import 'profile_view_team.dart';

class MainLayout extends StatefulWidget {
  final String role;
  
  const MainLayout({super.key, required this.role});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _currentIndex = 0;

  late final List<Widget> _views;

  @override
  void initState() {
    super.initState();
    _views = [
      widget.role == 'Tim' ? const TeamDashboard() : const ManagerDashboard(), // Beranda
      const InboxScreen(),      // Kotak Masuk
      const CollabView(),       // Kolaborasi
      widget.role == 'Tim' ? const ProfileViewTeam() : const ProfileViewManager(), // Proyek/Profile
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _views,
      ),
      bottomNavigationBar: AppBottomNav(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }
}