import 'package:flutter/material.dart';
import '../../theme/colors.dart';
import 'profile_view_manager.dart';

class InboxScreen extends StatelessWidget {
  const InboxScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text(
          'KYU',
          style: TextStyle(
            color: Color(0xFF1E3A8A),
            fontWeight: FontWeight.w900,
            fontSize: 20,
            letterSpacing: 1,
          ),
        ),
        actions: [
          Image.asset(
            'image/ic_search.png',
            width: 24,
            errorBuilder: (context, error, stackTrace) => const Icon(Icons.search, color: AppColors.textSecondary),
          ),
          const SizedBox(width: 16),
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfileViewManager()),
              );
            },
            child: CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.inputBackground,
              child: Image.asset(
                'image/ic_profile.png',
                width: 24,
                errorBuilder: (context, error, stackTrace) => const Icon(Icons.person, color: AppColors.textMain, size: 24),
              ),
            ),
          ),
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
                  const Text(
                    'Kotak Masuk',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textMain,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.textMain,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      '12 Baru',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Tabs
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  _buildTab('Semua', true),
                  _buildTab('Belum Dibaca', false),
                  _buildTab('Mention', false),
                  _buildTab('Tenggat Waktu', false),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // HARI INI Divider
            _buildDateDivider('HARI INI'),
            const SizedBox(height: 16),

            // Today Notifications
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  _buildNotificationCard(
                    iconBgColor: const Color(0xFFF0F4FF),
                    iconAsset: 'image/ic_chat_blue.png',
                    fallbackIcon: Icons.chat_bubble_outline,
                    iconColor: AppColors.primary,
                    title: 'Dea Marselia',
                    subtitle: ' berkomentar pa',
                    time: '10:24 AM',
                    content: '"Saya telah memperbarui milestone untuk fase engineering. Beri tahu..."',
                    isUnread: true,
                  ),
                  const SizedBox(height: 12),
                  _buildNotificationCard(
                    iconBgColor: const Color(0xFFE8F5E9), // Light green
                    iconAsset: 'image/ic_clipboard_green.png',
                    fallbackIcon: Icons.assignment_outlined,
                    iconColor: AppColors.successText,
                    title: 'Tugas Baru Diberikan',
                    subtitle: '',
                    time: '08:15 AM',
                    content: 'Tinjau protokol keamanan untuk API V2',
                    badgeText: 'Prioritas Tinggi',
                    badgeColor: const Color(0xFFE0F2F1),
                    badgeTextColor: const Color(0xFF009688),
                    isUnread: true,
                  ),
                  const SizedBox(height: 12),
                  _buildNotificationCard(
                    iconBgColor: const Color(0xFFFFEBEE), // Light red
                    iconAsset: 'image/ic_alarm_red.png',
                    fallbackIcon: Icons.notifications_none,
                    iconColor: AppColors.alertText,
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
            _buildDateDivider('KEMARIN'),
            const SizedBox(height: 16),

            // Yesterday Notifications
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  _buildNotificationCard(
                    iconBgColor: const Color(0xFFF5F5F5), // Light grey
                    iconAsset: 'image/ic_document_grey.png',
                    fallbackIcon: Icons.description_outlined,
                    iconColor: AppColors.textSecondary,
                    title: 'Dian Paramitha',
                    subtitle: ' membagikan De',
                    time: 'Kemarin',
                    content: 'Dibagikan di #Project-Kyu',
                    isUnread: false,
                  ),
                  const SizedBox(height: 12),
                  _buildNotificationCard(
                    iconBgColor: const Color(0xFFF5F5F5), // Light grey
                    iconAsset: 'image/ic_chat_grey.png',
                    fallbackIcon: Icons.chat_bubble_outline,
                    iconColor: AppColors.textSecondary,
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
                    decoration: const BoxDecoration(
                      color: Color(0xFFEEEEEE),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Image.asset(
                        'image/ic_history.png',
                        width: 24,
                        errorBuilder: (context, error, stackTrace) => const Icon(Icons.history, color: AppColors.textSecondary, size: 28),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Anda sudah membaca semuanya!',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textMain,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Tidak ada notifikasi lama untuk ditampilkan.',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
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
  }

  Widget _buildTab(String text, bool isSelected) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.textMain : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isSelected ? AppColors.textMain : AppColors.border,
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: isSelected ? Colors.white : AppColors.textSecondary,
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }

  Widget _buildDateDivider(String date) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Text(
            date,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: AppColors.textSecondary,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(child: Divider(color: AppColors.border)),
        ],
      ),
    );
  }

  Widget _buildNotificationCard({
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
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 0.5),
        boxShadow: [
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
                          style: const TextStyle(fontSize: 12, color: AppColors.textMain, height: 1.4),
                          children: [
                            TextSpan(text: title, style: const TextStyle(fontWeight: FontWeight.bold)),
                            TextSpan(text: subtitle, style: const TextStyle(color: AppColors.textSecondary)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      time,
                      style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
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
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textMain,
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
    );
  }
}
