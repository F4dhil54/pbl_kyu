import 'package:flutter/material.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/theme_mode.dart';
import 'package:pbl_kyu/shared/widgets/profile_avatar.dart';
import 'task_detail_team_screen.dart' as task_detail;

class TeamTaskListScreen extends StatelessWidget {
  const TeamTaskListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeControl.themeNotifier,
      builder: (context, currentMode, child) {
        bool isDark = currentMode == ThemeMode.dark;

        return Scaffold(
          backgroundColor: isDark ? AppDarkColors.background : AppColors.background,
          appBar: AppBar(
            backgroundColor: isDark ? AppDarkColors.background : AppColors.background,
            elevation: 0,
            title: Text(
              'KYU',
              style: TextStyle(
                color: isDark ? Colors.white : const Color(0xFF1E3A8A),
                fontWeight: FontWeight.w900,
                fontSize: 20,
                letterSpacing: 1,
              ),
            ),
            actions: [
              Image.asset(
                'image/ic_search.png',
                width: 24,
                color: isDark ? AppDarkColors.textSecondary : AppColors.textSecondary,
                errorBuilder: (context, error, stackTrace) => Icon(
                  Icons.search, 
                  color: isDark ? AppDarkColors.textSecondary : AppColors.textSecondary
                ),
              ),
              const SizedBox(width: 16),
              const ProfileAvatarButton(),
              const SizedBox(width: 20),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Daftar Tugas',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppDarkColors.textMain : AppColors.textMain,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Text(
                      'Tugas Prioritas',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark ? AppDarkColors.textMain : AppColors.textMain,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppColors.alertText, // Red dot tetap merah di kedua mode
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Task Card 1
                _buildTaskCard(
                  isDark: isDark,
                  badgeText: 'Sedang Dikerjakan',
                  badgeColor: isDark ? const Color(0xFF115E59) : const Color(0xFFCCFBF1), // Teal gelap vs Teal terang
                  badgeTextColor: isDark ? const Color(0xFF99F6E4) : const Color(0xFF0F766E),
                  title: 'Projek Q4 Brand',
                  description: 'Mengintegrasikan komponen bento grid untuk\nvisualisasi data proyek utama. Melibatkan\nsistem kampanye digital untuk meningkatkan\nawareness dan engagement pelanggan.',
                  dateIcon: Icons.calendar_today_outlined,
                  dateText: '24 Okt 2026',
                  dateColor: isDark ? AppDarkColors.textSecondary : AppColors.textSecondary,
                  topRightIcon: Icons.more_vert,
                  bottomRightWidget: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white : const Color(0xFF020617), // Putih di mode gelap, Navy pekat di terang
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.close, 
                      color: isDark ? AppDarkColors.background : Colors.white, 
                      size: 14
                    ),
                  ),
                  leftBorderColor: isDark ? Colors.white : const Color(0xFF020617),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const task_detail.TaskDetailTeamScreen()),
                    );
                  },
                ),
                const SizedBox(height: 16),

                // Task Card 2
                _buildTaskCard(
                  isDark: isDark,
                  badgeText: 'Belum Selesai',
                  badgeColor: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9), // Abu-abu gelap vs terang
                  badgeTextColor: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
                  title: 'Migrasi Cloud Fase 2',
                  description: 'Memastikan sinkronisasi endpoint untuk fitur\nkolaborasi tim.',
                  dateIcon: Icons.history,
                  dateText: 'Besok',
                  dateColor: AppColors.alertText, // Tetap merah peringatan
                  topRightIcon: Icons.bookmark_border,
                  bottomRightWidget: null,
                ),
                const SizedBox(height: 16),

                // Task Card 3
                _buildTaskCard(
                  isDark: isDark,
                  badgeText: 'Sedang Dikerjakan',
                  badgeColor: isDark ? const Color(0xFF115E59) : const Color(0xFFCCFBF1),
                  badgeTextColor: isDark ? const Color(0xFF99F6E4) : const Color(0xFF0F766E),
                  title: 'Persiapan Audit Tahunan',
                  description: 'Optimasi query untuk laporan performa anggota\nbulanan.',
                  dateIcon: Icons.calendar_today_outlined,
                  dateText: '28 Okt  2026',
                  dateColor: isDark ? AppDarkColors.textSecondary : AppColors.textSecondary,
                  topRightIcon: Icons.more_vert,
                  bottomRightWidget: null,
                  leftBorderColor: isDark ? Colors.white : const Color(0xFF020617),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTaskCard({
    required bool isDark,
    required String badgeText,
    required Color badgeColor,
    required Color badgeTextColor,
    required String title,
    required String description,
    required IconData dateIcon,
    required String dateText,
    required Color dateColor,
    required IconData topRightIcon,
    Widget? bottomRightWidget,
    Color? leftBorderColor,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppDarkColors.surface : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? AppDarkColors.border : AppColors.border, 
            width: 0.5
          ),
          boxShadow: isDark 
              ? [] // Hilangkan bayangan hitam di mode gelap agar tidak kotor
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Container(
            decoration: BoxDecoration(
              border: leftBorderColor != null
                  ? Border(left: BorderSide(color: leftBorderColor, width: 4))
                  : null,
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: badgeColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        badgeText,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: badgeTextColor,
                        ),
                      ),
                    ),
                    Icon(
                      topRightIcon, 
                      color: isDark ? AppDarkColors.textSecondary : AppColors.textSecondary, 
                      size: 20
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppDarkColors.textMain : AppColors.textMain,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? AppDarkColors.textSecondary : AppColors.textSecondary,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(dateIcon, color: dateColor, size: 16),
                        const SizedBox(width: 8),
                        Text(
                          dateText,
                          style: TextStyle(
                            fontSize: 12,
                            color: dateColor,
                            fontWeight: dateColor == AppColors.alertText ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                    ?bottomRightWidget,
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}