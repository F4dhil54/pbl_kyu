import 'package:flutter/material.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/theme_mode.dart';

class AppBottomNav extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const AppBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  Widget _buildIcon(String assetPath, IconData fallbackIcon, bool isSelected, bool isDark) {
    // Menentukan warna ikon tidak aktif berdasarkan status tema
    final Color unselectedColor = isDark ? AppDarkColors.textSecondary : AppColors.textSecondary;

    return Image.asset(
      assetPath,
      width: 24,
      height: 24,
      color: isSelected ? AppColors.primary : unselectedColor,
      errorBuilder: (context, error, stackTrace) {
        // Fallback ke standar ikon material jika file aset gambar belum tersedia
        return Icon(
          fallbackIcon,
          size: 24,
          color: isSelected ? AppColors.primary : unselectedColor,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeControl.themeNotifier,
      builder: (context, currentMode, child) {
        bool isDark = currentMode == ThemeMode.dark;
        final Color unselectedColor = isDark ? AppDarkColors.textSecondary : AppColors.textSecondary;

        return Container(
          decoration: BoxDecoration(
            color: isDark ? AppDarkColors.surface : AppColors.surface,
            border: Border(
              top: BorderSide(
                color: isDark ? AppDarkColors.border : AppColors.border, 
                width: 0.5,
              ),
            ),
          ),
          child: BottomNavigationBar(
            currentIndex: currentIndex,
            onTap: onTap,
            backgroundColor: Colors.transparent,
            elevation: 0,
            type: BottomNavigationBarType.fixed,
            selectedItemColor: AppColors.primary,
            unselectedItemColor: unselectedColor,
            selectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 10,
              fontFamily: 'Inter',
            ),
            unselectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.normal,
              fontSize: 10,
              fontFamily: 'Inter',
            ),
            items: [
              BottomNavigationBarItem(
                icon: Padding(
                  padding: const EdgeInsets.only(bottom: 4.0),
                  child: _buildIcon(
                    'image/ic_home.png',
                    Icons.home_outlined,
                    currentIndex == 0,
                    isDark,
                  ),
                ),
                activeIcon: Padding(
                  padding: const EdgeInsets.only(bottom: 4.0),
                  child: _buildIcon(
                    'image/ic_home_filled.png',
                    Icons.home,
                    currentIndex == 0,
                    isDark,
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
                    isDark,
                  ),
                ),
                activeIcon: Padding(
                  padding: const EdgeInsets.only(bottom: 4.0),
                  child: _buildIcon(
                    'image/ic_inbox_filled.png',
                    Icons.inbox,
                    currentIndex == 1,
                    isDark,
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
                    isDark,
                  ),
                ),
                activeIcon: Padding(
                  padding: const EdgeInsets.only(bottom: 4.0),
                  child: _buildIcon(
                    'image/ic_collab_filled.png',
                    Icons.people,
                    currentIndex == 2,
                    isDark,
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
                    isDark,
                  ),
                ),
                activeIcon: Padding(
                  padding: const EdgeInsets.only(bottom: 4.0),
                  child: _buildIcon(
                    'image/ic_project_filled.png',
                    Icons.assignment,
                    currentIndex == 3,
                    isDark,
                  ),
                ),
                label: 'Proyek',
              ),
            ],
          ),
        );
      },
    );
  }
}
