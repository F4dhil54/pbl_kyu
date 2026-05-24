import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pbl_kyu/core/theme/colors.dart';
import 'package:pbl_kyu/core/theme/theme_mode.dart';
import 'package:pbl_kyu/shared/providers/navigation_provider.dart';
import 'package:pbl_kyu/shared/widgets/profile_avatar.dart';
import 'package:pbl_kyu/features/auth/presentation/views/onboarding_screen.dart';
import 'package:pbl_kyu/features/auth/providers/auth_provider.dart';

class AppSidebar extends ConsumerWidget {
  const AppSidebar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = ref.watch(navigationIndexProvider);
    final user = Supabase.instance.client.auth.currentUser;
    final name = user?.userMetadata?['nama'] ??
                 user?.userMetadata?['name'] ??
                 user?.userMetadata?['full_name'] ??
                 'Pengguna';
    final role = user?.userMetadata?['role'] ?? 'Tim';

    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeControl.themeNotifier,
      builder: (context, currentMode, child) {
        final isDark = currentMode == ThemeMode.dark;
        final bgColor = isDark ? AppDarkColors.background : AppColors.surface;
        final activeColor = AppColors.primary;
        final inactiveColor = isDark ? AppDarkColors.textSecondary : AppColors.textSecondary;
        final textColor = isDark ? AppDarkColors.textMain : AppColors.textMain;

        return Drawer(
          backgroundColor: bgColor,
          child: SafeArea(
            child: Column(
              children: [
                // Drawer Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Image.asset(
                            'image/logoSemua.png',
                            width: 24,
                            height: 24,
                            errorBuilder: (context, error, stackTrace) => Icon(
                              Icons.business_center,
                              color: AppColors.primary,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'KYU',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: isDark ? Colors.white : const Color(0xFF1E3A8A),
                              letterSpacing: 1.5,
                            ),
                          ),
                          Text(
                            'Workspace',
                            style: TextStyle(
                              fontSize: 12,
                              color: inactiveColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Divider(
                  height: 1,
                  color: isDark ? AppDarkColors.border : AppColors.border,
                  thickness: 0.5,
                ),
                const SizedBox(height: 16),

                // Drawer Menu Items
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      _buildMenuItem(
                        context: context,
                        ref: ref,
                        index: 0,
                        title: 'Beranda',
                        icon: Icons.dashboard_rounded,
                        activeColor: activeColor,
                        inactiveColor: inactiveColor,
                        textColor: textColor,
                        isSelected: currentIndex == 0,
                      ),
                      const SizedBox(height: 8),
                      _buildMenuItem(
                        context: context,
                        ref: ref,
                        index: 1,
                        title: 'Kotak Masuk',
                        icon: Icons.mail_rounded,
                        activeColor: activeColor,
                        inactiveColor: inactiveColor,
                        textColor: textColor,
                        isSelected: currentIndex == 1,
                      ),
                      const SizedBox(height: 8),
                      _buildMenuItem(
                        context: context,
                        ref: ref,
                        index: 2,
                        title: 'Kolaborasi',
                        icon: Icons.people_alt_rounded,
                        activeColor: activeColor,
                        inactiveColor: inactiveColor,
                        textColor: textColor,
                        isSelected: currentIndex == 2,
                      ),
                      const SizedBox(height: 8),
                      _buildMenuItem(
                        context: context,
                        ref: ref,
                        index: 3,
                        title: 'Proyek',
                        icon: Icons.assignment_rounded,
                        activeColor: activeColor,
                        inactiveColor: inactiveColor,
                        textColor: textColor,
                        isSelected: currentIndex == 3,
                      ),
                    ],
                  ),
                ),

                // Theme Toggle & Profile Info
                Divider(
                  height: 1,
                  color: isDark ? AppDarkColors.border : AppColors.border,
                  thickness: 0.5,
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      // Mode Malam Toggler
                      ListTile(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        leading: Icon(
                          isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                          color: isDark ? Colors.amber : Colors.orange,
                        ),
                        title: Text(
                          'Mode Malam',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: textColor,
                          ),
                        ),
                        trailing: Switch.adaptive(
                          value: isDark,
                          activeTrackColor: AppColors.primary,
                          onChanged: (val) {
                            ThemeControl.toggleTheme();
                          },
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Profile Card
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppDarkColors.surface
                              : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isDark ? AppDarkColors.border : AppColors.border,
                            width: 0.5,
                          ),
                        ),
                        child: Row(
                          children: [
                            const ProfileAvatar(radius: 20),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: textColor,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: role == 'Manajer'
                                          ? const Color(0xFFFEF3C7)
                                          : const Color(0xFFE0F2FE),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      role,
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: role == 'Manajer'
                                            ? const Color(0xFFD97706)
                                            : const Color(0xFF0284C7),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              onPressed: () async {
                                final authController = ref.read(authControllerProvider);
                                await authController.signOut();
                                ref.read(navigationIndexProvider.notifier).state = 0;
                                if (context.mounted) {
                                  Navigator.pushAndRemoveUntil(
                                    context,
                                    MaterialPageRoute(builder: (context) => const OnboardingScreen()),
                                    (route) => false,
                                  );
                                }
                              },
                              icon: const Icon(
                                Icons.logout_rounded,
                                color: AppColors.alertText,
                                size: 20,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMenuItem({
    required BuildContext context,
    required WidgetRef ref,
    required int index,
    required String title,
    required IconData icon,
    required Color activeColor,
    required Color inactiveColor,
    required Color textColor,
    required bool isSelected,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isSelected ? activeColor.withValues(alpha: 0.08) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        leading: Icon(
          icon,
          color: isSelected ? activeColor : inactiveColor,
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
            color: isSelected ? activeColor : textColor,
          ),
        ),
        onTap: () {
          ref.read(navigationIndexProvider.notifier).state = index;
          Navigator.pop(context); // Close the drawer
        },
      ),
    );
  }
}
