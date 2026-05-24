import 'package:flutter/material.dart';
import 'package:pbl_kyu/features/auth/presentation/views/login_screen.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/theme_mode.dart';
import '../../../../shared/widgets/profile_menu.dart';

class MemberDashboard extends StatefulWidget {
  const MemberDashboard({super.key});

  @override
  State<MemberDashboard> createState() => _MemberDashboardState();
}

class _MemberDashboardState extends State<MemberDashboard> {

  void _handleLogout() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (Route<dynamic> route) => false,
    );
  }

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
                color: isDark ? Colors.white : AppColors.primary,
                fontWeight: FontWeight.bold,
                fontSize: 24,
              ),
            ),
            actions: [
              IconButton(
                icon: Icon(Icons.search, color: isDark ? AppDarkColors.textMain : AppColors.textMain),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Fitur pencarian akan segera hadir!'), duration: Duration(seconds: 2)),
                  );
                },
              ),
              ProfileMenu(
                onLogout: _handleLogout,
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'WORKSPACE / TEAM MEMBER',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppDarkColors.textSecondary : AppColors.textMain,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'My Daily Focus',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppDarkColors.textMain : AppColors.textMain,
                  ),
                ),
                const SizedBox(height: 24),

                // My Daily Today Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'My Daily Today',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark ? AppDarkColors.textMain : AppColors.textMain,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.pendingText.withValues(alpha: 0.2) : AppColors.pending,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Text(
                        '4 Pending',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: AppColors.pendingText,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Task List
                _buildTaskItem('HIGH PRIORITY', 'Aether-01', 'Finalize architectural\nSystem Design', true, isDark: isDark),
                const SizedBox(height: 12),
                _buildTaskItem('MEDIUM', 'Aether-04', 'Conduct Accessibility\nAudit On Main Dashboard', true, isDark: isDark),
                const SizedBox(height: 12),
                _buildTaskItem('EXECUTION', 'Internal-02', 'Finalize architectural\nSystem Design', true, isDark: isDark),
                const SizedBox(height: 12),
                _buildTaskItem('LOW', 'Growth-12', 'Team Knowledge\nSharing Session Prep', true, isDark: isDark),
                const SizedBox(height: 24),

                // Fokus Mode
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: isDark ? AppDarkColors.surface : AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: isDark ? Border.all(color: AppDarkColors.border) : null,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.timer, size: 32, color: isDark ? AppDarkColors.textMain : AppColors.textMain),
                          const SizedBox(width: 12),
                          Text(
                            'Fokus Mode',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isDark ? AppDarkColors.textMain : AppColors.textMain,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Silence all notification and commit to a single high-impact task for deep work',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? AppDarkColors.textSecondary : AppColors.textMain,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: isDark ? AppDarkColors.background : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: isDark ? Border.all(color: AppDarkColors.border) : Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.play_arrow, color: isDark ? AppDarkColors.textMain : AppColors.textMain),
                            const SizedBox(width: 8),
                            Text(
                              'Start Pomodoro Session\n(25 min)',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: isDark ? AppDarkColors.textMain : AppColors.textMain,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Daily Motivation
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: isDark ? AppDarkColors.surface : AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: isDark ? Border.all(color: AppDarkColors.border) : null,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(width: 40, height: 4, color: AppColors.success),
                          const SizedBox(width: 8),
                          Text(
                            'DAILY MOTIVATION',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: isDark ? AppDarkColors.textMain : AppColors.textMain,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '"The way to get started is to\nquit talking and begin doing."',
                        style: TextStyle(
                          fontStyle: FontStyle.italic,
                          fontSize: 16,
                          color: isDark ? AppDarkColors.textMain : AppColors.textMain,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Container(width: 20, height: 4, color: Colors.purple),
                          const SizedBox(width: 8),
                          Text(
                            'Walt Disney',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: isDark ? AppDarkColors.textMain : AppColors.textMain,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Week Status
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: isDark ? AppDarkColors.surface : AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: isDark ? Border.all(color: AppDarkColors.border) : null,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'WEEK STATUS',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: isDark ? AppDarkColors.textMain : AppColors.textMain,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            '82%',
                            style: TextStyle(
                              color: AppColors.success,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Stack(
                        children: [
                          Container(
                            height: 4,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: isDark ? AppDarkColors.border : AppColors.inputBackground,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          Container(
                            height: 4,
                            width: 250, 
                            decoration: BoxDecoration(
                              color: AppColors.success,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        "You've completed 12 tasks this week.\nKeep the momentum!",
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? AppDarkColors.textSecondary : AppColors.textMain,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTaskItem(String priority, String tag, String title, bool isChecked, {required bool isDark}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppDarkColors.surface : AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: isDark ? Border.all(color: AppDarkColors.border) : null,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Icon(Icons.check, color: Colors.white, size: 14),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isDark ? AppDarkColors.background : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: isDark ? AppDarkColors.border : AppColors.inputBackground),
                      ),
                      child: Text(
                        priority,
                        style: TextStyle(
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                          color: isDark ? AppDarkColors.textMain : AppColors.textMain,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      tag,
                      style: TextStyle(
                        fontSize: 10,
                        color: isDark ? AppDarkColors.textSecondary : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: isDark ? AppDarkColors.textMain : AppColors.textMain,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.more_vert, color: isDark ? AppDarkColors.textSecondary : AppColors.textMain),
        ],
      ),
    );
  }
}
