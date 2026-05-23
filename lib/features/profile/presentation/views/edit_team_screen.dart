import 'package:flutter/material.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/theme_mode.dart'; 

class EditTeamScreen extends StatelessWidget {
  const EditTeamScreen({super.key});

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
            automaticallyImplyLeading: false,
            title: Row(
              children: [
                IconButton(
                  icon: Icon(Icons.arrow_back, color: isDark ? AppDarkColors.textMain : AppColors.textMain),
                  onPressed: () => Navigator.pop(context),
                ),
                Text(
                  'KYU',
                  style: TextStyle(
                    color: isDark ? Colors.white : const Color(0xFF1E3A8A),
                    fontWeight: FontWeight.w900,
                    fontSize: 20,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Manajemen Tim',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppDarkColors.textMain : AppColors.textMain,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Kelola tim kolaborasi dan hak akses tim dalam\nproyek.',
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? AppDarkColors.textSecondary : AppColors.textSecondary,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 24),

                // Form Card
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: isDark ? AppDarkColors.surface : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: isDark ? AppDarkColors.border : AppColors.border, width: 0.5),
                    boxShadow: [
                      if (!isDark)
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
                      Text(
                        'Edit Tim',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark ? AppDarkColors.textMain : AppColors.textMain,
                        ),
                      ),
                      const SizedBox(height: 24),

                      _buildInputLabel('Nama Grup', isDark: isDark),
                      _buildTextField('Tim Projek Brand Q4', isDark: isDark),
                      const SizedBox(height: 20),

                      _buildInputLabel('Pilih Anggota', isDark: isDark),
                      _buildTagsInput(isDark: isDark),
                      const SizedBox(height: 20),

                      _buildInputLabel('Pilih Proyek', isDark: isDark),
                      _buildDropdown('Tim Projek Persiapan Audit Tahunan', isDark: isDark),
                      const SizedBox(height: 32),
                      Divider(color: isDark ? AppDarkColors.border : AppColors.border),
                      const SizedBox(height: 24),

                      // Action Buttons
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {},
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isDark ? AppColors.primary : const Color(0xFF020617),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            elevation: 0,
                          ),
                          child: const Text(
                            'Simpan Perubahan',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: isDark ? AppDarkColors.border : AppColors.border),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: Text(
                            'Batal',
                            style: TextStyle(
                              color: isDark ? AppDarkColors.textMain : AppColors.textMain,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
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
      },
    );
  }

  Widget _buildInputLabel(String label, {required bool isDark}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: isDark ? AppDarkColors.textMain : AppColors.textMain,
        ),
      ),
    );
  }

  Widget _buildTextField(String text, {required bool isDark}) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppDarkColors.background : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: isDark ? AppDarkColors.border : AppColors.border),
      ),
      child: TextField(
        controller: TextEditingController(text: text),
        decoration: const InputDecoration(
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        style: TextStyle(color: isDark ? AppDarkColors.textMain : AppColors.textMain, fontSize: 14),
      ),
    );
  }

  Widget _buildDropdown(String text, {required bool isDark}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: isDark ? AppDarkColors.background : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: isDark ? AppDarkColors.border : AppColors.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 14, color: isDark ? AppDarkColors.textMain : AppColors.textMain),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Icon(Icons.keyboard_arrow_down, color: isDark ? AppDarkColors.textSecondary : AppColors.textSecondary),
        ],
      ),
    );
  }

  Widget _buildTagsInput({required bool isDark}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppDarkColors.background : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: isDark ? AppDarkColors.border : AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildTagChip('Sukma Ananda', isDark: isDark),
              _buildTagChip('Dea Marselia', isDark: isDark),
              _buildTagChip('Dian Paramitha', isDark: isDark),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            decoration: InputDecoration(
              hintText: 'Ketik nama anggota...',
              hintStyle: TextStyle(color: isDark ? AppDarkColors.textSecondary : AppColors.textSecondary, fontSize: 14),
              border: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.zero,
            ),
            style: TextStyle(color: isDark ? AppDarkColors.textMain : AppColors.textMain, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildTagChip(String name, {required bool isDark}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? AppDarkColors.surface : const Color(0xFFE0E7FF),
        borderRadius: BorderRadius.circular(16),
        border: isDark ? Border.all(color: AppDarkColors.border) : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            name,
            style: TextStyle(
              color: isDark ? Colors.white : AppColors.primary,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 4),
          Icon(
            Icons.close,
            size: 14,
            color: isDark ? Colors.white : AppColors.primary,
          ),
        ],
      ),
    );
  }
}