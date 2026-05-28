import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/theme_mode.dart';
import '../../../profile/presentation/views/profile_view_manager.dart';

Future<bool> cekTanggalMerah(DateTime tanggalPilihan) async {
  if (tanggalPilihan.weekday == DateTime.sunday) return true;

  final tahun = tanggalPilihan.year;
  final url = Uri.parse('https://date.nager.at/api/v3/PublicHolidays/$tahun/ID');
  
  try {
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final List liburan = json.decode(response.body);
      String formatPilihan = DateFormat('yyyy-MM-dd').format(tanggalPilihan);
      return liburan.any((hari) => hari['date'] == formatPilihan);
    }
  } catch (e) {
    debugPrint("Error checking holiday: $e");
  }
  return false; 
}

class CreateTaskScreen extends StatefulWidget {
  const CreateTaskScreen({super.key});

  @override
  State<CreateTaskScreen> createState() => _CreateTaskScreenState();
}

class _CreateTaskScreenState extends State<CreateTaskScreen> {
  DateTime? _selectedDate;
  bool _isHoliday = false;
  bool _isLoadingDate = false;

  Future<void> _pilihTanggal(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _isLoadingDate = true;
        _isHoliday = false; 
      });

      bool isMerah = await cekTanggalMerah(picked);

      if (mounted) {
        setState(() {
          _isHoliday = isMerah;
          _isLoadingDate = false;
        });
      }
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
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ProfileViewManager()),
                  );
                },
                child: CircleAvatar(
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
                  'Tambah Tugas Baru',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: isDark ? AppDarkColors.textMain : AppColors.textMain),
                ),
                const SizedBox(height: 8),
                Text(
                  'Detailkan parameter proyek dan tentukan pelaksana tugas.',
                  style: TextStyle(fontSize: 14, color: isDark ? AppDarkColors.textSecondary : AppColors.textSecondary, height: 1.5),
                ),
                const SizedBox(height: 24),

                // Main Form Card
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: isDark ? AppDarkColors.surface : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: isDark ? AppDarkColors.border : AppColors.border, width: 0.5),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInputLabel('Judul Tugas', isDark),
                      _buildTextField('Masukkan judul koordinasi...', isDark),
                      const SizedBox(height: 20),

                      _buildInputLabel('DESKRIPSI', isDark),
                      _buildTextArea('Jelaskan secara singkat tujuan, ruang lingkup, dan target hasil proyek...', isDark),
                      const SizedBox(height: 20),

                      _buildInputLabel('Ditugaskan ke', isDark),
                      _buildDropdown('Pilih Anggota Tim', isDark),
                      const SizedBox(height: 20),

                      _buildInputLabel('Prioritas Tugas', isDark),
                      Row(
                        children: [
                          Expanded(child: _buildPriorityChip('Rendah', false, AppColors.successText, isDark)),
                          const SizedBox(width: 8),
                          Expanded(child: _buildPriorityChip('Sedang', true, AppColors.warningText, isDark)),
                          const SizedBox(width: 8),
                          Expanded(child: _buildPriorityChip('Tinggi', false, AppColors.alertText, isDark)),
                        ],
                      ),
                      const SizedBox(height: 20),

                      _buildInputLabel('Pilih Tanggal', isDark),
                      GestureDetector(
                        onTap: () => _pilihTanggal(context),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(
                            color: isDark ? AppDarkColors.background : Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: _isHoliday ? AppColors.alertText.withOpacity(0.5) : (isDark ? AppDarkColors.border : AppColors.border)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _selectedDate == null ? 'Pilih tenggat waktu' : DateFormat('dd/MM/yyyy').format(_selectedDate!),
                                style: TextStyle(color: _selectedDate == null ? (isDark ? AppDarkColors.textSecondary : AppColors.textSecondary) : (isDark ? AppDarkColors.textMain : AppColors.textMain)),
                              ),
                              if (_isLoadingDate)
                                const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                              else
                                Icon(Icons.calendar_today, size: 18, color: isDark ? AppDarkColors.textSecondary : AppColors.textSecondary),
                            ],
                          ),
                        ),
                      ),
                      if (_isHoliday) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF4A1D1D) : const Color(0xFFFFF5F5),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.alertText.withOpacity(0.3)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Image.asset(
                                    'image/ic_warning_red.png',
                                    width: 16,
                                    errorBuilder: (context, error, stackTrace) => const Icon(Icons.warning_amber_rounded, color: AppColors.alertText, size: 16),
                                  ),
                                  const SizedBox(width: 6),
                                  const Text(
                                    'Hari Libur Nasional / Akhir Pekan',
                                    style: TextStyle(color: AppColors.alertText, fontSize: 12, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Sistem mendeteksi tanggal yang dipilih bertepatan dengan hari libur nasional atau hari Minggu.',
                                style: TextStyle(
                                  fontSize: 11, 
                                  color: isDark ? const Color(0xFFFCA5A5) : AppColors.textSecondary,
                                  height: 1.4
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      
                      const SizedBox(height: 32),

                      // Buttons Row
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(context),
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(color: isDark ? AppDarkColors.border : AppColors.border),
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              child: Text('Batal', style: TextStyle(color: isDark ? AppDarkColors.textMain : AppColors.textMain)),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {},
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isDark ? AppColors.primary : AppColors.buttonDark,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              child: const Text('Simpan Tugas', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 20),

                // Info Card (Tips Manajer)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? AppDarkColors.surface : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: isDark ? AppDarkColors.border : const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE5EEFF),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.info_outline, color: AppColors.primary, size: 18),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Tips Manajer',
                              style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? AppDarkColors.textMain : AppColors.textMain),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Menugaskan tugas dengan prioritas \'Sedang\' pada hari libur dapat menurunkan indeks produktivitas tim sebesar 15%.',
                              style: TextStyle(
                                fontSize: 13,
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
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInputLabel(String label, bool isDark) => Padding(
    padding: const EdgeInsets.only(bottom: 8.0),
    child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isDark ? AppDarkColors.textSecondary : AppDarkColors.textSecondary, letterSpacing: 0.5)),
  );

  Widget _buildTextField(String hint, bool isDark) => Container(
    decoration: BoxDecoration(color: isDark ? AppDarkColors.background : Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: isDark ? AppDarkColors.border : AppColors.border)),
    child: TextField(style: TextStyle(color: isDark ? AppDarkColors.textMain : AppColors.textMain), decoration: InputDecoration(hintText: hint, hintStyle: TextStyle(color: isDark ? AppDarkColors.textSecondary : AppColors.textSecondary, fontSize: 14), border: InputBorder.none, contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14))),
  );

  Widget _buildTextArea(String hint, bool isDark) => Container(
    height: 100,
    decoration: BoxDecoration(color: isDark ? AppDarkColors.background : Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: isDark ? AppDarkColors.border : AppColors.border)),
    child: TextField(style: TextStyle(color: isDark ? AppDarkColors.textMain : AppColors.textMain), maxLines: null, expands: true, decoration: InputDecoration(hintText: hint, hintStyle: TextStyle(color: isDark ? AppDarkColors.textSecondary : AppColors.textSecondary, fontSize: 14), border: InputBorder.none, contentPadding: const EdgeInsets.all(16))),
  );

  Widget _buildDropdown(String text, bool isDark) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    decoration: BoxDecoration(color: isDark ? AppDarkColors.background : Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: isDark ? AppDarkColors.border : AppColors.border)),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(text, style: TextStyle(fontSize: 14, color: isDark ? AppDarkColors.textMain : AppColors.textMain)), Icon(Icons.keyboard_arrow_down, color: isDark ? AppDarkColors.textSecondary : AppColors.textSecondary)]),
  );

  Widget _buildPriorityChip(String label, bool isSelected, Color dotColor, bool isDark) => Container(
    padding: const EdgeInsets.symmetric(vertical: 12),
    decoration: BoxDecoration(color: isSelected ? (isDark ? const Color(0xFF1E293B) : const Color(0xFFE5EEFF)) : (isDark ? AppDarkColors.background : Colors.white), borderRadius: BorderRadius.circular(8), border: Border.all(color: isSelected ? AppColors.primary : (isDark ? AppDarkColors.border : AppColors.border))),
    child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Container(width: 8, height: 8, decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle)), const SizedBox(width: 8), Text(label, style: TextStyle(fontSize: 12, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, color: isDark ? AppDarkColors.textMain : AppColors.textMain))]),
  );
}