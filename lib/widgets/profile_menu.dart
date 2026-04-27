import 'package:flutter/material.dart';
import '../theme/colors.dart';

class ProfileMenu extends StatelessWidget {
  final VoidCallback onLogout;

  const ProfileMenu({
    super.key,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: const Icon(
        Icons.account_circle,
        color: AppColors.textSecondary,
        size: 32,
      ),
      offset: const Offset(0, 50),
      itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
        const PopupMenuItem<String>(
          value: 'profile',
          child: Row(
            children: [
              Icon(Icons.person, color: AppColors.textMain, size: 20),
              SizedBox(width: 12),
              Text(
                'Profile',
                style: TextStyle(
                  color: AppColors.textMain,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem<String>(
          value: 'logout',
          onTap: onLogout,
          child: const Row(
            children: [
              Icon(Icons.logout, color: Colors.red, size: 20),
              SizedBox(width: 12),
              Text(
                'Logout',
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
