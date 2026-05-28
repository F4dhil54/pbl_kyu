import 'package:flutter/material.dart';
import 'package:pbl_kyu/features/auth/presentation/views/onboarding_screen.dart';
import 'package:pbl_kyu/core/theme/colors.dart';
import 'package:pbl_kyu/core/theme/theme_mode.dart';
import 'edit_team_screen.dart';
import 'edit_member_screen.dart';
import 'create_team_screen.dart';


class ProfileViewManager extends StatelessWidget {
  const ProfileViewManager({super.key});

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
              CircleAvatar(
                radius: 16,
                backgroundColor: isDark ? AppDarkColors.surface : AppColors.inputBackground,
                child: Image.asset(
                  'image/ic_profile.png',
                  width: 24,
                  errorBuilder: (context, error, stackTrace) => Icon(
                    Icons.person,
                    color: isDark ? AppDarkColors.textMain : AppColors.textMain,
                    size: 24,
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
                Text(
                  'Pengaturan Manajer',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppDarkColors.textMain : AppColors.textMain,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Kelola profil, anggota tim, dan grup proyek Anda dari\ndasbor terpusat.',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? AppDarkColors.textSecondary : AppColors.textSecondary,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 24),

                // Edit Profil Card
                _buildCardWrapper(
                  isDark: isDark,
                  title: 'Edit Profil',
                  iconData: Icons.person_add_alt_1_outlined,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Stack(
                          children: [
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isDark ? AppDarkColors.background : AppColors.inputBackground,
                                border: Border.all(color: isDark ? AppDarkColors.border : AppColors.border, width: 1),
                              ),
                              child: Icon(Icons.person_outline, size: 48, color: isDark ? AppDarkColors.textSecondary : AppColors.textSecondary),
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: isDark ? Colors.white : AppColors.textMain,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: isDark ? AppDarkColors.surface : Colors.white, width: 2),
                                ),
                                child: Icon(Icons.camera_alt, size: 14, color: isDark ? AppDarkColors.surface : Colors.white),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text('Nama Lengkap', style: TextStyle(fontSize: 12, color: isDark ? AppDarkColors.textSecondary : AppColors.textSecondary)),
                      const SizedBox(height: 8),
                      _buildTextField('Fadhil Syahidan', isDark: isDark),
                      const SizedBox(height: 16),
                      Text('Alamat Email', style: TextStyle(fontSize: 12, color: isDark ? AppDarkColors.textSecondary : AppColors.textSecondary)),
                      const SizedBox(height: 8),
                      _buildTextField('fadhil@kyu-corp.com', isDark: isDark),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: () {},
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isDark ? AppColors.primary : AppColors.buttonDark,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            elevation: 0,
                          ),
                          child: const Text('Simpan Perubahan', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Manajemen Orang Card
                _buildCardWrapper(
                  isDark: isDark,
                  title: 'Manajemen Orang',
                  iconData: Icons.group_add_outlined,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDark ? AppDarkColors.background : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: isDark ? AppDarkColors.border : AppColors.border),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Tambah Orang',
                              style: TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 16),
                            _buildTextField('Nama anggota baru...', isDark: isDark),
                            const SizedBox(height: 12),
                            _buildTextField('Email anggota baru...', isDark: isDark),
                            const SizedBox(height: 12),
                            _buildDropdown('Jabatan: Anggota', isDark: isDark),
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              height: 44,
                              child: ElevatedButton(
                                onPressed: () {},
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: isDark ? AppColors.primary : AppColors.buttonDark,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  elevation: 0,
                                ),
                                child: const Text('Kirim Undangan', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      _buildMemberListItem(context, 'Sukma Ananda', 'Project Lead', 's', isDark: isDark),
                      Divider(height: 24, color: isDark ? AppDarkColors.border : AppColors.border),
                      _buildMemberListItem(context, 'Dian Paramitha', 'Designer', 'd', iconColor: Colors.red, isDark: isDark),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Manajemen Tim Card
                _buildCardWrapper(
                  isDark: isDark,
                  title: 'Manajemen Tim',
                  iconData: Icons.account_tree_outlined,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Nama Tim', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isDark ? AppDarkColors.textMain : AppColors.textMain)),
                                const SizedBox(height: 8),
                                _buildTextField('mis. Design Sprint', height: 40, isDark: isDark),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Pilih Anggota', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isDark ? AppDarkColors.textMain : AppColors.textMain)),
                                const SizedBox(height: 8),
                                _buildDropdown('Nama Anggot', height: 40, isDark: isDark),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text('Pilih Proyek', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isDark ? AppDarkColors.textMain : AppColors.textMain)),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: MediaQuery.of(context).size.width * 0.4,
                        child: _buildDropdown('Nama Proyek', height: 40, isDark: isDark),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 44,
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const CreateTeamScreen()),
                            );
                          },
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: isDark ? AppDarkColors.textSecondary : AppColors.textMain),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text('Buat Tim Baru', style: TextStyle(color: isDark ? AppDarkColors.textMain : AppColors.textMain, fontWeight: FontWeight.bold, fontSize: 14)),
                        ),
                      ),
                      const SizedBox(height: 24),
                      _buildTeamListItem(context, 'Tim Projek Brand Q4', Colors.blue, isDark: isDark),
                      Divider(height: 24, color: isDark ? AppDarkColors.border : AppColors.border),
                      _buildTeamListItem(context, 'Tim Projek Persiapan Audit Tahunan', Colors.red, isDark: isDark),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Mode Terang & Notifikasi
                Row(
                  children: [
                    // Tema
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          ThemeControl.toggleTheme();
                        },
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: isDark ? AppDarkColors.surface : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: isDark ? AppDarkColors.border : AppColors.border, width: 0.5),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                isDark ? Icons.dark_mode : Icons.light_mode,
                                color: isDark ? Colors.amberAccent : Colors.orange,
                                size: 28,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                isDark ? 'Mode Gelap' : 'Mode Terang',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? AppDarkColors.textMain : AppColors.textMain,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    
                    // Notifikasi
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: isDark ? AppDarkColors.surface : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: isDark ? AppDarkColors.border : AppColors.border, width: 0.5),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.notifications_none, color: isDark ? AppDarkColors.textSecondary : AppColors.textSecondary, size: 28),
                            const SizedBox(height: 16),
                            Text(
                              'Notifikasi',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: isDark ? AppDarkColors.textMain : AppColors.textMain,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // Keluar Button
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (context) => const OnboardingScreen()),
                        (route) => false,
                      );
                    },
                    icon: const Icon(Icons.logout, color: AppColors.alertText, size: 20),
                    label: const Text('Keluar', style: TextStyle(color: AppColors.alertText, fontWeight: FontWeight.bold, fontSize: 14)),
                    style: OutlinedButton.styleFrom(
                      backgroundColor: isDark ? AppDarkColors.surface : Colors.white,
                      side: const BorderSide(color: AppColors.alertText),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
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

  Widget _buildCardWrapper({required String title, required IconData iconData, required Widget child, required bool isDark}) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? AppDarkColors.surface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? AppDarkColors.border : AppColors.border, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppDarkColors.textMain : AppColors.textMain,
                ),
              ),
              Icon(iconData, color: isDark ? AppDarkColors.textSecondary : AppColors.textSecondary, size: 24),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildTextField(String hint, {double height = 48, required bool isDark}) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: isDark ? AppDarkColors.background : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: isDark ? AppDarkColors.border : AppColors.border),
      ),
      child: TextField(
        style: TextStyle(color: isDark ? AppDarkColors.textMain : AppColors.textMain),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: isDark ? AppDarkColors.textSecondary : AppColors.textSecondary, fontSize: 14),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: (height - 20) / 2),
        ),
      ),
    );
  }

  Widget _buildDropdown(String hint, {double height = 48, required bool isDark}) {
    return Container(
      height: height,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: isDark ? AppDarkColors.background : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: isDark ? AppDarkColors.border : AppColors.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(hint, style: TextStyle(color: isDark ? AppDarkColors.textMain : AppColors.textMain, fontSize: 14)),
          Icon(Icons.keyboard_arrow_down, color: isDark ? AppDarkColors.textSecondary : AppColors.textSecondary),
        ],
      ),
    );
  }

  Widget _buildMemberListItem(BuildContext context, String name, String role, String initial, {Color iconColor = Colors.blue, required bool isDark}) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: iconColor, width: 2),
          ),
          child: Center(
            child: Icon(Icons.person, color: iconColor, size: 20),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: isDark ? AppDarkColors.textMain : AppColors.textMain)),
              Text(role, style: TextStyle(fontSize: 12, color: isDark ? AppDarkColors.textSecondary : AppColors.textSecondary)),
            ],
          ),
        ),
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const EditMemberScreen()),
            );
          },
          child: Icon(Icons.more_vert, color: isDark ? AppDarkColors.textSecondary : AppColors.textSecondary, size: 20),
        ),
      ],
    );
  }

  Widget _buildTeamListItem(BuildContext context, String name, Color iconColor, {required bool isDark}) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: iconColor, width: 2),
          ),
          child: Center(
            child: Icon(Icons.person, color: iconColor, size: 20),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(name, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: isDark ? AppDarkColors.textMain : AppColors.textMain)),
        ),
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const EditTeamScreen()),
            );
          },
          child: Icon(Icons.more_vert, color: isDark ? AppDarkColors.textSecondary : AppColors.textSecondary, size: 20),
        ),
      ],
    );
  }
}