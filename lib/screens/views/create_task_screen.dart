import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import '../../theme/colors.dart';
import 'profile_view_manager.dart';

// FUNGSI LOKAL & API NAGER.DATE
Future<bool> cekTanggalMerah(DateTime tanggalPilihan) async {
  // Cek Offline: Hari Minggu
  if (tanggalPilihan.weekday == DateTime.sunday) {
    print("[LOG LOKAL] Hari Minggu terdeteksi! (Otomatis Tanggal Merah)");
    return true; 
  }

  // Cek Online: Nager.Date API
  final tahun = tanggalPilihan.year;
  final url = Uri.parse('https://date.nager.at/api/v3/PublicHolidays/$tahun/ID');
  
  try {
    print("[LOG API] Mengambil data dari Nager.Date untuk tahun $tahun...");
    final response = await http.get(url);
    
    if (response.statusCode == 200) {
      final List liburan = json.decode(response.body);
      String formatPilihan = DateFormat('yyyy-MM-dd').format(tanggalPilihan);
      
      bool isLibur = liburan.any((hari) => hari['date'] == formatPilihan);
      
      if (isLibur) {
        var dataLibur = liburan.firstWhere((hari) => hari['date'] == formatPilihan);
        print("[LOG API] COCOK! HARI LIBUR NASIONAL: ${dataLibur['localName']}");
      } else {
        print("[LOG API] Tanggal Aman (Bukan hari libur nasional).");
      }
      
      return isLibur;
    } else {
      print("[LOG ERROR] Server Nager.Date merespons dengan status: ${response.statusCode}");
    }
  } catch (e) {
    print("[LOG ERROR] Gagal! Pastikan izin INTERNET ada di AndroidManifest.xml. Error: $e");
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
      // Nyalakan indikator loading di kalender
      setState(() {
        _selectedDate = picked;
        _isLoadingDate = true;
        _isHoliday = false; 
      });

      // Proses Pengecekan
      bool isMerah = await cekTanggalMerah(picked);

      // Matikan indikator loading dan munculkan peringatan jika true
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
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfileViewManager()),
              );
            },
            child: CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.inputBackground,
              child: Image.asset(
                'image/ic_profile.png',
                width: 24,
                errorBuilder: (context, error, stackTrace) => const Icon(Icons.person, color: AppColors.textMain, size: 24),
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
            const Text(
              'Tambah Tugas Baru',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textMain),
            ),
            const SizedBox(height: 8),
            const Text(
              'Detailkan parameter proyek dan tentukan pelaksana\ntugas.',
              style: TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.5),
            ),
            const SizedBox(height: 24),

            // Main Form Card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border, width: 0.5),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInputLabel('Judul Tugas'),
                  _buildTextField('Masukkan judul koordinasi...'),
                  const SizedBox(height: 20),

                  _buildInputLabel('DESKRIPSI'),
                  _buildTextArea('Jelaskan secara singkat tujuan, ruang\nlingkup, dan target hasil proyek...'),
                  const SizedBox(height: 20),

                  _buildInputLabel('Ditugaskan ke'),
                  _buildDropdown('Pilih Anggota Tim'),
                  const SizedBox(height: 20),

                  _buildInputLabel('Prioritas Tugas'),
                  Row(
                    children: [
                      Expanded(child: _buildPriorityChip('Rendah', false, AppColors.successText)),
                      const SizedBox(width: 8),
                      Expanded(child: _buildPriorityChip('Sedang', true, AppColors.warningText)),
                      const SizedBox(width: 8),
                      Expanded(child: _buildPriorityChip('Tinggi', false, AppColors.alertText)),
                    ],
                  ),
                  const SizedBox(height: 20),

                  _buildInputLabel('Pilih Tanggal'),
                  
                  GestureDetector(
                    onTap: () => _pilihTanggal(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: _isHoliday ? AppColors.alertText : AppColors.border,
                          width: _isHoliday ? 1.5 : 1.0, 
                        ), 
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _selectedDate == null 
                                ? 'Pilih tenggat waktu' 
                                : DateFormat('dd/MM/yyyy').format(_selectedDate!),
                            style: TextStyle(
                              color: _selectedDate == null ? AppColors.textSecondary : AppColors.textMain,
                              fontSize: 14,
                            ),
                          ),
                          if (_isLoadingDate)
                            const SizedBox(
                              width: 16, height: 16, 
                              child: CircularProgressIndicator(strokeWidth: 2)
                            )
                          else
                            const Icon(Icons.calendar_today, size: 18, color: AppColors.textSecondary),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  if (_isHoliday) ...[
                    Row(
                      children: [
                        Image.asset(
                          'image/ic_warning_red.png',
                          width: 16,
                          errorBuilder: (context, error, stackTrace) => const Icon(Icons.warning_amber_rounded, color: AppColors.alertText, size: 16),
                        ),
                        const SizedBox(width: 4),
                        const Text(
                          'Hari Libur Nasional / Akhir Pekan',
                          style: TextStyle(color: AppColors.alertText, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Sistem mendeteksi tanggal yang dipilih bertepatan dengan\nhari libur nasional atau hari Minggu.',
                      style: TextStyle(fontSize: 10, color: AppColors.textSecondary),
                    ),
                  ],
                  const SizedBox(height: 32),

                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {},
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppColors.border),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: const Text(
                            'Batal',
                            style: TextStyle(color: AppColors.textMain, fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {},
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.buttonDark,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            elevation: 0,
                          ),
                          child: const Text(
                            'Simpan Tugas',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Info Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Color(0xFFD6E4FF),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.info_outline, color: AppColors.primary, size: 20),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Tips Manajer',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textMain,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Menugaskan tugas dengan prioritas \'Med\' pada hari libur dapat menurunkan indeks produktivitas tim sebesar 15%.',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                            height: 1.5,
                          ),
                        ),
                      ],
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

  Widget _buildInputLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textMain)),
    );
  }

  Widget _buildTextField(String hint) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.border)),
      child: TextField(decoration: InputDecoration(hintText: hint, hintStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 14), border: InputBorder.none, contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14))),
    );
  }

  Widget _buildTextArea(String hint) {
    return Container(
      height: 100,
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.border)),
      child: TextField(maxLines: null, expands: true, textAlignVertical: TextAlignVertical.top, decoration: InputDecoration(hintText: hint, hintStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 14), border: InputBorder.none, contentPadding: const EdgeInsets.all(16))),
    );
  }

  Widget _buildDropdown(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.border)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [Text(text, style: const TextStyle(fontSize: 14, color: AppColors.textMain)), const Icon(Icons.keyboard_arrow_down, color: AppColors.textSecondary)],
      ),
    );
  }

  Widget _buildPriorityChip(String label, bool isSelected, Color dotColor) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(color: isSelected ? const Color(0xFFD6E4FF) : Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: isSelected ? AppColors.textMain : AppColors.border, width: isSelected ? 1.5 : 1.0)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(width: 8, height: 8, decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Text(label, style: TextStyle(fontSize: 12, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, color: AppColors.textMain)),
        ],
      ),
    );
  }
}