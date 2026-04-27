import 'package:flutter/material.dart';
import '../../widgets/app_bottom_nav.dart';
import 'manager_dashboard.dart';
import 'member_dashboard.dart';
import 'task_view_manager.dart';
import 'task_view_member.dart';
import 'collab_view.dart';
import 'profile_view_manager.dart';
import 'profile_view_member.dart';

class MainLayout extends StatefulWidget {
  final String role;
  
  const MainLayout({super.key, required this.role});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _currentIndex = 0;

  late final List<Widget> _managerViews;
  late final List<Widget> _memberViews;

  @override
  void initState() {
    super.initState();
    _managerViews = [
      const ManagerDashboard(), // We'll refactor this to not have a bottom nav
      const TaskViewManager(),
      const CollabView(),
      const ProfileViewManager(),
    ];
    
    _memberViews = [
      const MemberDashboard(), // We'll refactor this too
      const TaskViewMember(),
      const CollabView(),
      const ProfileViewMember(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final views = widget.role == 'Manager' ? _managerViews : _memberViews;

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: views,
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
