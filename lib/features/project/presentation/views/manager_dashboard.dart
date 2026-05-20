import 'package:flutter/material.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/theme_mode.dart';
import '../../../profile/presentation/views/profile_view_manager.dart';
import '../../../profile/presentation/views/all_members_screen.dart';
import 'create_project_screen.dart';

class ManagerDashboard extends StatelessWidget {
  const ManagerDashboard({super.key});

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
              Padding(
                padding: const EdgeInsets.only(right: 20.0),
                child: GestureDetector(
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
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Selamat datang kembali,\nManajer',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppDarkColors.textMain : AppColors.textMain,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Berikut adalah ringkasan singkat status proyek\ntim Anda hari ini.',
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? AppDarkColors.textSecondary : AppColors.textSecondary,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 24),

                // Progress Tim Card
                Container(
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
                          Text(
                            'Progress Tim',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isDark ? AppDarkColors.textMain : AppColors.textMain,
                            ),
                          ),
                          Row(
                            children: [
                              _buildLegendDot(AppColors.primary, 'Selesai', isDark: isDark),
                              const SizedBox(width: 12),
                              _buildLegendDot(isDark ? AppDarkColors.border : const Color(0xFFD6E4FF), 'Tertunda', isDark: isDark),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      _buildProgressBar('UI/UX Sprint', 85, isDark: isDark),
                      const SizedBox(height: 16),
                      _buildProgressBar('Backend API Integration', 42, isDark: isDark),
                      const SizedBox(height: 16),
                      _buildProgressBar('Mobile App Alpha', 68, isDark: isDark),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Status Anggota Card
                Container(
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
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Status Anggota',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isDark ? AppDarkColors.textMain : AppColors.textMain,
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const AllMembersScreen(),
                                ),
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
                                Icon(
                                  Icons.chevron_right,
                                  size: 16,
                                  color: isDark ? Colors.amberAccent : AppColors.primary,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      _buildMemberStatus(
                        'Fadhil Syahidan',
                        'Lead Designer',
                        'Aktif',
                        AppColors.successText,
                        isDark ? AppColors.successText.withOpacity(0.15) : AppColors.successBackground,
                        isDark: isDark,
                      ),
                      Divider(height: 32, color: isDark ? AppDarkColors.border : AppColors.border),
                      _buildMemberStatus(
                        'Dea Marselia',
                        'Frontend Dev',
                        'Sedang Rapat',
                        AppColors.warningText,
                        isDark ? AppColors.warningText.withOpacity(0.15) : AppColors.warningBackground,
                        isDark: isDark,
                      ),
                      Divider(height: 32, color: isDark ? AppDarkColors.border : AppColors.border),
                      _buildMemberStatus(
                        'Sukma Ananda',
                        'DevOps Engineer',
                        'Offline',
                        AppColors.offlineText,
                        isDark ? AppColors.offlineText.withOpacity(0.15) : AppColors.offlineBackground,
                        isDark: isDark,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Notifikasi Cepat Card
                Container(
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
                      Text(
                        'Notifikasi Cepat',
                        style: TextStyle(
                          fontSize: 16, 
                          fontWeight: FontWeight.bold,
                          color: isDark ? AppDarkColors.textMain : AppColors.textMain,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Divider(height: 1, color: isDark ? AppDarkColors.border : AppColors.border),
                      const SizedBox(height: 20),

                      _buildNotificationItem(
                        'image/ic_commit.png',
                        Icons.commit,
                        AppColors.primary,
                        RichText(
                          text: TextSpan(
                            style: TextStyle(
                              fontSize: 14,
                              color: isDark ? AppDarkColors.textMain : AppColors.textMain,
                              height: 1.4,
                            ),
                            children: [
                              const TextSpan(
                                text: 'Dian Paramitha',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              const TextSpan(text: ' melakukan push 3 commit ke '),
                              TextSpan(
                                text: 'main',
                                style: TextStyle(
                                  backgroundColor: isDark ? AppDarkColors.background : const Color(0xFFF0F0F0),
                                  fontFamily: 'monospace',
                                ),
                              ),
                            ],
                          ),
                        ),
                        '2 mnt lalu',
                        isDark: isDark,
                      ),
                      const SizedBox(height: 24),

                      _buildNotificationItem(
                        'image/ic_check_circle.png',
                        Icons.check_circle_outline,
                        AppColors.successText,
                        RichText(
                          text: TextSpan(
                            style: TextStyle(
                              fontSize: 14,
                              color: isDark ? AppDarkColors.textMain : AppColors.textMain,
                              height: 1.4,
                            ),
                            children: const [
                              TextSpan(
                                text: 'Dea Marselia',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              TextSpan(
                                text: ' menandai Navigation Component telah selesai.',
                              ),
                            ],
                          ),
                        ),
                        '45 mnt lalu',
                        isDark: isDark,
                      ),
                      const SizedBox(height: 24),

                      _buildNotificationItem(
                        'image/ic_chat_bubble.png',
                        Icons.chat_bubble_outline,
                        AppColors.warningText,
                        RichText(
                          text: TextSpan(
                            style: TextStyle(
                              fontSize: 14,
                              color: isDark ? AppDarkColors.textMain : AppColors.textMain,
                              height: 1.4,
                            ),
                            children: const [
                              TextSpan(
                                text: 'Komentar baru pada Perencanaan Sprint #4 dari ',
                              ),
                              TextSpan(
                                text: 'Fadhil Syahidan.',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                        '1 jam lalu',
                        isDark: isDark,
                      ),
                      const SizedBox(height: 24),

                      _buildNotificationItem(
                        'image/ic_error.png',
                        Icons.error_outline,
                        AppColors.alertText,
                        RichText(
                          text: TextSpan(
                            style: TextStyle(
                              fontSize: 14,
                              color: isDark ? AppDarkColors.textMain : AppColors.textMain,
                              height: 1.4,
                            ),
                            children: const [
                              TextSpan(
                                text: 'Build ',
                                style: TextStyle(fontStyle: FontStyle.italic),
                              ),
                              TextSpan(text: 'gagal terdeteksi pada '),
                              TextSpan(
                                text: 'pipeline',
                                style: TextStyle(fontStyle: FontStyle.italic),
                              ),
                              TextSpan(
                                text: '\nAuth-Service.',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                        '3 jam lalu',
                        isDark: isDark,
                      ),

                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 40,
                        child: OutlinedButton(
                          onPressed: () {},
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: isDark ? AppDarkColors.border : const Color(0xFFE3E8FF)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                            'Tandai semua telah dibaca',
                            style: TextStyle(
                              color: isDark ? Colors.amberAccent : AppColors.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 80),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLegendDot(Color color, String text, {required bool isDark}) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          text,
          style: TextStyle(
            fontSize: 10,
            color: isDark ? AppDarkColors.textSecondary : AppColors.textSecondary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildProgressBar(String title, int percentage, {required bool isDark}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: isDark ? AppDarkColors.textSecondary : AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              '$percentage%',
              style: TextStyle(
                fontSize: 12, 
                fontWeight: FontWeight.bold,
                color: isDark ? AppDarkColors.textMain : AppColors.textMain,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Stack(
          children: [
            Container(
              height: 8,
              decoration: BoxDecoration(
                color: isDark ? AppDarkColors.border : const Color(0xFFF0F0F0),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            FractionallySizedBox(
              widthFactor: percentage / 100,
              child: Container(
                height: 8,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMemberStatus(
    String name,
    String role,
    String status,
    Color statusColor,
    Color statusBg,
    {required bool isDark}
  ) {
    return Row(
      children: [
        CircleAvatar(
          radius: 20,
          backgroundColor: Colors.transparent,
          child: Image.asset(
            'image/ic_avatar_${name.split(' ')[0].toLowerCase()}.png',
            errorBuilder: (context, error, stackTrace) =>
                Icon(Icons.account_circle, size: 40, color: statusColor),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: isDark ? AppDarkColors.textMain : AppColors.textMain,
                ),
              ),
              Text(
                role,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? AppDarkColors.textSecondary : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: statusBg,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: statusColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                status,
                style: TextStyle(
                  color: statusColor,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNotificationItem(
    String assetPath,
    IconData fallbackIcon,
    Color iconColor,
    Widget content,
    String time,
    {required bool isDark}
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Image.asset(
          assetPath,
          width: 20,
          height: 20,
          color: iconColor,
          errorBuilder: (context, error, stackTrace) =>
              Icon(fallbackIcon, size: 20, color: iconColor),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              content,
              const SizedBox(height: 4),
              Text(
                time,
                style: TextStyle(
                  fontSize: 10,
                  color: isDark ? AppDarkColors.textSecondary : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}