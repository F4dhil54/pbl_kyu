import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
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
  final bool? isManager;
  const CreateTaskScreen({super.key, required this.projectId, this.taskToEdit, this.isManager});

  @override
  ConsumerState<CreateTaskScreen> createState() => _CreateTaskScreenState();
}

class _CreateTaskScreenState extends ConsumerState<CreateTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  final _judulController = TextEditingController();
  final _deskripsiController = TextEditingController();

  DateTime? _selectedDate;
  DateTime? _scheduledDate;
  bool _isHoliday = false;
  bool _isLoadingDate = false;
  bool _isSaving = false;

  // Failsafe timer: paksa reset _isSaving jika Supabase hang di Flutter Web
  Timer? _saveTimeoutTimer;

  // Flag untuk mencegah infinite loop: _resolveAssigneeNames hanya boleh
  // memicu setState SATU kali setelah nama berhasil diambil.
  bool _assigneesResolved = false;

  String _selectedPriority = 'Schedule'; // 'Do' | 'Schedule' | 'Delegate'
  bool _assignToAll = true;
  final List<Map<String, dynamic>> _selectedAssignees = [];
  final List<AttachmentModel> _attachments = [];
  final Map<String, Uint8List> _attachmentBytes = {};

  @override
  void initState() {
    super.initState();
    if (widget.taskToEdit != null) {
      _judulController.text = widget.taskToEdit!.judulTugas;
      _deskripsiController.text = widget.taskToEdit!.deskripsiTugas;
      _selectedPriority = widget.taskToEdit!.prioritas;
      _selectedDate = widget.taskToEdit!.deadlineDate;
      _scheduledDate = widget.taskToEdit!.scheduledFor;
      
      if (widget.taskToEdit!.projectTeamId != null) {
        _selectedAssignees.add({
          'type': 'team',
          'id': widget.taskToEdit!.projectTeamId,
          'user_id': null,
          'name': 'Loading Team...',
        });
        _assignToAll = false;
      }
      
      if (widget.taskToEdit!.assignees.isNotEmpty) {
        for (final uid in widget.taskToEdit!.assignees) {
          _selectedAssignees.add({
            'type': 'member',
            'id': '',
            'user_id': uid,
            'name': 'Loading Member...',
          });
        }
        _assignToAll = false;
      }
      
      if (_selectedAssignees.isEmpty) {
        _assignToAll = true;
      }
      
      _attachments.addAll(widget.taskToEdit!.attachments);
    }
  }

  @override
  void dispose() {
    _saveTimeoutTimer?.cancel();
    _judulController.dispose();
    _deskripsiController.dispose();
    super.dispose();
  }

  // Dipanggil SEKALI saat data members/teams sudah tersedia untuk edit mode.
  // Menggunakan flag _assigneesResolved agar TIDAK membuat infinite loop:
  // resolve → setState → rebuild → resolve → setState → rebuild ...
  void _resolveAssigneeNamesOnce(
    List<Map<String, dynamic>> membersList,
    List<Map<String, dynamic>> teamsList,
  ) {
    // Sudah resolved? Jangan setState lagi — ini mencegah infinite loop.
    if (_assigneesResolved) return;

    // Tidak perlu resolve jika tidak ada yang perlu diisi
    final hasUnresolved = _selectedAssignees.any((item) => item['name'].toString().startsWith('Loading'));
    if (!hasUnresolved) {
      _assigneesResolved = true;
      return;
    }

    bool updated = false;
    for (int i = 0; i < _selectedAssignees.length; i++) {
      final item = _selectedAssignees[i];
      if (item['name'].toString().startsWith('Loading')) {
        if (item['type'] == 'team') {
          final matchedTeam = teamsList.firstWhere(
            (t) => t['id'] == item['id'] || t['team_id'] == item['id'],
            orElse: () => {},
          );
          if (matchedTeam.isNotEmpty) {
            _selectedAssignees[i] = {
              'type': 'team',
              'id': matchedTeam['id'],
              'user_id': null,
              'name': matchedTeam['nama_tim'],
            };
            updated = true;
          }
        } else {
          final matchedMember = membersList.firstWhere(
            (m) => m['member_id'] == item['id'] || m['user_id'] == item['user_id'],
            orElse: () => {},
          );
          if (matchedMember.isNotEmpty) {
            _selectedAssignees[i] = {
              'type': 'member',
              'id': matchedMember['member_id'],
              'user_id': matchedMember['user_id'],
              'name': matchedMember['nama'],
            };
            updated = true;
          }
        }
      }
    }

    if (updated) {
      // Tandai sudah resolved SEBELUM addPostFrameCallback agar rebuild
      // berikutnya tidak masuk ke sini lagi.
      _assigneesResolved = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() {});
      });
    } else {
      // Tidak ada yang cocok tapi juga tidak perlu loop lagi
      _assigneesResolved = true;
    }
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
        if (!context.mounted) return;
        final TimeOfDay? pickedTime = await showTimePicker(
          context: context,
          initialTime: const TimeOfDay(hour: 23, minute: 59),
        );

        if (pickedTime != null) {
          final combinedDate = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
          
          setState(() {
            _selectedDate = combinedDate;
            _isLoadingDate = true;
            _isHoliday = false;
          });
          bool isMerah = await cekTanggalMerah(combinedDate);
          if (mounted) {
            setState(() {
              _isHoliday = isMerah;
              _isLoadingDate = false;
            });
          }
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
        // Hanya set tanggal jadwal di state form — TIDAK auto-save.
        // User harus menekan tombol "Ditugaskan" / "Simpan Draft" secara eksplisit.
        setState(() {
          _scheduledDate = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
          _selectedPriority = 'Schedule';
        });
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
                title: const Text('Ambil Foto (Kamera)'),
                onTap: () async {
                  Navigator.pop(context);
                  final picker = ImagePicker();
                  final pickedFile = await picker.pickImage(source: ImageSource.camera, imageQuality: 70, maxWidth: 1080);
                  if (pickedFile != null) {
                    final size = await pickedFile.length();
                    if (size > 5 * 1024 * 1024) {
                      if (mounted) {
                        ScaffoldMessenger.of(this.context).showSnackBar(
                          SnackBar(
                            content: const Text('Ukuran foto melebihi batas 5MB!'),
                            backgroundColor: AppColors.alertText,
                          ),
                        );
                      }
                      return;
                    }
                    final bytes = await pickedFile.readAsBytes();
                    setState(() {
                      _attachments.add(AttachmentModel(
                        id: '',
                        taskId: widget.taskToEdit?.id ?? '',
                        tipeLampiran: 'foto',
                        filePathOrUrl: pickedFile.path,
                        namaFile: pickedFile.name,
                      ));
                      _attachmentBytes[pickedFile.path] = bytes;
                    });
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library, color: AppColors.primary),
                title: const Text('Galeri Foto'),
                onTap: () async {
                  Navigator.pop(context);
                  final picker = ImagePicker();
                  final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70, maxWidth: 1080);
                  if (pickedFile != null) {
                    final size = await pickedFile.length();
                    if (size > 5 * 1024 * 1024) {
                      if (mounted) {
                        ScaffoldMessenger.of(this.context).showSnackBar(
                          SnackBar(
                            content: const Text('Ukuran foto melebihi batas 5MB!'),
                            backgroundColor: AppColors.alertText,
                          ),
                        );
                      }
                      return;
                    }
                    final bytes = await pickedFile.readAsBytes();
                    setState(() {
                      _attachments.add(AttachmentModel(
                        id: '',
                        taskId: widget.taskToEdit?.id ?? '',
                        tipeLampiran: 'foto',
                        filePathOrUrl: pickedFile.path,
                        namaFile: pickedFile.name,
                      ));
                      _attachmentBytes[pickedFile.path] = bytes;
                    });
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.file_present_rounded, color: AppColors.primary),
                title: const Text('Pilih Dokumen (PDF, Word, dll.)'),
                onTap: () async {
                  Navigator.pop(context);
                  final result = await FilePicker.platform.pickFiles(
                    type: FileType.custom,
                    allowedExtensions: ['pdf', 'doc', 'docx', 'xls', 'xlsx', 'txt'],
                  );
                  if (result != null) {
                    final size = result.files.single.size;
                    if (size > 5 * 1024 * 1024) {
                      if (mounted) {
                        ScaffoldMessenger.of(this.context).showSnackBar(
                          SnackBar(
                            content: const Text('Ukuran dokumen melebihi batas 5MB!'),
                            backgroundColor: AppColors.alertText,
                          ),
                        );
                      }
                      return;
                    }
                    final pathOrUrl = kIsWeb ? result.files.single.name : (result.files.single.path ?? result.files.single.name);
                    final bytes = result.files.single.bytes ?? (kIsWeb ? null : await XFile(result.files.single.path!).readAsBytes());
                    if (bytes != null) {
                      setState(() {
                        _attachments.add(AttachmentModel(
                          id: '',
                          taskId: widget.taskToEdit?.id ?? '',
                          tipeLampiran: 'file',
                          filePathOrUrl: pathOrUrl,
                          namaFile: result.files.single.name,
                        ));
                        _attachmentBytes[pathOrUrl] = bytes;
                      });
                    }
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

  // ============================================================
  // APPROVAL: Manajer menyetujui usulan Draft Tim → Tugas Aktif
  // ============================================================
  Future<void> _approveTimDraft() async {
    if (widget.taskToEdit == null) return;
    setState(() { _isSaving = true; });
    try {
      await ref.read(projectTaskListProvider(widget.projectId).notifier)
          .approveOrRejectTask(widget.taskToEdit!.id, 'Setujui', 'Akan Dikerjakan');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Usulan tugas disetujui dan kini aktif!'),
            backgroundColor: AppColors.successText,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menyetujui: $e'), backgroundColor: AppColors.alertText),
        );
      }
    } finally {
      if (mounted) setState(() { _isSaving = false; });
    }
  }

  // ============================================================
  // REJECTION: Manajer menolak usulan Draft Tim
  // ============================================================
  Future<void> _rejectTimDraft() async {
    if (widget.taskToEdit == null) return;
    // Tampilkan dialog konfirmasi sebelum menolak
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Tolak Usulan Tugas?'),
        content: Text('Usulan "${widget.taskToEdit!.judulTugas}" akan ditandai sebagai "Tidak Disetujui" dan anggota tim akan diberitahu.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Tolak Usulan', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    setState(() { _isSaving = true; });
    try {
      await ref.read(projectTaskListProvider(widget.projectId).notifier)
          .approveOrRejectTask(widget.taskToEdit!.id, 'Tidak Setujui', 'Ditinjau');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Usulan tugas ditolak.'),
            backgroundColor: AppColors.alertText,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menolak: $e'), backgroundColor: AppColors.alertText),
        );
      }
    } finally {
      if (mounted) setState(() { _isSaving = false; });
    }
  }

  // ============================================================
  // PUBLISH: Manajer menerbitkan draft-nya sendiri → Tugas Aktif
  // (seperti tombol "Tugaskan" di Google Classroom)
  // ============================================================
  Future<void> _tugaskanDraft() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    // Override _scheduledDate agar tidak masuk ke path 'scheduled'
    _scheduledDate = null;
    await _simpanTugas(false); // isDraft=false, scheduledDate=null → accept
  }

  Future<void> _simpanTugas(bool isDraft) async {
    final judul = _judulController.text.trim();
    final deskripsi = _deskripsiController.text.trim();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() { _isSaving = true; });

    // ── LAYER 1: Timer failsafe ─────────────────────────────────────────────
    // Jika Supabase hang di Flutter Web (HTTP browser tidak merespons),
    // Timer ini PAKSA reset _isSaving setelah 20 detik. Bekerja independen
    // dari async/await dan tidak bergantung pada event loop Supabase.
    _saveTimeoutTimer?.cancel();
    _saveTimeoutTimer = Timer(const Duration(seconds: 20), () {
      if (mounted && _isSaving) {
        setState(() { _isSaving = false; });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gagal menyimpan: koneksi ke server timeout. Silakan coba lagi.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    });

    final user = Supabase.instance.client.auth.currentUser;
    final isManager = widget.isManager ?? (user?.userMetadata?['role'] == 'Manajer');

    // =======================================================
    // LOGIKA STATUS TUGAS:
    // - Tim buat tugas → selalu 'review' (butuh persetujuan manajer)
    // - Manajer simpan draft → 'draft' (privat, hanya manajer)
    // - Manajer jadwalkan → 'scheduled'
    // - Manajer tugaskan langsung → 'accept' (tugas aktif)
    // =======================================================
    String statusTugas;
    String keputusanManajer;

    if (!isManager) {
      statusTugas = 'review';
      keputusanManajer = 'Menunggu';
    } else if (isDraft) {
      statusTugas = 'draft';
      keputusanManajer = 'Menunggu';
    } else if (_scheduledDate != null) {
      statusTugas = 'scheduled';
      keputusanManajer = 'Menunggu';
    } else {
      statusTugas = 'accept';
      keputusanManajer = 'Setujui';
    }

    // Determine assignees
    List<Map<String, dynamic>> assignees = [];
    if (isManager) {
      if (_assignToAll) {
        final membersList = ref.read(projectMembersProvider(widget.projectId)).value ?? [];
        assignees = membersList.map((m) => {
          'user_id': m['user_id'] as String,
          'project_member_id': m['member_id'] as String,
          'project_team_id': null,
          'name': m['nama'] as String,
        }).toList();
      } else {
        assignees = _selectedAssignees.map((a) => {
          'user_id': a['user_id'],
          'project_member_id': a['type'] == 'member' ? a['id'] : null,
          'project_team_id': a['type'] == 'team' ? a['id'] : null,
          'name': a['name'],
        }).toList();
      }
    }

    String? resolvedTeamId;
    for (final a in assignees) {
      if (a['project_team_id'] != null) {
        resolvedTeamId = a['project_team_id'] as String?;
        break;
      }
    }

    String? resolvedMemberId;
    for (final a in assignees) {
      if (a['project_member_id'] != null) {
        resolvedMemberId = a['project_member_id'] as String?;
        break;
      }
    }

    // Upload attachments that have local bytes
    final List<AttachmentModel> uploadedAttachments = [];
    for (final att in _attachments) {
      if (_attachmentBytes.containsKey(att.filePathOrUrl)) {
        final bytes = _attachmentBytes[att.filePathOrUrl]!;
        try {
          final publicUrl = await ref.read(projectTaskListProvider(widget.projectId).notifier)
              .uploadAttachmentFile(bytes, att.namaFile);
          uploadedAttachments.add(AttachmentModel(
            id: att.id,
            taskId: att.taskId,
            logId: att.logId,
            tipeLampiran: att.tipeLampiran,
            filePathOrUrl: publicUrl,
            namaFile: att.namaFile,
          ));
        } catch (e) {
          debugPrint("Failed uploading attachment: $e");
          uploadedAttachments.add(att);
        }
      } else {
        uploadedAttachments.add(att);
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
      dibuatOlehRole: widget.taskToEdit?.dibuatOlehRole ?? (isManager ? 'Manajer' : 'Tim'),
      keputusanManajer: keputusanManajer,
      prioritas: isManager ? _selectedPriority : 'Schedule',
      deadlineDate: _selectedDate,
      scheduledFor: _scheduledDate,
      assignees: assignees.map((a) => (a['user_id'] ?? '') as String).where((uid) => uid.isNotEmpty).toList(),
      attachments: uploadedAttachments,
      projectTeamId: resolvedTeamId,
      projectMemberId: resolvedMemberId,
    );

    try {
      // ── LAYER 2: Future.timeout(15s) ────────────────────────────────────
      // Jika notifier tidak menyelesaikan operasi dalam 15 detik,
      // lempar exception ke catch block sehingga finally pasti jalan.
      if (widget.taskToEdit != null) {
        await ref.read(projectTaskListProvider(widget.projectId).notifier)
            .editTask(task, assignees)
            .timeout(
              const Duration(seconds: 15),
              onTimeout: () => throw Exception('Koneksi timeout. Coba lagi.'),
            );
      } else {
        await ref.read(projectTaskListProvider(widget.projectId).notifier)
            .addTask(task, assignees)
            .timeout(
              const Duration(seconds: 15),
              onTimeout: () => throw Exception('Koneksi timeout. Coba lagi.'),
            );
      }

      if (mounted) {
        String successMsg;
        if (!isManager) {
          successMsg = 'Usulan tugas berhasil dikirim! Menunggu persetujuan manajer.';
        } else if (isDraft) {
          successMsg = 'Draft berhasil disimpan!';
        } else if (_scheduledDate != null) {
          successMsg = 'Tugas berhasil dijadwalkan!';
        } else {
          successMsg = widget.taskToEdit != null ? 'Tugas berhasil diperbarui!' : 'Tugas berhasil ditugaskan!';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(successMsg), backgroundColor: AppColors.successText),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menyimpan tugas: ${e.toString().replaceAll("Exception: ", "")}'),
            backgroundColor: AppColors.alertText,
          ),
        );
      }
    } finally {
      // Batalkan timer failsafe dan selalu reset _isSaving
      _saveTimeoutTimer?.cancel();
      if (mounted) {
        setState(() { _isSaving = false; });
      }
    }
  }

  @override
  Widget build(BuildContext context) {

    final user = Supabase.instance.client.auth.currentUser;
    final isManager = widget.isManager ?? (user?.userMetadata?['role'] == 'Manajer');
    final membersAsync = ref.watch(projectMembersProvider(widget.projectId));
    final teamsAsync = ref.watch(projectTeamsProvider(widget.projectId));

    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeControl.themeNotifier,
      builder: (context, currentMode, child) {
        bool isDark = currentMode == ThemeMode.dark;

        return Scaffold(
          backgroundColor: isDark ? AppDarkColors.background : AppColors.background,
          appBar: AppBar(
            backgroundColor: isDark ? AppDarkColors.background : Colors.white,
            elevation: 0,
            scrolledUnderElevation: 0,
            shape: Border(
              bottom: BorderSide(
                color: isDark ? AppDarkColors.border : const Color(0xFFEEEEEE),
                width: 0.5,
              ),
            ),
            leading: IconButton(
              icon: Icon(
                Icons.arrow_back_ios_new_rounded,
                color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                size: 20,
              ),
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
              // ── KONTEKS 1: Manajer melihat usulan Draft Tim ──────────────────
              if (isManager && widget.taskToEdit != null &&
                  widget.taskToEdit!.dibuatOlehRole == 'Tim' &&
                  widget.taskToEdit!.statusTugas == 'Ditinjau') ...[
                if (_isSaving)
                  const Padding(
                    padding: EdgeInsets.only(right: 16),
                    child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))),
                  )
                else ...[
                  // Tombol Tolak (merah)
                  TextButton(
                    onPressed: _rejectTimDraft,
                    style: TextButton.styleFrom(foregroundColor: Colors.red),
                    child: const Text('Tolak', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  // Tombol Setujui (hijau) — seperti "Tugaskan" Google Classroom
                  Padding(
                    padding: const EdgeInsets.only(right: 12, left: 4),
                    child: ElevatedButton(
                      onPressed: _approveTimDraft,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.successText,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        elevation: 0,
                      ),
                      child: const Text('Setujui', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ]
              // ── KONTEKS 2: Manajer edit draft miliknya sendiri ───────────────
              else if (isManager && widget.taskToEdit != null &&
                  widget.taskToEdit!.dibuatOlehRole == 'Manajer' &&
                  widget.taskToEdit!.statusTugas == 'Draft') ...[
                if (_isSaving)
                  const Padding(
                    padding: EdgeInsets.only(right: 16),
                    child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))),
                  )
                else ...[
                  // Tombol TUGASKAN — seperti Google Classroom (biru, prominent)
                  Padding(
                    padding: const EdgeInsets.only(right: 4, left: 4),
                    child: ElevatedButton(
                      onPressed: _tugaskanDraft,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        elevation: 0,
                      ),
                      child: const Text('Tugaskan', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  // Popup: hanya Jadwalkan (Simpan Draft sudah ada di tombol bawah)
                  PopupMenuButton<String>(
                    icon: Icon(Icons.more_vert, color: isDark ? AppDarkColors.textMain : AppColors.textMain),
                    onSelected: (value) {
                      if (value == 'schedule') _pilihTanggalJadwal(context);
                    },
                    itemBuilder: (context) => [
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
                ],
              ]
              // ── KONTEKS 3: Manajer membuat tugas baru atau edit tugas aktif ──
              else if (isManager) ...[
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
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  () {
                    if (widget.taskToEdit != null) {
                      if (isManager && widget.taskToEdit!.dibuatOlehRole == 'Tim' && widget.taskToEdit!.statusTugas == 'Ditinjau') {
                        return 'Tinjau Usulan Tim';
                      } else if (isManager && widget.taskToEdit!.statusTugas == 'Draft') {
                        return 'Edit Draft Tugas';
                      }
                      return 'Edit Tugas';
                    }
                    return isManager ? 'Tambah Tugas Baru' : 'Usulkan Tugas Baru';
                  }(),
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: isDark ? AppDarkColors.textMain : AppColors.textMain),
                ),
                const SizedBox(height: 8),
                Text(
                  () {
                    if (isManager && widget.taskToEdit != null && widget.taskToEdit!.dibuatOlehRole == 'Tim' && widget.taskToEdit!.statusTugas == 'Ditinjau') {
                      return 'Review usulan dari anggota tim. Setujui untuk menjadikannya tugas aktif.';
                    } else if (isManager && widget.taskToEdit != null && widget.taskToEdit!.statusTugas == 'Draft') {
                      return 'Draft tersimpan privat. Tekan "Tugaskan" di atas untuk menerbitkan ke tim.';
                    }
                    return isManager
                        ? 'Detailkan parameter proyek dan tentukan pelaksana tugas.'
                        : 'Ajukan usulan tugas baru ke Manajer Workspace untuk disetujui.';
                  }(),
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
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildInputLabel('JUDUL TUGAS *', isDark),
                        _buildTextField(
                          'Masukkan judul koordinasi...', 
                          isDark, 
                          _judulController,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Judul tugas tidak boleh kosong';
                            }
                            if (value.trim().length < 3) {
                              return 'Judul tugas minimal 3 karakter';
                            }
                            return null;
                          },
                        ),
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
                              return teamsAsync.when(
                                loading: () => const Center(child: CircularProgressIndicator()),
                                error: (err, stack) => Text('Gagal memuat tim: $err', style: const TextStyle(color: Colors.red)),
                                data: (teamsList) {
                                  // Resolve initial loaded/editing assignee names (hanya sekali)
                                  _resolveAssigneeNamesOnce(membersList, teamsList);

                                  if (membersList.isEmpty && teamsList.isEmpty) {
                                    return const Text('Tidak ada anggota atau tim proyek tersedia.', style: TextStyle(color: Colors.grey, fontSize: 13));
                                  }

                                  final List<DropdownMenuItem<String>> dropdownItems = [];
                                  
                                  for (final m in membersList) {
                                    dropdownItems.add(DropdownMenuItem(
                                      value: 'member_${m['member_id']}',
                                      child: Row(
                                        children: [
                                          const Icon(Icons.person, size: 18, color: Colors.blue),
                                          const SizedBox(width: 8),
                                          Text(m['nama'] as String, style: TextStyle(color: isDark ? Colors.white : Colors.black)),
                                        ],
                                      ),
                                    ));
                                  }

                                  for (final t in teamsList) {
                                    dropdownItems.add(DropdownMenuItem(
                                      value: 'team_${t['id']}',
                                      child: Row(
                                        children: [
                                          const Icon(Icons.group, size: 18, color: Colors.amber),
                                          const SizedBox(width: 8),
                                          Text(t['nama_tim'] as String, style: TextStyle(color: isDark ? Colors.white : Colors.black)),
                                        ],
                                      ),
                                    ));
                                  }

                                  return Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      DropdownButtonFormField<String>(
                                        initialValue: null,
                                        decoration: InputDecoration(
                                          labelText: 'Pilih Penerima Tugas (Anggota/Tim)',
                                          filled: true,
                                          fillColor: isDark ? AppDarkColors.background : Colors.grey[100],
                                          border: const OutlineInputBorder(),
                                        ),
                                        dropdownColor: isDark ? AppDarkColors.surface : Colors.white,
                                        items: dropdownItems,
                                        onChanged: (val) {
                                          if (val != null) {
                                            if (val.startsWith('member_')) {
                                              final memberId = val.substring('member_'.length);
                                              final m = membersList.firstWhere((x) => x['member_id'] == memberId);
                                              final alreadySelected = _selectedAssignees.any((a) => a['id'] == m['member_id']);
                                              if (!alreadySelected) {
                                                setState(() {
                                                  _selectedAssignees.add({
                                                    'type': 'member',
                                                    'id': m['member_id'],
                                                    'user_id': m['user_id'],
                                                    'name': m['nama'],
                                                  });
                                                });
                                              }
                                            } else if (val.startsWith('team_')) {
                                              final teamId = val.substring('team_'.length);
                                              final t = teamsList.firstWhere((x) => x['id'] == teamId);
                                              final alreadySelected = _selectedAssignees.any((a) => a['id'] == t['id']);
                                              if (!alreadySelected) {
                                                setState(() {
                                                  _selectedAssignees.add({
                                                    'type': 'team',
                                                    'id': t['id'],
                                                    'user_id': null,
                                                    'name': t['nama_tim'],
                                                  });
                                                });
                                              }
                                            }
                                          }
                                        },
                                      ),
                                      const SizedBox(height: 12),
                                      Wrap(
                                        spacing: 8,
                                        runSpacing: 8,
                                        children: _selectedAssignees.map((assignee) {
                                          final isTeam = assignee['type'] == 'team';
                                          return Chip(
                                            avatar: Icon(
                                              isTeam ? Icons.group : Icons.person,
                                              size: 14,
                                              color: isTeam ? Colors.amber[800] : Colors.blue[800],
                                            ),
                                            label: Text(assignee['name'] as String),
                                            backgroundColor: isDark ? AppDarkColors.background : Colors.grey[200],
                                            labelStyle: TextStyle(color: isDark ? Colors.white : Colors.black),
                                            deleteIcon: const Icon(Icons.close, size: 16),
                                            onDeleted: () {
                                              setState(() {
                                                _selectedAssignees.remove(assignee);
                                              });
                                            },
                                          );
                                        }).toList(),
                                      ),
                                    ],
                                  );
                                },
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
                              border: Border.all(color: _isHoliday ? AppColors.alertText.withValues(alpha: 0.5) : (isDark ? AppDarkColors.border : AppColors.border)),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _selectedDate == null ? 'Pilih tenggat waktu' : _formatIndonesianDateTime(_selectedDate!),
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
                              border: Border.all(color: AppColors.alertText.withValues(alpha: 0.3)),
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
                      const SizedBox(height: 6),
                      Text(
                        '* Maksimal ukuran lampiran adalah 5 MB.',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? AppDarkColors.textSecondary : AppColors.textSecondary,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      const SizedBox(height: 32),

                      // ── TOMBOL BAWAH: Context-aware ──────────────────────────
                      if (_isSaving)
                        const Center(child: CircularProgressIndicator())
                      
                      // KONTEKS A: Manajer meninjau usulan Draft Tim
                      // → Aksi (Tolak/Setujui) sudah ada di AppBar, tombol bawah hanya Batal
                      else if (isManager && widget.taskToEdit != null &&
                          widget.taskToEdit!.dibuatOlehRole == 'Tim' &&
                          widget.taskToEdit!.statusTugas == 'Ditinjau')
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: isDark ? AppDarkColors.border : AppColors.border),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            child: Text('Kembali', style: TextStyle(color: isDark ? AppDarkColors.textMain : AppColors.textMain)),
                          ),
                        )
                      
                      // KONTEKS B: Manajer edit draft miliknya sendiri
                      // → AppBar punya tombol "Tugaskan" & "Jadwalkan", tombol bawah = Simpan Draft
                      else if (isManager && widget.taskToEdit != null &&
                          widget.taskToEdit!.dibuatOlehRole == 'Manajer' &&
                          widget.taskToEdit!.statusTugas == 'Draft')
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
                              child: ElevatedButton.icon(
                                onPressed: () => _simpanTugas(true),
                                icon: const Icon(Icons.edit_document, size: 18, color: Colors.white),
                                label: const Text('Simpan Draft', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF6B7280),
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  elevation: 0,
                                ),
                              ),
                            ),
                          ],
                        )

                      // KONTEKS C: Default — Manajer buat tugas baru / edit tugas aktif / Tim usulkan
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
                                  () {
                                    if (!isManager) return 'Kirim Usulan';
                                    if (_scheduledDate != null) return 'Simpan Dijadwalkan';
                                    if (widget.taskToEdit != null) return 'Simpan Perubahan';
                                    return 'Ditugaskan';
                                  }(),
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
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

  Widget _buildTextField(String hint, bool isDark, TextEditingController controller, {String? Function(String?)? validator}) {
    return TextFormField(
      controller: controller,
      validator: validator,
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
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.red, width: 1.0),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.red, width: 2.0),
        ),
        errorStyle: const TextStyle(color: Colors.red, fontSize: 12),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  Widget _buildTextArea(String hint, bool isDark, TextEditingController controller, {String? Function(String?)? validator}) {
    return TextFormField(
      controller: controller,
      validator: validator,
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
      selectedColor: color.withValues(alpha: 0.2),
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
