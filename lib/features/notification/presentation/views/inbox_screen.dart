import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/theme_mode.dart';
import 'package:pbl_kyu/shared/widgets/profile_avatar.dart';
import 'package:pbl_kyu/shared/widgets/app_sidebar.dart';
import '../../data/models/notification_model.dart';
import '../providers/notification_provider.dart';
import '../../../profile/presentation/providers/profile_provider.dart';
import 'message_detail_screen.dart' as message_detail;
import 'compose_message_screen.dart';

// Assuming we have these imports available for deep linking:
// import '../../project/presentation/views/project_detail_screen.dart';
// import '../../task/presentation/views/task_detail_screen.dart';

class InboxScreen extends ConsumerStatefulWidget {
  const InboxScreen({super.key});

  @override
  ConsumerState<InboxScreen> createState() => _InboxScreenState();
}

class _InboxScreenState extends ConsumerState<InboxScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Load data initially
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(notificationNotifierProvider.notifier).loadNotifications();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _formatNotificationTime(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date).inDays;
    final isToday = now.year == date.year && now.month == date.month && now.day == date.day;
    final isYesterday = now.subtract(const Duration(days: 1)).day == date.day && now.month == date.month;
    
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');

    if (isToday) {
      return '$hour:$minute';
    } else if (isYesterday) {
      return 'Kemarin $hour:$minute';
    } else if (difference >= 2 && difference <= 7) {
      // 3 to 7 days (difference of 2 days = 3rd day)
      final days = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];
      return '${days[date.weekday - 1]} $hour:$minute';
    } else {
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
      return '${date.day} ${months[date.month - 1]} ${date.year} $hour:$minute';
    }
  }

  void _handleNotificationTap(NotificationModel notif) async {
    // Mark as read
    if (!notif.isRead) {
      ref.read(notificationNotifierProvider.notifier).markAsRead(notif.id);
    }

    if (notif.tipeNotifikasi == 'pesan' || notif.tipeNotifikasi == 'mention' || notif.tipeNotifikasi == 'undangan') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => message_detail.MessageDetailScreen(
            notification: notif,
          ),
        ),
      );
    } else if (notif.tipeNotifikasi == 'proyek') {
      // Deep link to project
      // Navigator.push(context, MaterialPageRoute(builder: (context) => ProjectDetailScreen(projectId: notif.projectId)));
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Mengarahkan ke detail proyek...')));
    } else if (notif.tipeNotifikasi == 'tugas') {
      // Deep link to task
      // Navigator.push(context, MaterialPageRoute(builder: (context) => TaskDetailScreen(taskId: notif.taskId)));
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Mengarahkan ke detail tugas...')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final asyncNotifications = ref.watch(filteredNotificationsProvider);
    final currentFilter = ref.watch(notificationFilterProvider);

    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeControl.themeNotifier,
      builder: (context, currentMode, child) {
        bool isDark = currentMode == ThemeMode.dark;

        Widget buildTab(String text, NotificationFilter filter) {
          final isSelected = currentFilter == filter;
          Color selectedBg = isDark ? Colors.white : AppColors.textMain;
          Color unselectedBg = isDark ? AppDarkColors.surface : Colors.white;
          Color borderColor = isDark ? AppDarkColors.border : AppColors.border;

          return GestureDetector(
            onTap: () {
              ref.read(notificationFilterProvider.notifier).state = filter;
            },
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? selectedBg : unselectedBg,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? selectedBg : borderColor,
                ),
              ),
              child: Text(
                text,
                style: TextStyle(
                  color: isSelected 
                      ? (isDark ? AppDarkColors.background : Colors.white) 
                      : (isDark ? AppDarkColors.textSecondary : AppColors.textSecondary),
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          );
        }

        return Scaffold(
          backgroundColor: isDark ? AppDarkColors.background : AppColors.background,
          drawer: const AppSidebar(),
          floatingActionButton: FloatingActionButton(
            heroTag: 'inbox_screen_fab',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ComposeMessageScreen()),
              );
            },
            backgroundColor: AppColors.primary,
            child: const Icon(Icons.edit, color: Colors.white),
          ),
          appBar: AppBar(
            backgroundColor: isDark ? AppDarkColors.background : AppColors.background,
            elevation: 0,
            leading: Builder(
              builder: (context) => IconButton(
                icon: Icon(Icons.menu, color: isDark ? AppDarkColors.textMain : AppColors.textMain),
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
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Kotak Masuk',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: isDark ? AppDarkColors.textMain : AppColors.textMain,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white : AppColors.textMain,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: asyncNotifications.when(
                        data: (notifications) {
                          final unreadCount = notifications.where((n) => !n.isRead).length;
                          return Text(
                            '$unreadCount Baru',
                            style: TextStyle(
                              color: isDark ? AppDarkColors.background : Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          );
                        },
                        loading: () => const SizedBox(width: 10, height: 10, child: CircularProgressIndicator(strokeWidth: 2)),
                        error: (err, stack) => const Text('Error', style: TextStyle(color: Colors.red, fontSize: 10)),
                      ),
                    ),
                  ],
                ),
              ),

              // Search Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: TextField(
                  controller: _searchController,
                  onChanged: (value) {
                    ref.read(notificationSearchProvider.notifier).state = value;
                  },
                  style: TextStyle(color: isDark ? AppDarkColors.textMain : AppColors.textMain),
                  decoration: InputDecoration(
                    hintText: 'Cari pesan atau notifikasi...',
                    hintStyle: TextStyle(color: isDark ? AppDarkColors.textSecondary : AppColors.textSecondary),
                    prefixIcon: Icon(Icons.search, color: isDark ? AppDarkColors.textSecondary : AppColors.textSecondary),
                    filled: true,
                    fillColor: isDark ? AppDarkColors.surface : Colors.white,
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: isDark ? AppDarkColors.border : AppColors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: isDark ? AppDarkColors.border : AppColors.border),
                    ),
                  ),
                ),
              ),
              
              // Tabs Section
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  children: [
                    buildTab('Semua', NotificationFilter.semua),
                    buildTab('Belum Dibaca', NotificationFilter.belumDibaca),
                    buildTab('Mention & Pesan', NotificationFilter.mention),
                    buildTab('Tugas & Proyek', NotificationFilter.tugas),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              // Notification List
              Expanded(
                child: asyncNotifications.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (err, stack) => Center(child: Text('Error: $err', style: TextStyle(color: AppColors.alertText))),
                  data: (notifications) {
                    if (notifications.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                color: isDark ? AppDarkColors.surface : const Color(0xFFEEEEEE),
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Icon(
                                  Icons.inbox, 
                                  color: isDark ? AppDarkColors.textSecondary : AppColors.textSecondary, 
                                  size: 28
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Tidak ada notifikasi',
                              style: TextStyle(
                                fontSize: 14,
                                color: isDark ? AppDarkColors.textSecondary : AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return RefreshIndicator(
                      onRefresh: () => ref.read(notificationNotifierProvider.notifier).loadNotifications(),
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(20, 10, 20, 80),
                        itemCount: notifications.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final notif = notifications[index];
                          
                          // Determine icon/color based on type
                          IconData iconData = Icons.notifications;
                          Color iconColor = AppColors.primary;
                          Color iconBgColor = isDark ? const Color(0xFF1E293B) : const Color(0xFFF0F4FF);
                          
                          bool isAccepted = notif.tipeNotifikasi == 'undangan' && notif.pesan == 'Undangan diterima!';
                          bool isRejected = notif.tipeNotifikasi == 'undangan' && notif.pesan == 'Undangan ditolak.';

                          if (notif.tipeNotifikasi == 'pesan' || notif.tipeNotifikasi == 'mention') {
                            iconData = Icons.chat_bubble_outline;
                            iconColor = AppColors.primary;
                          } else if (notif.tipeNotifikasi == 'tugas') {
                            iconData = Icons.assignment_outlined;
                            iconColor = isDark ? const Color(0xFF34D399) : AppColors.successText;
                            iconBgColor = isDark ? const Color(0xFF064E3B) : const Color(0xFFE8F5E9);
                          } else if (notif.tipeNotifikasi == 'proyek') {
                            iconData = Icons.folder_open;
                            iconColor = Colors.orange;
                            iconBgColor = isDark ? const Color(0xFF422006) : const Color(0xFFFFF7ED);
                          } else if (notif.tipeNotifikasi == 'kudos') {
                            iconData = Icons.star_border;
                            iconColor = Colors.amber;
                            iconBgColor = isDark ? const Color(0xFF422006) : const Color(0xFFFFFBEB);
                          } else if (isAccepted) {
                            iconData = Icons.check_circle_outline;
                            iconColor = AppColors.successText;
                            iconBgColor = isDark ? const Color(0xFF064E3B) : const Color(0xFFE8F5E9);
                          } else if (isRejected) {
                            iconData = Icons.cancel_outlined;
                            iconColor = AppColors.alertText;
                            iconBgColor = isDark ? const Color(0xFF7F1D1D) : const Color(0xFFFFEBEB);
                          }

                          Color notifBgColor = isAccepted 
                              ? (isDark ? AppColors.successText.withValues(alpha: 0.15) : AppColors.successBackground)
                              : (isRejected 
                                  ? (isDark ? AppColors.alertText.withValues(alpha: 0.15) : const Color(0xFFFFEBEB))
                                  : (notif.isRead 
                                      ? (isDark ? AppDarkColors.background : Colors.white)
                                      : (isDark ? AppDarkColors.surface : AppColors.inputBackground)));

                          return GestureDetector(
                            onTap: () => _handleNotificationTap(notif),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: notifBgColor,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isAccepted 
                                      ? AppColors.successText.withValues(alpha: 0.3)
                                      : (isRejected 
                                          ? AppColors.alertText.withValues(alpha: 0.3) 
                                          : (isDark ? AppDarkColors.border : AppColors.border)), 
                                  width: 0.5
                                ),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (notif.senderAvatar != null && notif.senderAvatar!.isNotEmpty)
                                    CircleAvatar(
                                      radius: 20,
                                      backgroundImage: NetworkImage(notif.senderAvatar!),
                                    )
                                  else
                                    Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: iconBgColor,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Center(
                                        child: Icon(iconData, color: iconColor, size: 20),
                                      ),
                                    ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Expanded(
                                              child: Text(
                                                notif.judul,
                                                style: TextStyle(
                                                  fontSize: 14, 
                                                  color: isDark ? AppDarkColors.textMain : AppColors.textMain, 
                                                  fontWeight: notif.isRead ? FontWeight.normal : FontWeight.bold
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              _formatNotificationTime(notif.createdAt),
                                              style: TextStyle(
                                                  fontSize: 10, 
                                                  color: isDark ? AppDarkColors.textSecondary : AppColors.textSecondary
                                              ),
                                            ),
                                            if (!notif.isRead) ...[
                                              const SizedBox(width: 6),
                                              Container(
                                                width: 8,
                                                height: 8,
                                                margin: const EdgeInsets.only(top: 2),
                                                decoration: const BoxDecoration(
                                                  color: AppColors.primary,
                                                  shape: BoxShape.circle,
                                                ),
                                              ),
                                            ]
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        Builder(
                                          builder: (context) {
                                            String displayPesan = notif.pesan;
                                            if (notif.tipeNotifikasi == 'undangan' && notif.senderName != null && !isAccepted && !isRejected) {
                                              displayPesan = displayPesan.replaceAll('Anda telah diundang', '${notif.senderName} mengundang Anda');
                                            }
                                            return Text(
                                              displayPesan,
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                fontSize: 13,
                                                color: notif.isRead 
                                                    ? (isDark ? AppDarkColors.textSecondary : AppColors.textSecondary)
                                                    : (isDark ? AppDarkColors.textMain : AppColors.textMain),
                                                height: 1.4,
                                              ),
                                            );
                                          }
                                        ),
                                        if (notif.projectName != null && notif.projectName!.isNotEmpty) ...[
                                          const SizedBox(height: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: isDark ? AppDarkColors.surface : AppColors.inputBackground,
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              notif.projectName!,
                                              style: TextStyle(
                                                color: isDark ? AppDarkColors.textSecondary : AppColors.textSecondary,
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ],
                                        if (notif.tipeNotifikasi == 'undangan' && !isAccepted && !isRejected) ...[
                                          const SizedBox(height: 12),
                                          Row(
                                            children: [
                                              Expanded(
                                                child: ElevatedButton(
                                                  onPressed: () async {
                                                    if (notif.senderId != null) {
                                                      try {
                                                        await ref.read(profileRepositoryProvider).respondToInvitation(notif.senderId!, notif.userId, 'aktif');
                                                        if (context.mounted) {
                                                          await ref.read(notificationNotifierProvider.notifier).updateNotificationStatus(notif.id, 'Undangan diterima!');
                                                          if (context.mounted) {
                                                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Undangan diterima!')));
                                                          }
                                                        }
                                                      } catch (e) {
                                                        if (context.mounted) {
                                                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal menerima undangan: $e')));
                                                        }
                                                      }
                                                    } else {
                                                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gagal: ID pengirim tidak ditemukan.')));
                                                    }
                                                  },
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor: AppColors.successText,
                                                    padding: const EdgeInsets.symmetric(vertical: 8),
                                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                                  ),
                                                  child: const Text('Terima', style: TextStyle(color: Colors.white, fontSize: 12)),
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: OutlinedButton(
                                                  onPressed: () async {
                                                    if (notif.senderId != null) {
                                                      try {
                                                        await ref.read(profileRepositoryProvider).rejectInvitation(notif.senderId!, notif.userId);
                                                        if (context.mounted) {
                                                          await ref.read(notificationNotifierProvider.notifier).updateNotificationStatus(notif.id, 'Undangan ditolak.');
                                                          if (context.mounted) {
                                                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Undangan ditolak.')));
                                                          }
                                                        }
                                                      } catch (e) {
                                                        if (context.mounted) {
                                                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal menolak undangan: $e')));
                                                        }
                                                      }
                                                    } else {
                                                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gagal: ID pengirim tidak ditemukan.')));
                                                    }
                                                  },
                                                  style: OutlinedButton.styleFrom(
                                                    padding: const EdgeInsets.symmetric(vertical: 8),
                                                    side: const BorderSide(color: Colors.red),
                                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                                  ),
                                                  child: const Text('Tolak', style: TextStyle(color: Colors.red, fontSize: 12)),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
