import 'package:flutter/material.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/theme_mode.dart';
import '../../../auth/presentation/views/login_screen.dart';
import 'notification_preference_item.dart';

class ProfileViewMember extends StatelessWidget {
  const ProfileViewMember({super.key});

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
            leading: Icon(Icons.arrow_back, color: isDark ? AppDarkColors.textMain : AppColors.textMain),
            title: Text(
              'Profil',
              style: TextStyle(
                color: isDark ? AppColors.primary : AppColors.primary, 
                fontWeight: FontWeight.bold
              ),
            ),
            actions: [
              IconButton(
                icon: Icon(Icons.settings, color: isDark ? AppDarkColors.textSecondary : AppColors.textSecondary), 
                onPressed: () {}
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Header Profil
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: isDark ? AppDarkColors.surface : AppColors.inputBackground,
                      child: Icon(Icons.person, size: 50, color: isDark ? AppDarkColors.textMain : AppColors.textMain),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isDark ? AppDarkColors.background : AppColors.background,
                            width: 2,
                          ),
                        ),
                        child: const Icon(Icons.edit, size: 16, color: Colors.white),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'PRINCIPAL DESIGN ARCHITECT', 
                  style: TextStyle(
                    fontSize: 10, 
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppDarkColors.textSecondary : AppColors.textSecondary,
                  )
                ),
                const SizedBox(height: 4),
                Text(
                  'Sukma Ananda', 
                  style: TextStyle(
                    fontWeight: FontWeight.bold, 
                    fontSize: 24,
                    color: isDark ? AppDarkColors.textMain : AppColors.textMain,
                  )
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: isDark ? AppDarkColors.surface : AppColors.inputBackground,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: isDark ? AppDarkColors.border : AppColors.border, width: 0.5),
                      ),
                      child: Text('Core Team', style: TextStyle(fontSize: 10, color: isDark ? AppDarkColors.textMain : AppColors.textMain)),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: isDark ? AppDarkColors.surface : AppColors.inputBackground,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: isDark ? AppDarkColors.border : AppColors.border, width: 0.5),
                      ),
                      child: Text('San Fransisco, CA', style: TextStyle(fontSize: 10, color: isDark ? AppDarkColors.textMain : AppColors.textMain)),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Statistik Fokus
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: isDark ? AppDarkColors.surface : AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: isDark ? AppDarkColors.border : AppColors.border, width: 0.5),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Focus\nStatistics', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: isDark ? AppDarkColors.textMain : AppColors.textMain)),
                      const SizedBox(height: 8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              'Deep work\nsessions over\nthe last 7\ndays',
                              style: TextStyle(fontSize: 10, color: isDark ? AppDarkColors.textSecondary : AppColors.textSecondary),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: isDark ? AppDarkColors.background : AppColors.inputBackground,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: isDark ? AppDarkColors.border : Colors.transparent),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: isDark ? AppDarkColors.surface : Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: isDark ? null : [
                                      BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4)
                                    ],
                                  ),
                                  child: Text('WEEKLY', style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: isDark ? AppDarkColors.textMain : AppColors.textMain)),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  child: Text('MONTHLY', style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: isDark ? AppDarkColors.textSecondary : AppColors.textSecondary)),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 40),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT'].map((day) {
                          bool isToday = day == 'WED';
                          return Text(
                            day,
                            style: TextStyle(
                              fontSize: 10,
                              color: isToday 
                                  ? AppColors.primary 
                                  : (isDark ? AppDarkColors.textSecondary : AppColors.textSecondary),
                              fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 8),
                      Divider(color: isDark ? AppDarkColors.border : AppColors.border),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Column(
                            children: [
                              Text('TOTAL\nFOCUS', textAlign: TextAlign.center, style: TextStyle(fontSize: 8, color: isDark ? AppDarkColors.textSecondary : AppColors.textSecondary, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              Text('24.5h', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: isDark ? AppDarkColors.textMain : AppColors.textMain)),
                            ],
                          ),
                          Column(
                            children: [
                              Text('DAILY AVG', textAlign: TextAlign.center, style: TextStyle(fontSize: 8, color: isDark ? AppDarkColors.textSecondary : AppColors.textSecondary, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              Text('3.5h', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: isDark ? AppDarkColors.textMain : AppColors.textMain)),
                            ],
                          ),
                          Column(
                            children: [
                              Text('STREAK', textAlign: TextAlign.center, style: TextStyle(fontSize: 8, color: isDark ? AppDarkColors.textSecondary : AppColors.textSecondary, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              Text('12 Days', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: isDark ? AppDarkColors.textMain : AppColors.textMain)),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Sinkronisasi GitHub
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: isDark ? AppDarkColors.surface : AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: isDark ? AppDarkColors.border : AppColors.border, width: 0.5),
                  ),
                  child: Column(
                    children: [
                      Text('Github Sync', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: isDark ? AppDarkColors.textMain : AppColors.textMain)),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Status', style: TextStyle(fontSize: 12, color: isDark ? AppDarkColors.textSecondary : AppColors.textSecondary)),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.success,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text('CONNECTED', style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Account', style: TextStyle(fontSize: 12, color: isDark ? AppDarkColors.textSecondary : AppColors.textSecondary)),
                          Text('@sukma_architect', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isDark ? AppDarkColors.textMain : AppColors.textMain)),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: isDark ? AppDarkColors.background : AppColors.inputBackground,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: isDark ? AppDarkColors.border : AppColors.border),
                        ),
                        child: Center(
                          child: Text(
                            'Sync Repositories', 
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: isDark ? AppDarkColors.textMain : AppColors.textMain)
                          )
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Header Kontrol Akun
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text('ACCOUNT CONTROL', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 10)),
                ),
                const SizedBox(height: 16),
                
                // Item Kontrol Akun
                Container(
                  decoration: BoxDecoration(
                    color: isDark ? AppDarkColors.surface : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: isDark ? AppDarkColors.border : AppColors.border, width: 0.5),
                  ),
                  child: Column(
                    children: [
                      _buildControlItem(Icons.edit, 'Edit Profil', 'Update identity and role\ninformation', isDark: isDark),
                      Divider(height: 1, indent: 72, endIndent: 16, color: isDark ? AppDarkColors.border : AppColors.border),
                      _buildControlItem(Icons.security, 'Security & Privacy', 'Manage passwords and 2FA', isDark: isDark),
                      Divider(height: 1, indent: 72, endIndent: 16, color: isDark ? AppDarkColors.border : AppColors.border),
                      NotificationPreferenceItem(isDark: isDark),
                      Divider(height: 1, indent: 72, endIndent: 16, color: isDark ? AppDarkColors.border : AppColors.border),
                      _buildControlItem(Icons.credit_card, 'Billing & Usage', 'Manage subscription and focus\ncredits', isDark: isDark),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Keluar
                GestureDetector(
                  onTap: () {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (context) => const LoginScreen()),
                      (route) => false,
                    );
                  },
                  child: Container(
                    width: 150,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: isDark ? AppDarkColors.surface : AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: isDark ? AppDarkColors.border : AppColors.border, width: 0.5),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.logout, color: isDark ? AppDarkColors.textMain : AppColors.textMain),
                        const SizedBox(width: 8),
                        Text(
                          'Sign Out', 
                          style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? AppDarkColors.textMain : AppColors.textMain)
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

  Widget _buildControlItem(IconData icon, String title, String subtitle, {required bool isDark}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: isDark ? AppDarkColors.background : AppColors.inputBackground,
            child: Icon(icon, color: isDark ? AppDarkColors.textMain : AppColors.textMain, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title, 
                  style: TextStyle(
                    fontWeight: FontWeight.bold, 
                    fontSize: 14, 
                    color: isDark ? AppDarkColors.textMain : AppColors.textMain
                  )
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle, 
                  style: TextStyle(
                    fontSize: 12, 
                    color: isDark ? AppDarkColors.textSecondary : AppColors.textSecondary
                  )
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: isDark ? AppDarkColors.textSecondary : AppColors.textMain),
        ],
      ),
    );
  }
}
