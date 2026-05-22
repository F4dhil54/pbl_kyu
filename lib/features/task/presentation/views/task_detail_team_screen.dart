import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/theme_mode.dart';
import 'package:pbl_kyu/shared/widgets/profile_avatar.dart';
import 'package:pbl_kyu/core/services/github_status.dart';

class TaskDetailTeamScreen extends StatefulWidget {
  const TaskDetailTeamScreen({super.key});

  @override
  State<TaskDetailTeamScreen> createState() => _TaskDetailTeamScreenState();
}

class _TaskDetailTeamScreenState extends State<TaskDetailTeamScreen> {
  int _secondsRemaining = 25 * 60; // 25 mnt
  Timer? _timer;
  bool _isRunning = false;

  String get _timerText {
    int minutes = _secondsRemaining ~/ 60;
    int seconds = _secondsRemaining % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  void _startTimer() {
    if (_isRunning) {
      _timer?.cancel();
      setState(() { _isRunning = false; });
    } else {
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (_secondsRemaining > 0) {
          setState(() { _secondsRemaining--; });
        } else {
          timer.cancel();
          setState(() { _isRunning = false; });
        }
      });
      setState(() { _isRunning = true; });
    }
  }

  void _resetTimer() {
    _timer?.cancel();
    setState(() {
      _secondsRemaining = 25 * 60;
      _isRunning = false;
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadData();
  }

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    if (mounted) {
      setState(() {});
    }
  }

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
              Icon(Icons.notifications_none, color: isDark ? AppDarkColors.textMain : AppColors.textMain),
              const SizedBox(width: 16),
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
                    Icon(Icons.folder_open_outlined, size: 14, color: isDark ? AppDarkColors.textSecondary : AppColors.textSecondary),
                    const SizedBox(width: 8),
                    Text(
                      'PROJEK Q4 BRAND',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: isDark ? AppDarkColors.textSecondary : AppColors.textSecondary,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Title
                Text(
                  'Pemasaran yang Dirancang\nuntuk Meningkatkan\nAwareness, Engagement, dan\nPenjualan Brand',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppDarkColors.textMain : AppColors.textMain,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 24),

                // Pomodoro Card
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.rank1Background,
                    borderRadius: BorderRadius.circular(16),
                    border: isDark ? Border.all(color: AppDarkColors.border, width: 1) : null,
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        right: -20,
                        top: -20,
                        child: Icon(
                          Icons.timer_outlined,
                          size: 120,
                          color: Colors.white.withOpacity(0.06),
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const Text(
                            'POMODORO TIMER',
                            style: TextStyle(
                              color: Color(0xFFCBD5E1),
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.5,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _timerText,
                            style: const TextStyle(
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
                                  onPressed: _startTimer,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    foregroundColor: AppColors.rank1Background,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    elevation: 0,
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(_isRunning ? Icons.pause : Icons.play_arrow, size: 20),
                                      const SizedBox(width: 8),
                                      Text(
                                        _isRunning ? 'Jeda' : 'Mulai',
                                        style: const TextStyle(
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
                                  onPressed: _resetTimer,
                                  style: OutlinedButton.styleFrom(
                                    side: const BorderSide(color: Color(0xFF64748B), width: 1.5),
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
                const SizedBox(height: 24),

                // Manager Info
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: isDark ? AppDarkColors.surface : AppColors.rank1Background,
                      child: const Icon(Icons.close, color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Manager Proyek',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? AppDarkColors.textSecondary : AppColors.textSecondary,
                          ),
                        ),
                        Text(
                          'Fadhil Syahidan',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: isDark ? AppDarkColors.textMain : AppColors.textMain,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Deadline
                Text(
                  'Batas Waktu',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? AppDarkColors.textSecondary : AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.calendar_today_outlined, size: 14, color: AppColors.alertText),
                    const SizedBox(width: 8),
                    const Text(
                      '24 Oktober 2026, 23:59 WIB',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.alertText,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Instruksi Tugas Box
                Container(
                  padding: const EdgeInsets.all(20),
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
                          const SizedBox(width: 8),
                          Text(
                            'Instruksi Tugas',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isDark ? AppDarkColors.textMain : AppColors.textMain,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Tugas Q4 Brand Campaign melibatkan pengembangan dan pengelolaan sistem kampanye digital untuk meningkatkan awareness dan engagement pelanggan pada kuartal keempat. Sistem harus mendukung integrasi API pihak ketiga menggunakan protokol OAuth2 guna menjaga keamanan akses data.',
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark ? AppDarkColors.textSecondary : AppColors.textSecondary,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildBulletPoint('Implementasi autentikasi OAuth2 menggunakan library Passport.js', isDark),
                      const SizedBox(height: 12),
                      _buildBulletPoint('Memastikan environment variables aman dan tidak meng-commit file .env', isDark),
                      const SizedBox(height: 12),
                      _buildBulletPoint('Membuat unit test pada setiap endpoint baru', isDark),
                      const SizedBox(height: 24),

                      // Catatan Penting
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDark ? AppDarkColors.background : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(8),
                          border: Border(
                            left: BorderSide(color: isDark ? AppColors.primary : AppColors.rank1Background, width: 4),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Catatan Penting:',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.amberAccent : AppColors.rank1Background, letterSpacing: 0.3,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Pastikan sinkronisasi GitHub dalam keadaan aktif sebelum memulai pengerjaan kode untuk pencatatan progress otomatis.',
                              style: TextStyle(
                                fontSize: 12,
                                fontStyle: FontStyle.italic,
                                color: isDark ? AppDarkColors.textSecondary : AppColors.textSecondary,
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Perbarui Status Header
                Text(
                  'PERBARUI STATUS',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppDarkColors.textMain : AppColors.textMain,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 16),

                // Status Options
                Row(
                  children: [
                    Expanded(child: _buildStatusOption(Icons.circle_outlined, 'Akan\nDikerjakan', false, isDark)),
                    const SizedBox(width: 8),
                    Expanded(child: _buildStatusOption(Icons.more_horiz, 'Sedang\nDikerjakan', true, isDark)),
                    const SizedBox(width: 8),
                    Expanded(child: _buildStatusOption(Icons.check_circle_outline, 'Selesai', false, isDark)),
                  ],
                ),
                const SizedBox(height: 24),

                // Save Button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: () {},
                    icon: const Text(
                      'Simpan Pembaruan Tugas',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    label: const Icon(Icons.save_outlined, size: 18),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDark ? AppColors.primary : const Color(0xFF020617),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Sinkronisasi Commit GitHub
                GestureDetector(
                  onTap: () {
                    if (GitHubStatus.isConnected) {
                      setState(() {
                        GitHubStatus.isSyncActive = !GitHubStatus.isSyncActive;
                      });
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Silakan hubungkan akun GitHub di menu Profil terlebih dahulu.'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? AppDarkColors.surface : const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(12),
                      border: isDark ? Border.all(color: AppDarkColors.border, width: 0.5) : null,
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.sync, color: Colors.white, size: 20),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Sinkronisasi Commit GitHub',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Text(
                                    'Repositori tertaut: ',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.white70,
                                    ),
                                  ),
                                  Text(
                                    GitHubStatus.repoName,
                                    style: const TextStyle(
                                      fontSize: 10,
                                      color: Color(0xFF60A5FA),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              if (GitHubStatus.isConnected) ...[
                                const SizedBox(height: 2),
                                Text(
                                  'Oleh: @${GitHubStatus.username}',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: Colors.white54,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ]
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: GitHubStatus.isSyncActive ? const Color(0xFF064E3B) : Colors.red.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            GitHubStatus.isSyncActive ? 'Aktif' : 'Non-Aktif',
                            style: TextStyle(
                              color: GitHubStatus.isSyncActive ? const Color(0xFF34D399) : Colors.redAccent,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
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

  Widget _buildBulletPoint(String text, bool isDark) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(width: 8),
        Container(
          width: 4,
          height: 4,
          margin: const EdgeInsets.only(top: 8),
          decoration: BoxDecoration(
            color: isDark ? AppDarkColors.textSecondary : AppColors.textSecondary,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 14,
              color: isDark ? AppDarkColors.textSecondary : AppColors.textSecondary,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusOption(IconData icon, String title, bool isSelected, bool isDark) {
    Color contentColor;
    if (isSelected) {
      contentColor = Colors.white;
    } else {
      contentColor = isDark ? AppDarkColors.textMain : AppColors.textMain;
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: isSelected 
            ? AppColors.primary 
            : (isDark ? AppDarkColors.surface : Colors.white),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected 
              ? AppColors.primary 
              : (isDark ? AppDarkColors.border : AppColors.border),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon, 
            color: isSelected ? contentColor : (isDark ? Colors.blueAccent : AppColors.primary), 
            size: 20
          ),
          const SizedBox(height: 8),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: contentColor,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}