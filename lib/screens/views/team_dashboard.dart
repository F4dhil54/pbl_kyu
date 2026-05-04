import 'package:flutter/material.dart';
import '../../theme/colors.dart';

class TeamDashboard extends StatelessWidget {
  const TeamDashboard({super.key});

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
          CircleAvatar(
            radius: 16,
            backgroundColor: AppColors.inputBackground,
            child: Image.asset(
              'image/ic_profile.png',
              width: 24,
              errorBuilder: (context, error, stackTrace) => const Icon(Icons.person, color: AppColors.textMain, size: 24),
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
            const Text(
              'Selamat Pagi, Tim.',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.textMain,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Fokus pada eksekusi hari ini.',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 24),

            // Pomodoro Card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.rank1Background, // Dark navy
                borderRadius: BorderRadius.circular(16),
              ),
              child: Stack(
                children: [
                  Positioned(
                    right: -20,
                    top: -20,
                    child: Icon(
                      Icons.timer_outlined,
                      size: 120,
                      color: Colors.white.withOpacity(0.05),
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Text(
                        'POMODORO TIMER',
                        style: TextStyle(
                          color: Color(0xFF8BA6C1),
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        '25:00',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 64,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -2,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {},
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: AppColors.rank1Background,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                elevation: 0,
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.play_arrow, size: 20),
                                  SizedBox(width: 8),
                                  Text(
                                    'Mulai',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {},
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Color(0xFF4A6B8C)),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 16),
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.stop, size: 20),
                                  SizedBox(width: 8),
                                  Text(
                                    'Berhenti',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Tugas Saya Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Tugas Saya',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textMain,
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
            const SizedBox(height: 16),

            // Task List
            _buildTaskCard(
              title: 'Finalisasi Proposal Proyek',
              time: '09:00 - 11:00',
              progress: 0.6,
              isCompleted: false,
            ),
            const SizedBox(height: 12),
            _buildTaskCard(
              title: 'Review Desain Sprint UI',
              time: '13:30 - 15:00',
              progress: 0.2,
              isCompleted: false,
            ),
            const SizedBox(height: 12),
            _buildTaskCard(
              title: 'Daily Standup Meeting',
              time: 'Selesai',
              progress: 1.0,
              isCompleted: true,
            ),
            const SizedBox(height: 40),

            // Quote Section
            Center(
              child: Column(
                children: [
                  const Icon(
                    Icons.format_quote_rounded,
                    color: Color(0xFFD6E4FF),
                    size: 40,
                  ),
                  const SizedBox(height: 8),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      '"Kualitas bukan merupakan sebuah aksi, melainkan sebuah kebiasaan yang terus dilakukan secara konsisten."',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textMain,
                        height: 1.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '— Aristotle',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.primary,
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
  }

  Widget _buildTaskCard({
    required String title,
    required String time,
    required double progress,
    required bool isCompleted,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 0.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Checkbox
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: isCompleted ? AppColors.primary : Colors.white,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: isCompleted ? AppColors.primary : AppColors.border,
                width: 2,
              ),
            ),
            child: isCompleted
                ? const Icon(Icons.check, size: 16, color: Colors.white)
                : null,
          ),
          const SizedBox(width: 16),
          // Texts
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isCompleted ? AppColors.textSecondary : AppColors.textMain,
                    decoration: isCompleted ? TextDecoration.lineThrough : null,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    if (!isCompleted) ...[
                      const Icon(Icons.access_time, size: 12, color: AppColors.textSecondary),
                      const SizedBox(width: 4),
                    ] else ...[
                      const Icon(Icons.check_circle_outline, size: 12, color: AppColors.textSecondary),
                      const SizedBox(width: 4),
                    ],
                    Text(
                      time,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Progress bar (only if not completed)
          if (!isCompleted)
            SizedBox(
              width: 48,
              height: 6,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: AppColors.lightBlueSelection,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
              ),
            ),
        ],
      ),
    );
  }
}