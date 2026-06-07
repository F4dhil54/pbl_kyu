import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/theme_mode.dart';
import 'package:pbl_kyu/shared/widgets/profile_avatar.dart';
import 'package:pbl_kyu/shared/widgets/app_sidebar.dart';
import '../../../task/presentation/views/team_task_list_screen.dart' as team_task_list;
import '../../../task/presentation/providers/task_provider.dart';
import '../../presentation/providers/project_provider.dart';
import '../../data/models/project_model.dart';
import 'project_detail_screen.dart';
import '../../../notification/presentation/providers/notification_provider.dart';

class TeamDashboard extends ConsumerWidget {
  const TeamDashboard({super.key});

  String _timeAgo(DateTime? date) {
    if (date == null) return '';
    final diff = DateTime.now().difference(date);
    if (diff.inDays > 0) return '${diff.inDays} hari lalu';
    if (diff.inHours > 0) return '${diff.inHours} jam lalu';
    if (diff.inMinutes > 0) return '${diff.inMinutes} mnt lalu';
    return 'baru saja';
  }


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
          drawer: const AppSidebar(),
          appBar: AppBar(
            backgroundColor: isDark ? AppDarkColors.background : AppColors.background,
            elevation: 0,
            leading: Builder(
              builder: (context) => IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () => Scaffold.of(context).openDrawer(),
              ),
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

                // Kartu Notifikasi
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: isDark ? AppDarkColors.surface : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: isDark ? AppDarkColors.border : AppColors.border, width: 0.5),
                    boxShadow: isDark ? null : [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.02),
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

                      Consumer(
                        builder: (context, ref, child) {
                          final notifsAsync = ref.watch(notificationNotifierProvider);
                          return notifsAsync.when(
                            data: (notifs) {
                              final unreadNotifs = notifs.where((n) => !n.isRead).toList();
                              final latest = unreadNotifs.take(3).toList();
                              if (latest.isEmpty) {
                                return Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 24),
                                  child: Text('Belum ada notifikasi baru.', style: TextStyle(color: isDark ? AppDarkColors.textSecondary : AppColors.textSecondary)),
                                );
                              }
                              return Column(
                                children: latest.asMap().entries.map((entry) {
                                  final idx = entry.key;
                                  final n = entry.value;
                                  
                                  String iconPath = 'image/ic_chat_bubble.png';
                                  IconData fallbackIcon = Icons.notifications;
                                  Color iconColor = AppColors.primary;
                                  
                                  if (n.judul.toLowerCase().contains('commit') || n.pesan.toLowerCase().contains('commit')) {
                                    iconPath = 'image/ic_commit.png';
                                    fallbackIcon = Icons.commit;
                                  } else if (n.judul.toLowerCase().contains('selesai') || n.pesan.toLowerCase().contains('selesai')) {
                                    iconPath = 'image/ic_check_circle.png';
                                    fallbackIcon = Icons.check_circle_outline;
                                    iconColor = AppColors.successText;
                                  } else if (n.judul.toLowerCase().contains('gagal') || n.judul.toLowerCase().contains('error') || n.pesan.toLowerCase().contains('gagal')) {
                                    iconPath = 'image/ic_error.png';
                                    fallbackIcon = Icons.error_outline;
                                    iconColor = AppColors.alertText;
                                  } else {
                                    iconPath = 'image/ic_chat_bubble.png';
                                    fallbackIcon = Icons.chat_bubble_outline;
                                    iconColor = AppColors.warningText;
                                  }

                                  return Column(
                                    children: [
                                      _buildNotificationItem(
                                        iconPath,
                                        fallbackIcon,
                                        iconColor,
                                        RichText(
                                          text: TextSpan(
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: isDark ? AppDarkColors.textMain : AppColors.textMain,
                                              height: 1.4,
                                            ),
                                            children: [
                                              TextSpan(
                                                text: '${n.judul}\n',
                                                style: const TextStyle(fontWeight: FontWeight.bold),
                                              ),
                                              TextSpan(
                                                text: n.pesan,
                                              ),
                                            ],
                                          ),
                                        ),
                                        _timeAgo(n.createdAt),
                                        isDark: isDark,
                                      ),
                                      if (idx < latest.length - 1)
                                        const SizedBox(height: 24),
                                    ],
                                  );
                                }).toList(),
                              );
                            },
                            loading: () => const Center(child: CircularProgressIndicator()),
                            error: (err, stack) => const SizedBox(),
                          );
                        },
                      ),

                      const SizedBox(height: 24),
                      Consumer(
                        builder: (context, ref, child) {
                          return SizedBox(
                            width: double.infinity,
                            height: 40,
                            child: OutlinedButton(
                              onPressed: () {
                                final notifsState = ref.read(notificationNotifierProvider);
                                if (notifsState.hasValue) {
                                  // Tandai semua notifikasi dibaca
                                  final unreadNotifs = notifsState.value!.where((n) => !n.isRead).toList();
                                  for (var n in unreadNotifs) {
                                    ref.read(notificationNotifierProvider.notifier).markAsRead(n.id);
                                  }
                                }
                              },
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
                          );
                        }
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Header Tugas Saya
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

                // Daftar Tugas
                myTasksAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (err, stack) => Text('Gagal memuat tugas: $err'),
                  data: (tasks) {
                    if (tasks.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        child: Center(
                          child: Text(
                            'Tidak ada tugas untuk diselesaikan.',
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
                      separatorBuilder: (context, index) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final task = tasks[index];
                        final isCompleted = task.statusTugas == 'Selesai';
                        
                        // Cari proyek terkait
                        ProjectModel? matchedProject;
                        projectsAsync.whenData((projectList) {
                          try {
                            matchedProject = projectList.firstWhere((p) => p.id == task.projectId);
                          } catch (_) {
                            // tidak ditemukan
                          }
                        });

                        // Format waktu
                        String timeText = 'Akan Dikerjakan';
                        if (isCompleted) {
                          timeText = 'Selesai';
                        } else if (task.deadlineDate != null) {
                          final deadline = task.deadlineDate!;
                          timeText = '${deadline.day} ${[
                            'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
                            'Jul', 'Ags', 'Sep', 'Okt', 'Nov', 'Des'
                          ][deadline.month - 1]} ${deadline.year}';
                        }

                        // Progress
                        double progressVal = 0.0;
                        if (isCompleted) {
                          progressVal = 1.0;
                        } else if (task.statusTugas == 'Sedang Dikerjakan') {
                          progressVal = 0.5;
                        } else if (task.statusTugas == 'Ditinjau') {
                          progressVal = 0.8;
                        } else if (task.statusTugas == 'Dijadwalkan') {
                          progressVal = 0.1;
                        }

                        return _buildTaskCard(
                          title: task.judulTugas,
                          time: timeText,
                          progress: progressVal,
                          isCompleted: isCompleted,
                          isDark: isDark,
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

                // Bagian Kutipan
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
              color: Colors.black.withValues(alpha: 0.02),
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
