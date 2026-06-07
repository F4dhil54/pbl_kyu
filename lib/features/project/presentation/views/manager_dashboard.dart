import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pbl_kyu/features/project/presentation/providers/project_provider.dart';
import 'package:pbl_kyu/features/profile/presentation/providers/profile_provider.dart';
import 'package:pbl_kyu/features/notification/presentation/providers/notification_provider.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/theme_mode.dart';
import 'package:pbl_kyu/shared/widgets/profile_avatar.dart';
import 'package:pbl_kyu/shared/widgets/app_sidebar.dart';
import '../../../profile/presentation/views/all_members_screen.dart';

class ManagerDashboard extends ConsumerWidget {
  const ManagerDashboard({super.key});

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
            padding: const EdgeInsets.all(20.0),
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
                                 'Manajer';
                    return Text(
                      'Selamat Datang,\n$name',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: isDark ? AppDarkColors.textMain : AppColors.textMain,
                        height: 1.2,
                      ),
                    );
                  },
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

                // Kartu Progress Tim
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
                      Consumer(
                        builder: (context, ref, child) {
                          final projectsAsync = ref.watch(projectListProvider);
                          return projectsAsync.when(
                            data: (projects) {
                              final activeProjects = projects.where((p) => p.statusAktif).take(3).toList();
                              if (activeProjects.isEmpty) {
                                return Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  child: Text(
                                    'Belum ada proyek aktif.',
                                    style: TextStyle(color: isDark ? AppDarkColors.textSecondary : AppColors.textSecondary),
                                  ),
                                );
                              }
                              return Column(
                                children: activeProjects.map((p) {
                                  return Consumer(
                                    builder: (context, ref, child) {
                                      final progressAsync = ref.watch(projectRealProgressProvider(p.id));
                                      return progressAsync.when(
                                        data: (progress) => Padding(
                                          padding: const EdgeInsets.only(bottom: 16),
                                          child: _buildProgressBar(p.name, (progress * 100).toInt(), isDark: isDark),
                                        ),
                                        loading: () => const Padding(
                                          padding: EdgeInsets.only(bottom: 16),
                                          child: Center(child: CircularProgressIndicator()),
                                        ),
                                        error: (err, stack) => Padding(
                                          padding: const EdgeInsets.only(bottom: 16),
                                          child: _buildProgressBar(p.name, (p.progress * 100).toInt(), isDark: isDark),
                                        ),
                                      );
                                    },
                                  );
                                }).toList(),
                              );
                            },
                            loading: () => const Center(child: CircularProgressIndicator()),
                            error: (err, stack) => const SizedBox(),
                          );
                        }
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Kartu Status Anggota
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
                      const SizedBox(height: 20),
                      Consumer(
                        builder: (context, ref, child) {
                          final membersAsync = ref.watch(managerInvitationsProvider);
                          return membersAsync.when(
                            data: (members) {
                              final topMembers = members.take(3).toList();
                              if (topMembers.isEmpty) {
                                return Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 24),
                                  child: Text('Belum ada anggota.', style: TextStyle(color: isDark ? AppDarkColors.textSecondary : AppColors.textSecondary)),
                                );
                              }
                              return Column(
                                children: topMembers.asMap().entries.map((entry) {
                                  final idx = entry.key;
                                  final m = entry.value;
                                  
                                  String statusUI = 'Offline';
                                  Color colorText = AppColors.offlineText;
                                  Color colorBg = isDark ? AppColors.offlineText.withValues(alpha: 0.15) : AppColors.offlineBackground;
                                  
                                  if (m['status'] == 'aktif') {
                                    statusUI = 'Aktif';
                                    colorText = AppColors.successText;
                                    colorBg = isDark ? AppColors.successText.withValues(alpha: 0.15) : AppColors.successBackground;
                                  } else if (m['status'] == 'pending') {
                                    statusUI = 'Menunggu';
                                    colorText = AppColors.warningText;
                                    colorBg = isDark ? AppColors.warningText.withValues(alpha: 0.15) : AppColors.warningBackground;
                                  } else if (m['status'] == 'nonaktif') {
                                    statusUI = 'Nonaktif';
                                    colorText = AppColors.alertText;
                                    colorBg = isDark ? AppColors.alertText.withValues(alpha: 0.15) : const Color(0xFFFFEBEB);
                                  }

                                  return Column(
                                    children: [
                                      _buildMemberStatus(
                                        m['name'],
                                        m['role'],
                                        statusUI,
                                        colorText,
                                        colorBg,
                                        isDark: isDark,
                                      ),
                                      if (idx < topMembers.length - 1)
                                        Divider(height: 32, color: isDark ? AppDarkColors.border : AppColors.border),
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
                    ],
                  ),
                ),
                const SizedBox(height: 20),

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
            Expanded(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? AppDarkColors.textSecondary : AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(width: 12),
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
