import 'package:flutter/material.dart';
import '../../../../shared/widgets/app_bottom_nav.dart';
import 'package:pbl_kyu/features/project/presentation/views/manager_dashboard.dart';
import 'package:pbl_kyu/features/project/presentation/views/project_list_screen.dart';
import 'package:pbl_kyu/features/project/presentation/views/team_dashboard.dart';
import 'package:pbl_kyu/features/task/presentation/views/team_task_list_screen.dart';
import 'package:pbl_kyu/features/notification/presentation/views/inbox_screen.dart';
import 'package:pbl_kyu/features/kudos/presentation/views/collab_view.dart';
//import 'package:pbl_kyu/features/profile/presentation/views/profile_view_manager.dart';
//import 'package:pbl_kyu/features/profile/presentation/views/profile_view_team.dart';

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
      widget.role == 'Tim' ? const TeamTaskListScreen() : const ProjectListScreen(), // Proyek
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