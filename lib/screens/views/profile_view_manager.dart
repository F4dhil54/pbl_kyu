import 'package:flutter/material.dart';
import '../../theme/colors.dart';
import 'edit_member_screen.dart';
import 'edit_team_screen.dart';

class ProfileViewManager extends StatelessWidget {
  const ProfileViewManager({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textMain),
          onPressed: () => Navigator.pop(context),
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
          Container(
            margin: const EdgeInsets.only(right: 20),
            decoration: const BoxDecoration(
              color: Color(0xFF020617), // Very dark blue/black
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white, size: 20),
              onPressed: () => Navigator.pop(context),
              constraints: const BoxConstraints(),
              padding: const EdgeInsets.all(8),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Pengaturan Manajer',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.textMain,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Kelola profil, anggota tim, dan grup proyek Anda dari\ndasbor terpusat.',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),

            // Edit Profil Card
            _buildCardWrapper(
              title: 'Edit Profil',
              iconData: Icons.manage_accounts_outlined,
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  Center(
                    child: Stack(
                      children: [
                        const CircleAvatar(
                          radius: 40,
                          backgroundColor: Colors.transparent,
                          child: Icon(Icons.account_circle, size: 80, color: AppColors.textMain),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: AppColors.textMain,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.camera_alt, size: 12, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildInputLabel('Nama Lengkap'),
                  _buildTextField('Fadhil Syahidan'),
                  const SizedBox(height: 16),
                  _buildInputLabel('Alamat Email'),
                  _buildTextField('fadhil@kyu-corp.com'),
                  const SizedBox(height: 24),
                  _buildDarkButton('Simpan Perubahan'),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Manajemen Orang Card
            _buildCardWrapper(
              title: 'Manajemen Orang',
              iconData: Icons.person_add_alt_1_outlined,
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border, width: 1),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Tambah Orang', style: TextStyle(fontSize: 10, color: AppColors.primary, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 12),
                        _buildTextField('Nama anggota baru...'),
                        const SizedBox(height: 12),
                        _buildTextField('Email anggota baru...'),
                        const SizedBox(height: 12),
                        _buildDropdown('Jabatan: Anggota'),
                        const SizedBox(height: 16),
                        _buildDarkButton('Kirim Undangan'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildMemberListItem(context, 'Sukma Ananda', 'Project Lead', Colors.blue),
                  const Divider(height: 24, color: AppColors.border),
                  _buildMemberListItem(context, 'Dian Paramitha', 'Designer', Colors.red),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Manajemen Tim Card
            _buildCardWrapper(
              title: 'Manajemen Tim',
              iconData: Icons.account_tree_outlined,
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Nama Tim', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textMain)),
                            const SizedBox(height: 8),
                            _buildTextField('mis. Design Sprint'),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Pilih Anggota', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textMain)),
                            const SizedBox(height: 8),
                            _buildDropdown('Nama Anggot...'),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text('Pilih Proyek', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textMain)),
                  const SizedBox(height: 8),
                  _buildDropdown('Nama Proyek'),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: OutlinedButton(
                      onPressed: () {},
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.textMain),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Buat Tim Baru',
                        style: TextStyle(
                          color: AppColors.textMain,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildTeamListItem(context, 'Tim Projek Brand Q4', Colors.blue),
                  const Divider(height: 24, color: AppColors.border),
                  _buildTeamListItem(context, 'Tim Projek Persiapan Audit Tahunan', Colors.red),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Settings Cards
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
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.dark_mode_outlined, color: AppColors.textSecondary, size: 20),
                        SizedBox(height: 16),
                        Text(
                          'Mode Terang',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textMain,
                          ),
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
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.notifications_none, color: AppColors.textSecondary, size: 20),
                        SizedBox(height: 16),
                        Text(
                          'Notifikasi',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textMain,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Keluar Button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.logout, color: AppColors.alertText, size: 20),
                label: const Text(
                  'Keluar',
                  style: TextStyle(
                    color: AppColors.alertText,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  backgroundColor: Colors.white,
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
  }

  Widget _buildCardWrapper({required String title, required IconData iconData, required Widget child}) {
    return Container(
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
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textMain,
                ),
              ),
              Icon(iconData, size: 20, color: AppColors.textSecondary),
            ],
          ),
          child,
        ],
      ),
    );
  }

  Widget _buildInputLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: AppColors.textMain,
        ),
      ),
    );
  }

  Widget _buildTextField(String hint) {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: TextField(
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }

  Widget _buildDropdown(String text) {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              text, 
              style: const TextStyle(fontSize: 14, color: AppColors.textMain),
              overflow: TextOverflow.ellipsis,
            )
          ),
          const Icon(Icons.keyboard_arrow_down, color: AppColors.textSecondary),
        ],
      ),
    );
  }

  Widget _buildDarkButton(String text) {
    return SizedBox(
      width: double.infinity,
      height: 44,
      child: ElevatedButton(
        onPressed: () {},
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.buttonDark,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          elevation: 0,
        ),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildMemberListItem(BuildContext context, String name, String role, Color fallbackColor) {
    return Row(
      children: [
        CircleAvatar(
          radius: 16,
          backgroundColor: Colors.transparent,
          child: Icon(Icons.account_circle, color: fallbackColor, size: 32),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textMain),
              ),
              Text(
                role,
                style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
              ),
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
          child: const Icon(Icons.more_vert, color: AppColors.textSecondary, size: 20),
        ),
      ],
    );
  }

  Widget _buildTeamListItem(BuildContext context, String name, Color fallbackColor) {
    return Row(
      children: [
        CircleAvatar(
          radius: 16,
          backgroundColor: Colors.transparent,
          child: Icon(Icons.account_circle, color: fallbackColor, size: 32), // Using account_circle as placeholder for team avatar as in image
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            name,
            style: const TextStyle(fontSize: 14, color: AppColors.textMain),
          ),
        ),
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const EditTeamScreen()),
            );
          },
          child: const Icon(Icons.more_vert, color: AppColors.textSecondary, size: 20),
        ),
      ],
    );
  }
}
