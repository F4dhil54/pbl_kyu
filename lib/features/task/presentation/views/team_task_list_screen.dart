import 'package:flutter/material.dart';
import '../../../../core/theme/colors.dart';
import '../../../profile/presentation/views/profile_view_team.dart';
import 'task_detail_team_screen.dart' as task_detail;

class TeamTaskListScreen extends StatelessWidget {
  const TeamTaskListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text(
          'KYU',
          style: TextStyle(
            color: Color(0xFF1E3A8A),
            fontWeight: FontWeight.w900,
            fontSize: 20,
            letterSpacing: 1,
          ),
        ),
        actions: [
          Image.asset(
            'image/ic_search.png',
            width: 24,
            errorBuilder: (context, error, stackTrace) => const Icon(Icons.search, color: AppColors.textSecondary),
          ),
          const SizedBox(width: 16),
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfileViewTeam()),
              );
            },
            child: CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.inputBackground,
              child: Image.asset(
                'image/ic_profile.png',
                width: 24,
                errorBuilder: (context, error, stackTrace) => const Icon(Icons.person, color: AppColors.textMain, size: 24),
              ),
            ),
          ),
          const SizedBox(width: 20),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Daftar Tugas',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.textMain,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                const Text(
                  'Tugas Prioritas',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textMain,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppColors.alertText, // Red dot
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Task Card 1
            _buildTaskCard(
              badgeText: 'Sedang Dikerjakan',
              badgeColor: const Color(0xFFCCFBF1), // Light teal
              badgeTextColor: const Color(0xFF0F766E), // Dark teal
              title: 'Projek Q4 Brand',
              description: 'Mengintegrasikan komponen bento grid untuk\nvisualisasi data proyek utama. Melibatkan\nsistem kampanye digital untuk meningkatkan\nawareness dan engagement pelanggan.',
              dateIcon: Icons.calendar_today_outlined,
              dateText: '24 Okt 2026',
              dateColor: AppColors.textSecondary,
              topRightIcon: Icons.more_vert,
              bottomRightWidget: Container(
                width: 24,
                height: 24,
                decoration: const BoxDecoration(
                  color: Color(0xFF020617), // Dark navy
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, color: Colors.white, size: 14),
              ),
              leftBorderColor: const Color(0xFF020617), // Dark navy border on left
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
              badgeText: 'Belum Selesai',
              badgeColor: const Color(0xFFF1F5F9), // Light grey
              badgeTextColor: const Color(0xFF475569), // Slate grey
              title: 'Migrasi Cloud Fase 2',
              description: 'Memastikan sinkronisasi endpoint untuk fitur\nkolaborasi tim.',
              dateIcon: Icons.history, // using history icon for 'Besok' as in image
              dateText: 'Besok',
              dateColor: AppColors.alertText, // Red text
              topRightIcon: Icons.bookmark_border,
              bottomRightWidget: null,
            ),
            const SizedBox(height: 16),

            // Task Card 3
            _buildTaskCard(
              badgeText: 'Sedang Dikerjakan',
              badgeColor: const Color(0xFFCCFBF1),
              badgeTextColor: const Color(0xFF0F766E),
              title: 'Persiapan Audit Tahunan',
              description: 'Optimasi query untuk laporan performa anggota\nbulanan.',
              dateIcon: Icons.calendar_today_outlined,
              dateText: '28 Okt  2026',
              dateColor: AppColors.textSecondary,
              topRightIcon: Icons.more_vert,
              bottomRightWidget: null,
              leftBorderColor: const Color(0xFF020617),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskCard({
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 0.5),
        boxShadow: [
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
                  Icon(topRightIcon, color: AppColors.textSecondary, size: 20),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textMain,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                description,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
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
                  if (bottomRightWidget != null) bottomRightWidget,
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
