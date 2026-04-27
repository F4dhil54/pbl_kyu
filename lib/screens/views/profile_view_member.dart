import 'package:flutter/material.dart';
import '../../theme/colors.dart';
import 'login_screen.dart';

class ProfileViewMember extends StatelessWidget {
  const ProfileViewMember({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: const Icon(Icons.arrow_back, color: AppColors.textMain),
        title: const Text(
          'Profil',
          style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(icon: const Icon(Icons.settings, color: AppColors.textSecondary), onPressed: () {}),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Profile Header
            Stack(
              children: [
                const CircleAvatar(
                  radius: 50,
                  backgroundColor: AppColors.inputBackground,
                  child: Icon(Icons.person, size: 50, color: AppColors.textMain),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.edit, size: 16, color: Colors.white),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text('PRINCIPAL DESIGN ARCHITECT', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            const Text('Sukma Ananda', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24)),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.inputBackground,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Text('Core Team', style: TextStyle(fontSize: 10)),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.inputBackground,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Text('San Fransisco, CA', style: TextStyle(fontSize: 10)),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Focus Statistics
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Focus\nStatistics', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Expanded(
                        child: Text(
                          'Deep work\nsessions over\nthe last 7\ndays',
                          style: TextStyle(fontSize: 10, color: AppColors.textMain),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: AppColors.inputBackground,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Text('WEEKLY', style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold)),
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              child: Text('MONTHLY', style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
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
                      return Text(
                        day,
                        style: TextStyle(
                          fontSize: 10,
                          color: day == 'WED' ? AppColors.primary : AppColors.textSecondary,
                          fontWeight: day == 'WED' ? FontWeight.bold : FontWeight.normal,
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 8),
                  const Divider(),
                  const SizedBox(height: 16),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Column(
                        children: [
                          Text('TOTAL\nFOCUS', textAlign: TextAlign.center, style: TextStyle(fontSize: 8, color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
                          SizedBox(height: 4),
                          Text('24.5h', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      Column(
                        children: [
                          Text('DAILY AVG', textAlign: TextAlign.center, style: TextStyle(fontSize: 8, color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
                          SizedBox(height: 4),
                          Text('3.5h', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      Column(
                        children: [
                          Text('STREAK', textAlign: TextAlign.center, style: TextStyle(fontSize: 8, color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
                          SizedBox(height: 4),
                          Text('12 Days', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Github Sync
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  const Text('Github Sync', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Status', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
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
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Account', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                      Text('@sukma_architect', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.inputBackground,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Center(child: Text('Sync Repositories', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Account Control Header
            const Align(
              alignment: Alignment.centerLeft,
              child: Text('ACCOUNT CONTROL', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 10)),
            ),
            const SizedBox(height: 16),
            
            // Account Control Items
            _buildControlItem(Icons.edit, 'Edit Profil', 'Update identity and role\ninformation'),
            const SizedBox(height: 12),
            _buildControlItem(Icons.security, 'Security & Privacy', 'Manage passwords and 2FA'),
            const SizedBox(height: 12),
            _buildControlItem(Icons.notifications, 'Preferences', 'Customize alert and\nworkspace theme'),
            const SizedBox(height: 12),
            _buildControlItem(Icons.credit_card, 'Billing & Usage', 'Manage subscription and focus\ncredits'),
            const SizedBox(height: 32),

            // Sign Out
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
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.logout),
                    SizedBox(width: 8),
                    Text('Sign Out', style: TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildControlItem(IconData icon, String title, String subtitle) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.inputBackground,
            child: Icon(icon, color: AppColors.textMain, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 4),
                Text(subtitle, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: AppColors.textMain),
        ],
      ),
    );
  }
}