import 'package:flutter/material.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/theme_mode.dart';
import 'package:pbl_kyu/shared/widgets/profile_avatar.dart';
import 'create_task_screen.dart';

class TaskDetailScreen extends StatelessWidget {
  const TaskDetailScreen({super.key});

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
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: isDark ? AppDarkColors.textMain : AppColors.textMain),
              onPressed: () => Navigator.pop(context),
            ),
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
                // Breadcrumb
                Row(
                  children: [
                    Text(
                      'Proyek: Q4 Brand Campaign',
                      style: TextStyle(fontSize: 12, color: isDark ? AppDarkColors.textSecondary : AppColors.textSecondary),
                    ),
                    const SizedBox(width: 8),
                    Icon(Icons.chevron_right, size: 14, color: isDark ? AppDarkColors.textMain : AppColors.textMain),
                    const SizedBox(width: 8),
                    Text(
                      'Daftar Tugas',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isDark ? AppDarkColors.textMain : AppColors.textMain),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Top Cards
                Row(
                  children: [
                    _buildInfoCard(isDark, 'MANAJER', 'Fadhil Syahidan', Icons.account_circle, const Color(0xFFE65100)),
                    const SizedBox(width: 16),
                    _buildInfoCard(isDark, 'TENGGAT WAKTU', '24 Okt 2023', Icons.calendar_today, AppColors.alertText),
                  ],
                ),
                const SizedBox(height: 24),

                // Tugas Content Card
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: isDark ? AppDarkColors.surface : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: isDark ? AppDarkColors.border : AppColors.border, width: 0.5),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.description_outlined, color: isDark ? AppDarkColors.textMain : AppColors.textMain, size: 20),
                          const SizedBox(width: 12),
                          Text('Tugas', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? AppDarkColors.textMain : AppColors.textMain)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Divider(color: isDark ? AppDarkColors.border : AppColors.border, height: 1),
                      const SizedBox(height: 20),
                      Text(
                        'Mohon fokus pada optimasi authentication layer di dalam middleware. Implementasi saat ini menyebabkan penundaan 200ms pada setiap request.',
                        style: TextStyle(fontSize: 14, color: isDark ? AppDarkColors.textMain : AppColors.textMain, height: 1.6),
                      ),
                      const SizedBox(height: 24),
                      _buildListItem(isDark, 'Migrasikan validasi JWT ke Redis edge cache.'),
                      _buildListItem(isDark, 'Pastikan semua respons error mengikuti skema baru.'),
                      _buildListItem(isDark, 'Perbarui dokumentasi di direktori /docs/api-internal.'),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
                const SizedBox(height: 80),
              ],
            ),
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const CreateTaskScreen(projectId: ""))),
            backgroundColor: isDark ? Colors.white : Colors.black,
            child: Icon(Icons.add, color: isDark ? Colors.black : Colors.white, size: 28),
          ),
        );
      },
    );
  }

  Widget _buildInfoCard(bool isDark, String label, String value, IconData icon, Color iconColor) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppDarkColors.surface : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isDark ? AppDarkColors.border : AppColors.border, width: 0.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isDark ? AppDarkColors.textSecondary : AppColors.textSecondary)),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(icon, color: iconColor, size: 20),
                const SizedBox(width: 8),
                Expanded(child: Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isDark ? AppDarkColors.textMain : AppColors.textMain))),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListItem(bool isDark, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 8.0, right: 12.0),
            child: CircleAvatar(radius: 2, backgroundColor: isDark ? AppDarkColors.textSecondary : AppColors.textSecondary),
          ),
          Expanded(child: Text(text, style: TextStyle(fontSize: 14, color: isDark ? AppDarkColors.textSecondary : AppColors.textSecondary, height: 1.5))),
        ],
      ),
    );
  }
}
