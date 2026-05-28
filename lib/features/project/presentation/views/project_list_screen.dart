import 'package:flutter/material.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/theme_mode.dart';
import '../../../profile/presentation/views/profile_view_manager.dart';
import 'create_project_screen.dart';
import 'project_detail_screen.dart';

class ProjectListScreen extends StatelessWidget {
  const ProjectListScreen({super.key});

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
              IconButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Fitur pencarian akan segera hadir!'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
                icon: Icon(Icons.search, color: isDark ? AppDarkColors.textMain : AppColors.textMain),
              ),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ProfileViewManager(),
                    ),
                  );
                },
                child: CircleAvatar(
                  radius: 16,
                  backgroundColor: isDark ? AppDarkColors.surface : AppColors.inputBackground,
                  child: Image.asset(
                    'image/ic_profile.png',
                    width: 24,
                    errorBuilder: (context, error, stackTrace) => Icon(
                      Icons.person,
                      color: isDark ? AppDarkColors.textMain : AppColors.textMain,
                      size: 24,
                    ),
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
                Text(
                  'Proyek Aktif',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppDarkColors.textMain : AppColors.textMain,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Pantau progres dan kolaborasi tim pada 4\nmodul aktif Anda.',
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? AppDarkColors.textSecondary : AppColors.textSecondary,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 24),

                // Project 1
                _buildProjectCard(
                  context,
                  category: 'MARKETING',
                  categoryBgColor: isDark ? const Color(0xFF065F46).withOpacity(0.3) : const Color(0xFFD1FAE5),
                  categoryTextColor: isDark ? const Color(0xFF34D399) : const Color(0xFF065F46),
                  title: 'Kampanye Brand Q4',
                  progress: 0.75,
                  progressText: '75%',
                  progressColor: AppColors.primary,
                  date: '24 Okt',
                  avatars: [
                    'image/ic_avatar_1.png',
                    'image/ic_avatar_2.png',
                    'image/ic_avatar_3.png',
                  ],
                  extraAvatars: '+3',
                  isDark: isDark,
                ),
                const SizedBox(height: 16),

                // Project 2
                _buildProjectCard(
                  context,
                  category: 'IT INFRA',
                  categoryBgColor: isDark ? const Color(0xFF1E3A8A).withOpacity(0.4) : const Color(0xFF1E3A8A),
                  categoryTextColor: isDark ? Colors.blue[200]! : Colors.white,
                  title: 'Migrasi Cloud Fase 2',
                  progress: 0.32,
                  progressText: '32%',
                  progressColor: AppColors.primary,
                  date: '12 Nov',
                  avatars: ['image/ic_avatar_4.png'],
                  isDark: isDark,
                ),
                const SizedBox(height: 16),

                // Project 3
                _buildProjectCard(
                  context,
                  category: 'FINANCE',
                  categoryBgColor: isDark ? const Color(0xFF451A03).withOpacity(0.4) : const Color(0xFF451A03),
                  categoryTextColor: isDark ? Colors.orange[200]! : Colors.white,
                  title: 'Persiapan Audit Tahunan',
                  progress: 0.90,
                  progressText: '90%',
                  progressColor: AppColors.primary,
                  date: 'Minggu Depan',
                  avatars: ['image/ic_avatar_5.png', 'image/ic_avatar_6.png'],
                  isDark: isDark,
                ),
                const SizedBox(height: 16),

                // Project 4
                _buildProjectCard(
                  context,
                  category: 'OPERATIONS',
                  categoryBgColor: isDark ? const Color(0xFF78350F).withOpacity(0.4) : const Color(0xFF78350F),
                  categoryTextColor: isDark ? Colors.orange[300]! : Colors.white,
                  title: 'Optimasi Rantai Pasok',
                  progress: 0.55,
                  progressText: '55%',
                  progressColor: AppColors.primary,
                  date: '01 Des',
                  avatars: ['image/ic_avatar_7.png'],
                  isDark: isDark,
                ),
                const SizedBox(height: 80),
              ],
            ),
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CreateProjectScreen(),
                ),
              );
            },
            backgroundColor: isDark ? AppColors.primary : Colors.black,
            elevation: 4,
            shape: const CircleBorder(),
            child: const Icon(Icons.add, color: Colors.white, size: 28),
          ),
        );
      },
    );
  }

  Widget _buildProjectCard(
    BuildContext context, {
    required String category,
    required Color categoryBgColor,
    required Color categoryTextColor,
    required String title,
    required double progress,
    required String progressText,
    required Color progressColor,
    required String date,
    required List<String> avatars,
    String? extraAvatars,
    required bool isDark,
  }) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ProjectDetailScreen()),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? AppDarkColors.surface : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isDark ? AppDarkColors.border : AppColors.border, width: 0.5),
          boxShadow: isDark ? null : [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: categoryBgColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    category,
                    style: TextStyle(
                      color: categoryTextColor,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                ),
                Icon(
                  Icons.more_vert,
                  color: isDark ? AppDarkColors.textSecondary : AppColors.textSecondary,
                  size: 20,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? AppDarkColors.textMain : AppColors.textMain,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Progress',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? AppDarkColors.textSecondary : AppColors.textSecondary,
                  ),
                ),
                Text(
                  progressText,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppDarkColors.textMain : AppColors.textMain,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: isDark ? AppDarkColors.border : const Color(0xFFE2E8F0),
                valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                minHeight: 6,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Avatars
                Row(
                  children: [
                    for (int i = 0; i < avatars.length; i++)
                      Align(
                        widthFactor: 0.6,
                        child: CircleAvatar(
                          radius: 14,
                          backgroundColor: isDark ? AppDarkColors.surface : Colors.white,
                          child: CircleAvatar(
                            radius: 12,
                            backgroundColor: isDark ? AppDarkColors.background : AppColors.inputBackground,
                            child: Icon(
                              Icons.account_circle,
                              size: 24,
                              color: _getFallbackColor(i),
                            ),
                          ),
                        ),
                      ),
                    if (extraAvatars != null)
                      Align(
                        widthFactor: 0.6,
                        child: CircleAvatar(
                          radius: 14,
                          backgroundColor: isDark ? AppDarkColors.surface : Colors.white,
                          child: CircleAvatar(
                            radius: 12,
                            backgroundColor: isDark ? AppDarkColors.background : const Color(0xFFF1F5F9),
                            child: Text(
                              extraAvatars,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: isDark ? AppDarkColors.textSecondary : AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                // Date
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today_outlined,
                      size: 14,
                      color: isDark ? AppDarkColors.textSecondary : AppColors.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      date,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? AppDarkColors.textSecondary : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getFallbackColor(int index) {
    List<Color> colors = [
      Colors.orange,
      Colors.pink,
      Colors.blueGrey,
      Colors.amber,
      Colors.blue,
      Colors.red,
      Colors.green,
    ];
    return colors[index % colors.length];
  }
}