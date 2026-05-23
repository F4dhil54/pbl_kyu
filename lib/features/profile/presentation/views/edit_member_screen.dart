import 'package:flutter/material.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/theme_mode.dart';

class EditMemberScreen extends StatefulWidget {
  const EditMemberScreen({super.key});

  @override
  State<EditMemberScreen> createState() => _EditMemberScreenState();
}

class _EditMemberScreenState extends State<EditMemberScreen> {
  int _statusAkses = 1; // 1 for Aktif, 0 for Nonaktif

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
                  'Manajemen Orang',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppDarkColors.textMain : AppColors.textMain,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Kelola anggota tim dan hak akses mereka.',
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
                        'Edit Anggota',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark ? AppDarkColors.textMain : AppColors.textMain,
                        ),
                      ),
                      const SizedBox(height: 24),

                      _buildInputLabel('Nama Lengkap', isDark: isDark),
                      _buildTextField('Sukma Ananda', isDark: isDark),
                      const SizedBox(height: 20),

                      _buildInputLabel('Alamat Email', isDark: isDark),
                      _buildTextField('sukmaaa@gmail.com', isDark: isDark),
                      const SizedBox(height: 20),

                      _buildInputLabel('Jabatan', isDark: isDark),
                      _buildDropdown('Project Lead', isDark: isDark),
                      const SizedBox(height: 20),

                      _buildInputLabel('Status Akses', isDark: isDark),
                      Row(
                        children: [
                          _buildRadioButton('Aktif', 1, isDark: isDark),
                          const SizedBox(width: 24),
                          _buildRadioButton('Nonaktif', 0, isDark: isDark),
                        ],
                      ),
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
          Text(text, style: TextStyle(fontSize: 14, color: isDark ? AppDarkColors.textMain : AppColors.textMain)),
          Icon(Icons.keyboard_arrow_down, color: isDark ? AppDarkColors.textSecondary : AppColors.textSecondary),
        ],
      ),
    );
  }

  Widget _buildRadioButton(String title, int value, {required bool isDark}) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _statusAkses = value;
        });
      },
      child: Row(
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: _statusAkses == value 
                    ? AppColors.primary 
                    : (isDark ? AppDarkColors.border : AppColors.border),
                width: 2,
              ),
            ),
            child: _statusAkses == value
                ? Center(
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.primary,
                      ),
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              color: isDark ? AppDarkColors.textMain : AppColors.textMain,
            ),
          ),
        ],
      ),
    );
  }
}