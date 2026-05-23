import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/theme_mode.dart';
import '../../data/models/task_model.dart';
import '../../data/models/attachment_model.dart';
import '../providers/task_provider.dart';
import '../../../project/presentation/providers/project_provider.dart';

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

class CreateTaskScreen extends ConsumerStatefulWidget {
  final String projectId;
  final TaskModel? taskToEdit;
  const CreateTaskScreen({super.key, required this.projectId, this.taskToEdit});

  @override
  ConsumerState<CreateTaskScreen> createState() => _CreateTaskScreenState();
}

class _CreateTaskScreenState extends ConsumerState<CreateTaskScreen> {
  final _judulController = TextEditingController();
  final _deskripsiController = TextEditingController();

  DateTime? _selectedDate;
  DateTime? _scheduledDate;
  bool _isHoliday = false;
  bool _isLoadingDate = false;
  bool _isSaving = false;

  String _selectedPriority = 'Schedule'; // 'Do' | 'Schedule' | 'Delegate'
  bool _assignToAll = true;
  final List<String> _selectedMemberIds = [];
  final List<AttachmentModel> _attachments = [];

  @override
  void initState() {
    super.initState();
    if (widget.taskToEdit != null) {
      _judulController.text = widget.taskToEdit!.judulTugas;
      _deskripsiController.text = widget.taskToEdit!.deskripsiTugas;
      _selectedPriority = widget.taskToEdit!.prioritas;
      _selectedDate = widget.taskToEdit!.deadlineDate;
      _scheduledDate = widget.taskToEdit!.scheduledFor;
      _selectedMemberIds.addAll(widget.taskToEdit!.assignees);
      _assignToAll = widget.taskToEdit!.assignees.isEmpty;
      _attachments.addAll(widget.taskToEdit!.attachments);
    }
  }

  @override
  void dispose() {
    _judulController.dispose();
    _deskripsiController.dispose();
    super.dispose();
  }

  String _formatIndonesianDateOnly(DateTime? date) {
    if (date == null) return '';
    const months = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  String _formatIndonesianDateTime(DateTime? date) {
    if (date == null) return '';
    const months = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];
    final hourStr = date.hour.toString().padLeft(2, '0');
    final minuteStr = date.minute.toString().padLeft(2, '0');
    return '${date.day} ${months[date.month - 1]} ${date.year} pukul $hourStr:$minuteStr';
  }

  Future<void> _pilihTanggal(BuildContext context, bool isScheduled) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
    );

    if (pickedDate != null) {
      if (isScheduled) {
        if (!context.mounted) return;
        final TimeOfDay? pickedTime = await showTimePicker(
          context: context,
          initialTime: TimeOfDay.now(),
        );

        if (pickedTime != null) {
          setState(() {
            _scheduledDate = DateTime(
              pickedDate.year,
              pickedDate.month,
              pickedDate.day,
              pickedTime.hour,
              pickedTime.minute,
            );
          });
        }
      } else {
        setState(() {
          _selectedDate = pickedDate;
          _isLoadingDate = true;
          _isHoliday = false;
        });
        bool isMerah = await cekTanggalMerah(pickedDate);
        if (mounted) {
          setState(() {
            _isHoliday = isMerah;
            _isLoadingDate = false;
          });
        }
      }
    }
  }

  Future<void> _pilihTanggalJadwal(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
    );

    if (pickedDate != null) {
      if (!context.mounted) return;
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );

      if (pickedTime != null) {
        setState(() {
          _scheduledDate = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
          _selectedPriority = 'Schedule'; // Force schedule priority
        });
        
        // Auto-save task as scheduled
        _simpanTugas(false);
      }
    }
  }

  void _tambahLampiran() {
    final isDark = ThemeControl.themeNotifier.value == ThemeMode.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppDarkColors.surface : Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt, color: AppColors.primary),
                title: const Text('Ambil Foto'),
                onTap: () async {
                  Navigator.pop(context);
                  final picker = ImagePicker();
                  final pickedFile = await picker.pickImage(source: ImageSource.camera);
                  if (pickedFile != null) {
                    setState(() {
                      _attachments.add(AttachmentModel(
                        id: '',
                        taskId: widget.taskToEdit?.id ?? '',
                        tipeLampiran: 'foto',
                        filePathOrUrl: pickedFile.path,
                        namaFile: pickedFile.name,
                      ));
                    });
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.file_upload, color: AppColors.primary),
                title: const Text('Upload File'),
                onTap: () async {
                  Navigator.pop(context);
                  final picker = ImagePicker();
                  final pickedFile = await picker.pickImage(source: ImageSource.gallery);
                  if (pickedFile != null) {
                    setState(() {
                      _attachments.add(AttachmentModel(
                        id: '',
                        taskId: widget.taskToEdit?.id ?? '',
                        tipeLampiran: 'file',
                        filePathOrUrl: pickedFile.path,
                        namaFile: pickedFile.name,
                      ));
                    });
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.link, color: AppColors.primary),
                title: const Text('Sisipkan Link'),
                onTap: () {
                  Navigator.pop(context);
                  _showLinkInputDialog();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showLinkInputDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Sisipkan Link'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              hintText: 'Masukkan URL',
              labelText: 'URL Link',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () {
                final url = controller.text.trim();
                if (url.isNotEmpty) {
                  setState(() {
                    _attachments.add(AttachmentModel(
                      id: '',
                      taskId: widget.taskToEdit?.id ?? '',
                      tipeLampiran: 'link',
                      filePathOrUrl: url,
                      namaFile: url.length > 30 ? '${url.substring(0, 30)}...' : url,
                    ));
                  });
                }
                Navigator.pop(context);
              },
              child: const Text('Simpan'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _simpanTugas(bool isDraft) async {
    final judul = _judulController.text.trim();
    final deskripsi = _deskripsiController.text.trim();

    if (judul.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Judul tugas tidak boleh kosong!')),
      );
      return;
    }

    setState(() { _isSaving = true; });

    final user = Supabase.instance.client.auth.currentUser;
    final role = user?.userMetadata?['role'] ?? 'Tim';
    final isManager = role == 'Manajer';

    // Determine status
    String statusTugas = 'Akan Dikerjakan';
    if (isDraft) {
      statusTugas = 'draft';
    } else if (isManager && _scheduledDate != null) {
      statusTugas = 'scheduled';
    }

    // Determine assignees
    List<String> assignees = [];
    if (isManager) {
      if (_assignToAll) {
        final membersList = ref.read(projectMembersProvider(widget.projectId)).value ?? [];
        assignees = membersList.map((m) => m['user_id'] as String).toList();
      } else {
        assignees = List<String>.from(_selectedMemberIds);
      }
    }

    final task = TaskModel(
      id: widget.taskToEdit?.id ?? '',
      projectId: widget.projectId,
      createdBy: widget.taskToEdit?.createdBy ?? (user?.id ?? ''),
      judulTugas: judul,
      deskripsiTugas: deskripsi,
      kuadranEisenhower: isManager ? _selectedPriority : 'Schedule',
      statusTugas: statusTugas,
      durasiPomodoro: widget.taskToEdit?.durasiPomodoro ?? 25,
      dibuatOlehRole: widget.taskToEdit?.dibuatOlehRole ?? role,
      keputusanManajer: widget.taskToEdit?.keputusanManajer ?? (isManager ? 'Setujui' : 'Menunggu'),
      prioritas: isManager ? _selectedPriority : 'Schedule',
      deadlineDate: _selectedDate,
      scheduledFor: isManager && _scheduledDate != null ? _scheduledDate : null,
      assignees: assignees,
      attachments: _attachments,
    );

    try {
      if (widget.taskToEdit != null) {
        await ref.read(projectTaskListProvider(widget.projectId).notifier).editTask(task, assignees);
      } else {
        await ref.read(projectTaskListProvider(widget.projectId).notifier).addTask(task, assignees);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.taskToEdit != null 
                ? 'Tugas berhasil diperbarui!' 
                : (isDraft ? 'Draft berhasil disimpan!' : 'Tugas berhasil disimpan!')),
            backgroundColor: AppColors.successText,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menyimpan tugas: $e'), backgroundColor: AppColors.alertText),
        );
      }
    } finally {
      if (mounted) {
        setState(() { _isSaving = false; });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    final role = user?.userMetadata?['role'] ?? 'Tim';
    final isManager = role == 'Manajer';
    final membersAsync = ref.watch(projectMembersProvider(widget.projectId));

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
              if (isManager)
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert, color: isDark ? AppDarkColors.textMain : AppColors.textMain),
                  onSelected: (value) {
                    if (value == 'draft') {
                      _simpanTugas(true);
                    } else if (value == 'schedule') {
                      _pilihTanggalJadwal(context);
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'draft',
                      child: Row(
                        children: [
                          Icon(Icons.edit_document, size: 18),
                          SizedBox(width: 8),
                          Text('Simpan sebagai Draft'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'schedule',
                      child: Row(
                        children: [
                          Icon(Icons.schedule, size: 18),
                          SizedBox(width: 8),
                          Text('Jadwalkan'),
                        ],
                      ),
                    ),
                  ],
                ),
              const SizedBox(width: 12),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.taskToEdit != null
                      ? 'Edit Tugas'
                      : (isManager ? 'Tambah Tugas Baru' : 'Usulkan Tugas Baru'),
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: isDark ? AppDarkColors.textMain : AppColors.textMain),
                ),
                const SizedBox(height: 8),
                Text(
                  isManager 
                      ? 'Detailkan parameter proyek dan tentukan pelaksana tugas.'
                      : 'Ajukan usulan tugas baru ke Manajer Workspace untuk disetujui.',
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
                      _buildInputLabel('JUDUL TUGAS', isDark),
                      _buildTextField('Masukkan judul koordinasi...', isDark, _judulController),
                      const SizedBox(height: 20),

                      _buildInputLabel('DESKRIPSI TUGAS', isDark),
                      _buildTextArea('Jelaskan secara singkat tujuan, ruang lingkup, dan target hasil tugas...', isDark, _deskripsiController),
                      const SizedBox(height: 20),

                      if (isManager) ...[
                        _buildInputLabel('Ditugaskan ke', isDark),
                        Row(
                          children: [
                            Checkbox(
                              value: _assignToAll,
                              activeColor: AppColors.primary,
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() {
                                    _assignToAll = val;
                                  });
                                }
                              },
                            ),
                            Text(
                              'Semua Anggota Proyek',
                              style: TextStyle(
                                fontSize: 14,
                                color: isDark ? AppDarkColors.textMain : AppColors.textMain,
                              ),
                            ),
                          ],
                        ),
                        if (!_assignToAll) ...[
                          const SizedBox(height: 8),
                          membersAsync.when(
                            loading: () => const Center(child: CircularProgressIndicator()),
                            error: (err, stack) => Text('Gagal memuat anggota: $err', style: const TextStyle(color: Colors.red)),
                            data: (membersList) {
                              if (membersList.isEmpty) {
                                return const Text('Tidak ada anggota proyek tersedia.', style: TextStyle(color: Colors.grey, fontSize: 13));
                              }
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  DropdownButtonFormField<String>(
                                    decoration: InputDecoration(
                                      labelText: 'Pilih Anggota',
                                      filled: true,
                                      fillColor: isDark ? AppDarkColors.background : Colors.grey[100],
                                      border: const OutlineInputBorder(),
                                    ),
                                    dropdownColor: isDark ? AppDarkColors.surface : Colors.white,
                                    items: membersList.map<DropdownMenuItem<String>>((m) {
                                      final userId = m['user_id'] as String;
                                      final nama = m['nama'] as String;
                                      return DropdownMenuItem<String>(
                                        value: userId,
                                        child: Text(nama, style: TextStyle(color: isDark ? Colors.white : Colors.black)),
                                      );
                                    }).toList(),
                                    onChanged: (userId) {
                                      if (userId != null && !_selectedMemberIds.contains(userId)) {
                                        setState(() {
                                          _selectedMemberIds.add(userId);
                                        });
                                      }
                                    },
                                  ),
                                  const SizedBox(height: 12),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: _selectedMemberIds.map((userId) {
                                      final member = membersList.firstWhere(
                                        (m) => m['user_id'] == userId,
                                        orElse: () => {'nama': 'User'},
                                      );
                                      final name = member['nama'] as String;
                                      return Chip(
                                        label: Text(name),
                                        backgroundColor: isDark ? AppDarkColors.background : Colors.grey[200],
                                        labelStyle: TextStyle(color: isDark ? Colors.white : Colors.black),
                                        deleteIcon: const Icon(Icons.close, size: 16),
                                        onDeleted: () {
                                          setState(() {
                                            _selectedMemberIds.remove(userId);
                                          });
                                        },
                                      );
                                    }).toList(),
                                  ),
                                ],
                              );
                            },
                          ),
                        ],
                        const SizedBox(height: 20),

                        _buildInputLabel('Prioritas Eisenhower', isDark),
                        Row(
                          children: [
                            Expanded(child: _buildPriorityChip('Do', 'Do', AppColors.alertText, isDark)),
                            const SizedBox(width: 8),
                            Expanded(child: _buildPriorityChip('Schedule', 'Schedule', AppColors.warningText, isDark)),
                            const SizedBox(width: 8),
                            Expanded(child: _buildPriorityChip('Delegate', 'Delegate', AppColors.primary, isDark)),
                          ],
                        ),
                        const SizedBox(height: 20),

                        _buildInputLabel('Tenggat Waktu (Deadline)', isDark),
                        GestureDetector(
                          onTap: () => _pilihTanggal(context, false),
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
                                  _selectedDate == null ? 'Pilih tenggat waktu' : _formatIndonesianDateOnly(_selectedDate!),
                                  style: TextStyle(color: _selectedDate == null ? (isDark ? AppDarkColors.textSecondary : AppColors.textSecondary) : (isDark ? AppDarkColors.textMain : AppColors.textMain)),
                                ),
                                if (_isLoadingDate)
                                  const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                                else
                                  Icon(Icons.calendar_today, size: 18, color: isDark ? AppDarkColors.textSecondary : AppDarkColors.textSecondary),
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
                                    const Icon(Icons.warning_amber_rounded, color: AppColors.alertText, size: 16),
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
                        const SizedBox(height: 20),

                        if (_scheduledDate != null) ...[
                          _buildInputLabel('Dijadwalkan Pada', isDark),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            decoration: BoxDecoration(
                              color: isDark ? AppDarkColors.background : Colors.grey[100],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: isDark ? AppDarkColors.border : AppColors.border),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _formatIndonesianDateTime(_scheduledDate!),
                                  style: TextStyle(color: isDark ? AppDarkColors.textMain : AppColors.textMain),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.close, size: 18, color: Colors.red),
                                  onPressed: () {
                                    setState(() {
                                      _scheduledDate = null;
                                    });
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],
                      ],

                      _buildInputLabel('LAMPIRAN TUGAS (OPSIONAL)', isDark),
                      if (_attachments.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Column(
                          children: _attachments.map((att) {
                            IconData icon;
                            if (att.tipeLampiran == 'foto') {
                              icon = Icons.camera_alt_outlined;
                            } else if (att.tipeLampiran == 'file') {
                              icon = Icons.file_present_outlined;
                            } else {
                              icon = Icons.link;
                            }
                            return Card(
                              color: isDark ? AppDarkColors.background : Colors.grey[100],
                              child: ListTile(
                                leading: Icon(icon, color: AppColors.primary),
                                title: Text(att.namaFile, maxLines: 1, overflow: TextOverflow.ellipsis),
                                subtitle: Text(att.tipeLampiran.toUpperCase(), style: const TextStyle(fontSize: 10)),
                                trailing: IconButton(
                                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                                  onPressed: () {
                                    setState(() {
                                      _attachments.remove(att);
                                    });
                                  },
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 12),
                      ],
                      OutlinedButton.icon(
                        onPressed: _tambahLampiran,
                        icon: const Icon(Icons.add_link),
                        label: const Text('Tambah Lampiran'),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.primary),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Buttons Row
                      if (_isSaving)
                        const Center(child: CircularProgressIndicator())
                      else
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
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () => _simpanTugas(false),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  elevation: 0,
                                ),
                                child: Text(
                                  isManager 
                                      ? (widget.taskToEdit != null ? 'Simpan Perubahan' : 'Ditugaskan') 
                                      : 'Kirim Usulan',
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInputLabel(String text, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: isDark ? AppDarkColors.textSecondary : AppColors.textSecondary,
          letterSpacing: 1,
        ),
      ),
    );
  }

  Widget _buildTextField(String hint, bool isDark, TextEditingController controller) {
    return TextField(
      controller: controller,
      style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: isDark ? AppDarkColors.textSecondary : AppColors.textSecondary),
        fillColor: isDark ? AppDarkColors.background : Colors.grey[50],
        filled: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: isDark ? AppDarkColors.border : AppColors.border),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  Widget _buildTextArea(String hint, bool isDark, TextEditingController controller) {
    return TextField(
      controller: controller,
      maxLines: 5,
      style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: isDark ? AppDarkColors.textSecondary : AppColors.textSecondary),
        fillColor: isDark ? AppDarkColors.background : Colors.grey[50],
        filled: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: isDark ? AppDarkColors.border : AppColors.border),
        ),
        contentPadding: const EdgeInsets.all(16),
      ),
    );
  }

  Widget _buildPriorityChip(String label, String value, Color color, bool isDark) {
    final isSelected = _selectedPriority == value;
    return ChoiceChip(
      label: Container(
        alignment: Alignment.center,
        child: Text(label),
      ),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _selectedPriority = value;
          });
        }
      },
      selectedColor: color.withOpacity(0.2),
      backgroundColor: isDark ? AppDarkColors.background : Colors.grey[100],
      labelStyle: TextStyle(
        color: isSelected ? color : (isDark ? AppDarkColors.textMain : AppColors.textMain),
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        fontSize: 12,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: isSelected ? color : Colors.transparent),
      ),
    );
  }
}