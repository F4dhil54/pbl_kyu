import 'package:flutter/material.dart';
import '../../theme/colors.dart';
import 'profile_view_manager.dart';

class ManagerDashboard extends StatelessWidget {
  const ManagerDashboard({super.key});

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
            color: Color(0xFF1E3A8A), // Dark blue like the image
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
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Selamat datang kembali,\nManajer',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.textMain,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Berikut adalah ringkasan singkat status proyek\ntim Anda hari ini.',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),

            // Progress Tim Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border, width: 0.5),
                boxShadow: [
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
                      const Text(
                        'Progress Tim',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Row(
                        children: [
                          _buildLegendDot(AppColors.primary, 'Selesai'),
                          const SizedBox(width: 12),
                          _buildLegendDot(const Color(0xFFD6E4FF), 'Tertunda'),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _buildProgressBar('UI/UX Sprint', 85),
                  const SizedBox(height: 16),
                  _buildProgressBar('Backend API Integration', 42),
                  const SizedBox(height: 16),
                  _buildProgressBar('Mobile App Alpha', 68),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Status Anggota Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border, width: 0.5),
                boxShadow: [
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
                      const Text(
                        'Status Anggota',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Row(
                        children: [
                          Text(
                            'Lihat Semua',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Icon(Icons.chevron_right, size: 16, color: AppColors.primary),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _buildMemberStatus('Fadhil Syahidan', 'Lead Designer', 'Aktif', AppColors.successText, AppColors.successBackground),
                  const Divider(height: 32, color: AppColors.border),
                  _buildMemberStatus('Dea Marselia', 'Frontend Dev', 'Sedang Rapat', AppColors.warningText, AppColors.warningBackground),
                  const Divider(height: 32, color: AppColors.border),
                  _buildMemberStatus('Sukma Ananda', 'DevOps Engineer', 'Offline', AppColors.offlineText, AppColors.offlineBackground),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Notifikasi Cepat Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border, width: 0.5),
                boxShadow: [
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
                  const Text(
                    'Notifikasi Cepat',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Divider(height: 1, color: AppColors.border),
                  const SizedBox(height: 20),
                  
                  _buildNotificationItem(
                    'image/ic_commit.png', Icons.commit,
                    AppColors.primary,
                    RichText(
                      text: const TextSpan(
                        style: TextStyle(fontSize: 14, color: AppColors.textMain, height: 1.4),
                        children: [
                          TextSpan(text: 'Dian Paramitha', style: TextStyle(fontWeight: FontWeight.bold)),
                          TextSpan(text: ' melakukan push 3 commit ke '),
                          TextSpan(text: 'main', style: TextStyle(backgroundColor: Color(0xFFF0F0F0), fontFamily: 'monospace')),
                        ],
                      ),
                    ),
                    '2 mnt lalu',
                  ),
                  const SizedBox(height: 24),
                  
                  _buildNotificationItem(
                    'image/ic_check_circle.png', Icons.check_circle_outline,
                    AppColors.successText,
                    RichText(
                      text: const TextSpan(
                        style: TextStyle(fontSize: 14, color: AppColors.textMain, height: 1.4),
                        children: [
                          TextSpan(text: 'Dea Marselia', style: TextStyle(fontWeight: FontWeight.bold)),
                          TextSpan(text: ' menandai Navigation Component telah selesai.'),
                        ],
                      ),
                    ),
                    '45 mnt lalu',
                  ),
                  const SizedBox(height: 24),
                  
                  _buildNotificationItem(
                    'image/ic_chat_bubble.png', Icons.chat_bubble_outline,
                    AppColors.warningText,
                    RichText(
                      text: const TextSpan(
                        style: TextStyle(fontSize: 14, color: AppColors.textMain, height: 1.4),
                        children: [
                          TextSpan(text: 'Komentar baru pada Perencanaan Sprint #4 dari '),
                          TextSpan(text: 'Fadhil Syahidan.', style: TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                    '1 jam lalu',
                  ),
                  const SizedBox(height: 24),
                  
                  _buildNotificationItem(
                    'image/ic_error.png', Icons.error_outline,
                    AppColors.alertText,
                    RichText(
                      text: const TextSpan(
                        style: TextStyle(fontSize: 14, color: AppColors.textMain, height: 1.4),
                        children: [
                          TextSpan(text: 'Build ', style: TextStyle(fontStyle: FontStyle.italic)),
                          TextSpan(text: 'gagal terdeteksi pada '),
                          TextSpan(text: 'pipeline', style: TextStyle(fontStyle: FontStyle.italic)),
                          TextSpan(text: '\nAuth-Service.', style: TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                    '3 jam lalu',
                  ),
                  
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 40,
                    child: OutlinedButton(
                      onPressed: () {},
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFE3E8FF)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Tandai semua telah dibaca',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 80), // Space for FAB
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: AppColors.textMain,
        elevation: 4,
        shape: const CircleBorder(),
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      ),
    );
  }

  Widget _buildLegendDot(Color color, String text) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          text,
          style: const TextStyle(fontSize: 10, color: AppColors.textSecondary, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildProgressBar(String title, int percentage) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
            ),
            Text(
              '$percentage%',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Stack(
          children: [
            Container(
              height: 8,
              decoration: BoxDecoration(
                color: const Color(0xFFF0F0F0),
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

  Widget _buildMemberStatus(String name, String role, String status, Color statusColor, Color statusBg) {
    return Row(
      children: [
        CircleAvatar(
          radius: 20,
          backgroundColor: Colors.transparent, // fallback
          child: Image.asset(
            'image/ic_avatar_${name.split(' ')[0].toLowerCase()}.png',
            errorBuilder: (context, error, stackTrace) => Icon(Icons.account_circle, size: 40, color: statusColor),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              Text(
                role,
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
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

  Widget _buildNotificationItem(String assetPath, IconData fallbackIcon, Color iconColor, Widget content, String time) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Image.asset(
          assetPath,
          width: 20,
          height: 20,
          color: iconColor,
          errorBuilder: (context, error, stackTrace) => Icon(fallbackIcon, size: 20, color: iconColor),
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
                style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
