import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/theme_mode.dart';
import 'package:pbl_kyu/shared/widgets/profile_avatar.dart';
import '../providers/task_provider.dart';
import '../../../project/presentation/providers/project_provider.dart';
import '../../../project/data/models/project_model.dart';
import '../../../project/presentation/views/project_detail_screen.dart';

class TeamTaskListScreen extends ConsumerWidget {
  const TeamTaskListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final myTasksAsync = ref.watch(myTasksProvider);
    final projectsAsync = ref.watch(projectListProvider);

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
          body: RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(myTasksProvider);
              ref.invalidate(projectListProvider);
              await Future.delayed(const Duration(milliseconds: 500));
            },
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              physics: const AlwaysScrollableScrollPhysics(),
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
                      'Semua Tugas',
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
                        color: AppColors.primary, 
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                myTasksAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (err, stack) => Text('Gagal memuat tugas: $err'),
                  data: (tasks) {
                    if (tasks.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 40),
                        child: Center(
                          child: Text(
                            'Tidak ada tugas.',
                            style: TextStyle(
                              color: isDark ? AppDarkColors.textSecondary : AppColors.textSecondary,
                            ),
                          ),
                        ),
                      );
                    }
                    return ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: tasks.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 16),
                      itemBuilder: (context, index) {
                        final task = tasks[index];
                        final isCompleted = task.statusTugas == 'Selesai';
                        
                        ProjectModel? matchedProject;
                        projectsAsync.whenData((projectList) {
                          try {
                            matchedProject = projectList.firstWhere((p) => p.id == task.projectId);
                          } catch (_) {}
                        });

                        String dateText = 'Tidak ada tenggat';
                        Color dateColor = isDark ? AppDarkColors.textSecondary : AppColors.textSecondary;
                        if (isCompleted) {
                          dateText = 'Selesai';
                          dateColor = AppColors.successText;
                        } else if (task.deadlineDate != null) {
                          final deadline = task.deadlineDate!;
                          dateText = '${deadline.day} ${[
                            'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
                            'Jul', 'Ags', 'Sep', 'Okt', 'Nov', 'Des'
                          ][deadline.month - 1]} ${deadline.year}';
                          
                          // If deadline is passed and not completed
                          if (deadline.isBefore(DateTime.now()) && !isCompleted) {
                            dateColor = AppColors.alertText;
                          }
                        }

                        // Status styling
                        String badgeText = task.statusTugas;
                        Color badgeColor;
                        Color badgeTextColor;

                        if (isCompleted) {
                          badgeColor = isDark ? const Color(0xFF064E3B) : const Color(0xFFD1FAE5);
                          badgeTextColor = isDark ? const Color(0xFF6EE7B7) : const Color(0xFF047857);
                        } else if (task.statusTugas == 'Sedang Dikerjakan') {
                          badgeColor = isDark ? const Color(0xFF115E59) : const Color(0xFFCCFBF1);
                          badgeTextColor = isDark ? const Color(0xFF99F6E4) : const Color(0xFF0F766E);
                        } else {
                          // Draft, Akan Dikerjakan, Ditinjau, Dijadwalkan
                          badgeColor = isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9);
                          badgeTextColor = isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569);
                        }

                        return _buildTaskCard(
                          isDark: isDark,
                          badgeText: badgeText,
                          badgeColor: badgeColor,
                          badgeTextColor: badgeTextColor,
                          title: task.taskNumber != null ? '#${task.taskNumber} ${task.judulTugas}' : task.judulTugas,
                          description: task.deskripsiTugas.isNotEmpty ? task.deskripsiTugas : 'Tidak ada deskripsi',
                          dateIcon: isCompleted ? Icons.check_circle_outline : Icons.calendar_today_outlined,
                          dateText: dateText,
                          dateColor: dateColor,
                          topRightIcon: Icons.more_vert,
                          leftBorderColor: isDark ? Colors.white : const Color(0xFF020617),
                          onTap: () {
                            if (matchedProject != null) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ProjectDetailScreen(project: matchedProject!),
                                ),
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Proyek tidak ditemukan')),
                              );
                            }
                          },
                        );
                      },
                    );
                  },
                ),
                const SizedBox(height: 40),
              ],
            ),
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
                    color: Colors.black.withValues(alpha: 0.02),
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
