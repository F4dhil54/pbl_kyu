import 'package:flutter/material.dart';
import '../../theme/colors.dart';
import 'profile_view_manager.dart';

class TaskDetailScreen extends StatelessWidget {
  const TaskDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.menu, color: AppColors.textMain),
          onPressed: () {},
        ),
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
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Breadcrumb
            Row(
              children: [
                const Text(
                  'Proyek: Q4 Brand Campaign',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.chevron_right, size: 14, color: AppColors.textMain),
                const SizedBox(width: 8),
                const Text(
                  'Daftar Tugas',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textMain,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Top Cards
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border, width: 0.5),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'MANAJER',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textSecondary,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 12,
                              backgroundColor: Colors.transparent,
                              child: Image.asset(
                                'image/ic_avatar_fadhil.png',
                                errorBuilder: (context, error, stackTrace) => const Icon(Icons.account_circle, color: Color(0xFFE65100), size: 24),
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Expanded(
                              child: Text(
                                'Fadhil Syahidan',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textMain,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border, width: 0.5),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'TENGGAT WAKTU',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textSecondary,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Image.asset(
                              'image/ic_calendar_red.png',
                              width: 20,
                              errorBuilder: (context, error, stackTrace) => const Icon(Icons.calendar_today, color: AppColors.alertText, size: 20),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              '24 Okt 2023',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: AppColors.alertText,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Tugas Content Card
            Container(
              padding: const EdgeInsets.all(24),
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
                    children: [
                      Image.asset(
                        'image/ic_document_black.png',
                        width: 20,
                        errorBuilder: (context, error, stackTrace) => const Icon(Icons.description_outlined, color: AppColors.textMain, size: 20),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Tugas',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textMain,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(color: AppColors.border, height: 1),
                  const SizedBox(height: 20),
                  
                  const Text(
                    'Mohon fokus pada optimasi authentication layer di dalam middleware. Implementasi saat ini menyebabkan penundaan 200ms pada setiap request.',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textMain,
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  _buildListItem('Migrasikan validasi JWT ke Redis edge cache.'),
                  const SizedBox(height: 16),
                  _buildListItem('Pastikan semua respons error mengikuti skema baru yang didefinisikan pada PR #442.'),
                  const SizedBox(height: 16),
                  _buildListItem('Perbarui dokumentasi di direktori /docs/api-internal.'),
                  const SizedBox(height: 40),
                ],
              ),
            ),
            const SizedBox(height: 80), // FAB spacing
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: Colors.black, // Dark/black FAB like image
        elevation: 4,
        shape: const CircleBorder(),
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      ),
    );
  }

  Widget _buildListItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 8.0, right: 12.0),
            child: CircleAvatar(
              radius: 2,
              backgroundColor: AppColors.textSecondary,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
