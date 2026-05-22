import 'package:flutter/material.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/theme_mode.dart';
import 'package:pbl_kyu/shared/widgets/profile_avatar.dart';
import 'message_detail_screen.dart' as message_detail;

class InboxScreen extends StatelessWidget {
  const InboxScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeControl.themeNotifier,
      builder: (context, currentMode, child) {
        bool isDark = currentMode == ThemeMode.dark;

        Widget buildTab(String text, bool isSelected) {
          Color selectedBg = isDark ? Colors.white : AppColors.textMain;
          Color unselectedBg = isDark ? AppDarkColors.surface : Colors.white;
          Color borderColor = isDark ? AppDarkColors.border : AppColors.border;

          return Container(
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
          );
        }

        Widget buildDateDivider(String date) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Text(
                  date,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppDarkColors.textSecondary : AppColors.textSecondary,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Divider(
                    color: isDark ? AppDarkColors.border : AppColors.border
                  ),
                ),
              ],
            ),
          );
        }

        Widget buildNotificationCard({
          required Color iconBgColor,
          required String iconAsset,
          required IconData fallbackIcon,
          required Color iconColor,
          required String title,
          required String subtitle,
          required String time,
          required String content,
          bool isUnread = false,
          String? badgeText,
          Color? badgeColor,
          Color? badgeTextColor,
          VoidCallback? onTap,
        }) {
          return GestureDetector(
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? AppDarkColors.surface : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? AppDarkColors.border : AppColors.border, 
                  width: 0.5
                ),
                boxShadow: isDark 
                    ? [] 
                    : [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.01),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: iconBgColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Image.asset(
                        iconAsset,
                        width: 20,
                        color: isDark ? Colors.white : null,
                        errorBuilder: (context, error, stackTrace) => Icon(fallbackIcon, color: iconColor, size: 20),
                      ),
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
                              child: RichText(
                                text: TextSpan(
                                  style: TextStyle(
                                    fontSize: 12, 
                                    color: isDark ? AppDarkColors.textMain : AppColors.textMain, 
                                    height: 1.4
                                  ),
                                  children: [
                                    TextSpan(text: title, style: const TextStyle(fontWeight: FontWeight.bold)),
                                    TextSpan(
                                      text: subtitle, 
                                      style: TextStyle(
                                        color: isDark ? AppDarkColors.textSecondary : AppColors.textSecondary
                                      )
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              time,
                              style: TextStyle(
                                fontSize: 10, 
                                color: isDark ? AppDarkColors.textSecondary : AppColors.textSecondary
                              ),
                            ),
                            if (isUnread) ...[
                              const SizedBox(width: 6),
                              Container(
                                width: 6,
                                height: 6,
                                margin: const EdgeInsets.only(top: 4),
                                decoration: const BoxDecoration(
                                  color: AppColors.primary,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ] else ...[
                              const SizedBox(width: 12),
                            ]
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          content,
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark ? AppDarkColors.textMain : AppColors.textMain,
                            height: 1.4,
                          ),
                        ),
                        if (badgeText != null) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: badgeColor,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              badgeText,
                              style: TextStyle(
                                color: badgeTextColor,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }

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
          body: SingleChildScrollView(
            child: Column(
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
                        child: Text(
                          '12 Baru',
                          style: TextStyle(
                            color: isDark ? AppDarkColors.background : Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Tabs Section
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      buildTab('Semua', true),
                      buildTab('Belum Dibaca', false),
                      buildTab('Mention', false),
                      buildTab('Tenggat Waktu', false),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // HARI INI Divider
                buildDateDivider('HARI INI'),
                const SizedBox(height: 16),

                // Today Notifications
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      buildNotificationCard(
                        iconBgColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF0F4FF),
                        iconAsset: 'image/ic_chat_blue.png',
                        fallbackIcon: Icons.chat_bubble_outline,
                        iconColor: AppColors.primary,
                        title: 'Dea Marselia',
                        subtitle: ' berkomentar pa',
                        time: '10:24 AM',
                        content: '"Saya telah memperbarui milestone untuk fase engineering. Beri tahu..."',
                        isUnread: true,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const message_detail.MessageDetailScreen(
                                senderName: 'Dea Marselia',
                                title: 'Pembaruan Milestone',
                                content: 'Saya telah memperbarui milestone untuk fase engineering. Beri tahu jika ada feedback tambahan.',
                                time: '10:24 AM',
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                      buildNotificationCard(
                        iconBgColor: isDark ? const Color(0xFF064E3B) : const Color(0xFFE8F5E9),
                        iconAsset: 'image/ic_clipboard_green.png',
                        fallbackIcon: Icons.assignment_outlined,
                        iconColor: isDark ? const Color(0xFF34D399) : AppColors.successText,
                        title: 'Tugas Baru Diberikan',
                        subtitle: '',
                        time: '08:15 AM',
                        content: 'Tinjau protokol keamanan untuk API V2',
                        badgeText: 'Prioritas Tinggi',
                        badgeColor: isDark ? const Color(0xFF115E59) : const Color(0xFFE0F2F1),
                        badgeTextColor: isDark ? const Color(0xFF2DD4BF) : const Color(0xFF009688),
                        isUnread: true,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const message_detail.MessageDetailScreen(
                                senderName: 'Sistem KYU',
                                title: 'Tugas Baru Diberikan',
                                content: 'Tinjau protokol keamanan untuk API V2 segera sebelum sprint berakhir.',
                                time: '08:15 AM',
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                      buildNotificationCard(
                        iconBgColor: isDark ? const Color(0xFF7F1D1D) : const Color(0xFFFFEBEE),
                        iconAsset: 'image/ic_alarm_red.png',
                        fallbackIcon: Icons.notifications_none,
                        iconColor: isDark ? const Color(0xFFFCA5A5) : AppColors.alertText,
                        title: 'Pengingat Tenggat Waktu',
                        subtitle: '',
                        time: '07:00 AM',
                        content: 'Proyek "Alpha Orion" Fase 1 jatuh tempo dalam 4 jam.',
                        isUnread: false,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // KEMARIN Divider
                buildDateDivider('KEMARIN'),
                const SizedBox(height: 16),

                // Yesterday Notifications
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      buildNotificationCard(
                        iconBgColor: isDark ? const Color(0xFF334155) : const Color(0xFFF5F5F5),
                        iconAsset: 'image/ic_document_grey.png',
                        fallbackIcon: Icons.description_outlined,
                        iconColor: isDark ? AppDarkColors.textSecondary : AppColors.textSecondary,
                        title: 'Dian Paramitha',
                        subtitle: ' membagikan De',
                        time: 'Kemarin',
                        content: 'Dibagikan di #Project-Kyu',
                        isUnread: false,
                      ),
                      const SizedBox(height: 12),
                      buildNotificationCard(
                        iconBgColor: isDark ? const Color(0xFF334155) : const Color(0xFFF5F5F5),
                        iconAsset: 'image/ic_chat_grey.png',
                        fallbackIcon: Icons.chat_bubble_outline,
                        iconColor: isDark ? AppDarkColors.textSecondary : AppColors.textSecondary,
                        title: 'Sukma Ananda',
                        subtitle: ' me-mention A',
                        time: 'Kemarin',
                        content: '"@User coba cek komponen baru ini"',
                        isUnread: false,
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 40),
                
                // Bottom Empty State
                Center(
                  child: Column(
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: isDark ? AppDarkColors.surface : const Color(0xFFEEEEEE),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Image.asset(
                            'image/ic_history.png',
                            width: 24,
                            color: isDark ? AppDarkColors.textSecondary : AppColors.textSecondary,
                            errorBuilder: (context, error, stackTrace) => Icon(
                              Icons.history, 
                              color: isDark ? AppDarkColors.textSecondary : AppColors.textSecondary, 
                              size: 28
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Anda sudah membaca semuanya!',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: isDark ? AppDarkColors.textMain : AppColors.textMain,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Tidak ada notifikasi lama untuk ditampilkan.',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? AppDarkColors.textSecondary : AppColors.textSecondary,
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
}