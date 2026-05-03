import 'package:flutter/material.dart';
import '../../theme/colors.dart';

class ProfileViewManager extends StatelessWidget {
  const ProfileViewManager({super.key});

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
              'Pengaturan Manajer',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.textMain,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Kelola profil, anggota tim, dan grup proyek Anda dari dasbor terpusat.',
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
              iconAsset: 'image/ic_user_edit.png',
              fallbackIcon: Icons.manage_accounts_outlined,
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  Center(
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 40,
                          backgroundColor: Colors.transparent,
                          child: Image.asset(
                            'image/ic_avatar_fadhil.png',
                            errorBuilder: (context, error, stackTrace) => const Icon(Icons.account_circle, size: 80, color: AppColors.textMain),
                          ),
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
              iconAsset: 'image/ic_user_add.png',
              fallbackIcon: Icons.person_add_alt_1_outlined,
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
                        _buildTextField('Email anggota baru...'),
                        const SizedBox(height: 12),
                        _buildDropdown('Peran: Anggota'),
                        const SizedBox(height: 16),
                        _buildDarkButton('Kirim Undangan'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildMemberListItem('Sukma Ananda', 'Project Lead', 'image/ic_avatar_sukma.png', Colors.blue),
                  const Divider(height: 24, color: AppColors.border),
                  _buildMemberListItem('Dian Paramitha', 'Designer', 'image/ic_avatar_dian.png', Colors.red),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Manajemen Grup Card
            _buildCardWrapper(
              title: 'Manajemen Grup',
              iconAsset: 'image/ic_hierarchy.png',
              fallbackIcon: Icons.account_tree_outlined,
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Nama Grup', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textMain)),
                            const SizedBox(height: 8),
                            _buildTextField('mis. Design Sprint'),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Kategori', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textMain)),
                            const SizedBox(height: 8),
                            _buildDropdown('Development'),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
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
                        'Buat Grup Baru',
                        style: TextStyle(
                          color: AppColors.textMain,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

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

  Widget _buildCardWrapper({required String title, required String iconAsset, required IconData fallbackIcon, required Widget child}) {
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
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textMain,
                ),
              ),
              Image.asset(
                iconAsset,
                width: 20,
                errorBuilder: (context, error, stackTrace) => Icon(fallbackIcon, size: 20, color: AppColors.textSecondary),
              ),
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
        color: const Color(0xFFF9FAFB),
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
          Text(text, style: const TextStyle(fontSize: 14, color: AppColors.textMain)),
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

  Widget _buildMemberListItem(String name, String role, String avatarAsset, Color fallbackColor) {
    return Row(
      children: [
        CircleAvatar(
          radius: 16,
          backgroundColor: Colors.transparent,
          child: Image.asset(
            avatarAsset,
            errorBuilder: (context, error, stackTrace) => Icon(Icons.account_circle, color: fallbackColor, size: 32),
          ),
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
        const Icon(Icons.more_vert, color: AppColors.textSecondary, size: 20),
      ],
    );
  }
}
