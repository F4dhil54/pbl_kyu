import 'package:flutter/material.dart';
import '../../core/theme/colors.dart';

class AppBottomNav extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const AppBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  Widget _buildIcon(String assetPath, IconData fallbackIcon, bool isSelected) {
    return Image.asset(
      assetPath,
      width: 24,
      height: 24,
      color: isSelected ? AppColors.primary : AppColors.textSecondary,
      errorBuilder: (context, error, stackTrace) {
        // Fallback to standard Flutter icon if the image asset is not yet added
        return Icon(
          fallbackIcon,
          size: 24,
          color: isSelected ? AppColors.primary : AppColors.textSecondary,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border, width: 0.5)),
      ),
      child: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: onTap,
        backgroundColor: Colors.transparent,
        elevation: 0,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textSecondary,
        selectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 10,
        ),
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.normal,
          fontSize: 10,
        ),
        items: [
          BottomNavigationBarItem(
            icon: Padding(
              padding: const EdgeInsets.only(bottom: 4.0),
              child: _buildIcon(
                'image/ic_home.png',
                Icons.home_outlined,
                currentIndex == 0,
              ),
            ),
            activeIcon: Padding(
              padding: const EdgeInsets.only(bottom: 4.0),
              child: _buildIcon(
                'image/ic_home_filled.png',
                Icons.home,
                currentIndex == 0,
              ),
            ),
            label: 'Beranda',
          ),
          BottomNavigationBarItem(
            icon: Padding(
              padding: const EdgeInsets.only(bottom: 4.0),
              child: _buildIcon(
                'image/ic_inbox.png',
                Icons.inbox_outlined,
                currentIndex == 1,
              ),
            ),
            activeIcon: Padding(
              padding: const EdgeInsets.only(bottom: 4.0),
              child: _buildIcon(
                'image/ic_inbox_filled.png',
                Icons.inbox,
                currentIndex == 1,
              ),
            ),
            label: 'Kotak Masuk',
          ),
          BottomNavigationBarItem(
            icon: Padding(
              padding: const EdgeInsets.only(bottom: 4.0),
              child: _buildIcon(
                'image/ic_collab.png',
                Icons.people_outline,
                currentIndex == 2,
              ),
            ),
            activeIcon: Padding(
              padding: const EdgeInsets.only(bottom: 4.0),
              child: _buildIcon(
                'image/ic_collab_filled.png',
                Icons.people,
                currentIndex == 2,
              ),
            ),
            label: 'Kolaborasi',
          ),
          BottomNavigationBarItem(
            icon: Padding(
              padding: const EdgeInsets.only(bottom: 4.0),
              child: _buildIcon(
                'image/ic_project.png',
                Icons.assignment_outlined,
                currentIndex == 3,
              ),
            ),
            activeIcon: Padding(
              padding: const EdgeInsets.only(bottom: 4.0),
              child: _buildIcon(
                'image/ic_project_filled.png',
                Icons.assignment,
                currentIndex == 3,
              ),
            ),
            label: 'Proyek',
          ),
        ],
      ),
    );
  }
}
