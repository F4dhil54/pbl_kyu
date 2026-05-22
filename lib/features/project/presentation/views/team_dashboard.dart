import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/theme_mode.dart';
import 'package:pbl_kyu/shared/widgets/profile_avatar.dart';
import '../../../task/presentation/views/task_detail_team_screen.dart' as task_detail;
import '../../../task/presentation/views/team_task_list_screen.dart' as team_task_list;

class TeamDashboard extends StatelessWidget {
  const TeamDashboard({super.key});

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
              const ProfileAvatarButton(),
              const SizedBox(width: 20),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                StreamBuilder<AuthState>(
                  stream: Supabase.instance.client.auth.onAuthStateChange,
                  builder: (context, snapshot) {
                    final user = Supabase.instance.client.auth.currentUser;
                    final name = user?.userMetadata?['nama'] ??
                                 user?.userMetadata?['name'] ??
                                 user?.userMetadata?['full_name'] ??
                                 'Tim';
                    return Text(
                      'Selamat Datang, $name.',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: isDark ? AppDarkColors.textMain : AppColors.textMain,
                      ),
                    );
                  },
                ),
                const SizedBox(height: 4),
                Text(
                  'Fokus pada eksekusi hari ini.',
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? AppDarkColors.textSecondary : AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 24),

                // Tugas Saya Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Tugas Saya',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark ? AppDarkColors.textMain : AppColors.textMain,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const team_task_list.TeamTaskListScreen()),
                        );
                      },
                      child: Row(
                        children: [
                          Text(
                            'Lihat Semua',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? Colors.amberAccent : AppColors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Icon(Icons.chevron_right, size: 16, color: isDark ? Colors.amberAccent : AppColors.primary,),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Task List
                _buildTaskCard(
                  title: 'Finalisasi Proposal Proyek',
                  time: '09:00 - 11:00',
                  progress: 0.6,
                  isCompleted: false,
                  isDark: isDark,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const task_detail.TaskDetailTeamScreen()),
                    );
                  },
                ),
                const SizedBox(height: 12),
                _buildTaskCard(
                  title: 'Review Desain Sprint UI',
                  time: '13:30 - 15:00',
                  progress: 0.2,
                  isCompleted: false,
                  isDark: isDark,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const task_detail.TaskDetailTeamScreen()),
                    );
                  },
                ),
                const SizedBox(height: 12),
                _buildTaskCard(
                  title: 'Daily Standup Meeting',
                  time: 'Selesai',
                  progress: 1.0,
                  isCompleted: true,
                  isDark: isDark,
                ),
                const SizedBox(height: 40),

                // Quote Section
                Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.format_quote_rounded,
                        color: isDark ? AppDarkColors.border : const Color(0xFFD6E4FF),
                        size: 40,
                      ),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Text(
                          '"Kualitas bukan merupakan sebuah aksi, melainkan sebuah kebiasaan yang terus dilakukan secara konsisten."',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: isDark ? AppDarkColors.textMain : AppColors.textMain,
                            height: 1.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '— Aristotle',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.amberAccent : AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
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
    required String title,
    required String time,
    required double progress,
    required bool isCompleted,
    required bool isDark,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppDarkColors.surface : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isDark ? AppDarkColors.border : AppColors.border, width: 0.5),
          boxShadow: isDark ? null : [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: isCompleted ? AppColors.primary : (isDark ? AppDarkColors.background : Colors.white),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: isCompleted ? AppColors.primary : (isDark ? AppDarkColors.border : AppColors.border),
                  width: 2,
                ),
              ),
              child: isCompleted ? const Icon(Icons.check, size: 16, color: Colors.white) : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isCompleted 
                          ? (isDark ? AppDarkColors.textSecondary : AppColors.textSecondary) 
                          : (isDark ? AppDarkColors.textMain : AppColors.textMain),
                      decoration: isCompleted ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        isCompleted ? Icons.check_circle_outline : Icons.access_time,
                        size: 12,
                        color: isDark ? AppDarkColors.textSecondary : AppColors.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        time,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? AppDarkColors.textSecondary : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (!isCompleted)
              SizedBox(
                width: 48,
                height: 6,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: isDark ? AppDarkColors.border : AppColors.lightBlueSelection,
                    valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}