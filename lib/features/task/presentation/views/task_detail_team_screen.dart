import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/theme_mode.dart';
import 'package:pbl_kyu/shared/widgets/profile_avatar.dart';
import '../../data/models/task_model.dart';
import '../../data/models/attachment_model.dart';
import '../../../project/data/models/project_model.dart';
import '../providers/task_provider.dart';
import '../../../project/presentation/providers/project_provider.dart';
import 'team_progress_screen.dart';
import 'github_commits_screen.dart';


class TaskDetailTeamScreen extends ConsumerStatefulWidget {
  final TaskModel? task;
  final bool isReadOnly;
  const TaskDetailTeamScreen({super.key, this.task, this.isReadOnly = false});

  @override
  ConsumerState<TaskDetailTeamScreen> createState() => _TaskDetailTeamScreenState();
}

class _TaskDetailTeamScreenState extends ConsumerState<TaskDetailTeamScreen> {
  // Timer state
  Timer? _timer;
  int _secondsRemaining = 25 * 60; // 25 minutes default
  bool _isRunning = false;
  bool _isFocusSession = true; // Focus vs Break
  int _elapsedFocusSeconds = 0;
  DateTime? _startedAt;

  // Status & Attachment Form state
  String _selectedStatus = 'Akan Dikerjakan';
  String _attachmentType = 'link'; // 'foto' | 'file' | 'link'
  final _attachmentNameController = TextEditingController();
  final _attachmentPathController = TextEditingController();
  final _hambatanController = TextEditingController();
  final _catatanController = TextEditingController();
  bool _isUpdatingStatus = false;
  Uint8List? _pickedAttachmentBytes;

  // Fallback mock task if null
  late TaskModel _activeTask;

  String get _timerText {
    int minutes = _secondsRemaining ~/ 60;
    int seconds = _secondsRemaining % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  void initState() {
    super.initState();
    _initializeTask();
  }

  void _initializeTask() {
    if (widget.task != null) {
      _activeTask = widget.task!;
    } else {
      // Create a mock fallback task
      _activeTask = TaskModel(
        id: 'mock-task-id',
        projectId: 'mock-project-id',
        createdBy: 'mock-creator',
        judulTugas: 'Pengembangan Fitur Kolaborasi',
        deskripsiTugas: 'Optimasi authentication layer di dalam middleware. Pastikan sinkronisasi endpoint untuk fitur kolaborasi tim aman.',
        kuadranEisenhower: 'Do',
        statusTugas: 'Sedang Dikerjakan',
        durasiPomodoro: 25,
        dibuatOlehRole: 'Manajer',
        keputusanManajer: 'Setujui',
        prioritas: 'Do',
        deadlineDate: DateTime.now().add(const Duration(days: 2)),
        assignees: [],
        attachments: [],
      );
    }

    // Auto-aktivasi lokal jika scheduled_for sudah lewat
    final now = DateTime.now();
    if (_activeTask.statusTugas == 'Dijadwalkan' && 
        _activeTask.scheduledFor != null && 
        _activeTask.scheduledFor!.isBefore(now)) {
      _activeTask = _activeTask.copyWith(
        statusTugas: 'Akan Dikerjakan',
        keputusanManajer: 'Setujui',
      );
    }

    _selectedStatus = _activeTask.statusTugas;
  }

  void _startTimer() {
    final projects = ref.read(projectListProvider).value;
    ProjectModel? project;
    if (projects != null) {
      for (var p in projects) {
        if (p.id == _activeTask.projectId) {
          project = p;
          break;
        }
      }
    }
    
    if (project != null && project.isReadOnly) {
      final isDark = ThemeControl.themeNotifier.value == ThemeMode.dark;
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            backgroundColor: isDark ? AppDarkColors.surface : Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Text('Akses Dinonaktifkan'),
            content: const Text(
              'Akses Anda ke proyek ini dinonaktifkan oleh manajer. '
              'Anda tidak dapat mengerjakan tugas di proyek ini.'
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          );
        },
      );
      return;
    }

    final now = DateTime.now();
    if (_activeTask.statusTugas == 'Dijadwalkan' && 
        _activeTask.scheduledFor != null && 
        _activeTask.scheduledFor!.isAfter(now)) {
      final isDark = ThemeControl.themeNotifier.value == ThemeMode.dark;
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            backgroundColor: isDark ? AppDarkColors.surface : Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Text('Tugas Dijadwalkan'),
            content: const Text(
              'Tugas ini masih dijadwalkan dan belum aktif. '
              'Anggota tidak boleh mengerjakan tugas sebelum waktu mulai yang dijadwalkan.'
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          );
        },
      );
      return;
    }

    if (_activeTask.id.startsWith('local-')) {
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Tugas Belum Disimpan'),
            content: const Text(
              'Tugas ini belum tersimpan ke database. '
              'Pomodoro timer hanya dapat digunakan untuk tugas yang sudah disimpan di database Supabase!'
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          );
        },
      );
      return;
    }

    if (_isRunning) {
      _timer?.cancel();
      setState(() { _isRunning = false; });
    } else {
      if (_startedAt == null && _isFocusSession) {
        _startedAt = DateTime.now();
      }
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (_secondsRemaining > 0) {
          setState(() {
            _secondsRemaining--;
            if (_isFocusSession) {
              _elapsedFocusSeconds++;
            }
          });
        } else {
          _handleSessionFinished();
        }
      });
      setState(() { _isRunning = true; });
    }
  }

  void _handleSessionFinished() {
    _timer?.cancel();
    _isRunning = false;

    if (_isFocusSession) {
      // Focus session finished
      _showSessionDialog(
        title: 'Sesi Fokus Selesai!',
        message: 'Luar biasa, Anda telah menyelesaikan 25 menit fokus. Apakah Anda ingin memulai sesi istirahat 10 menit?',
        confirmText: 'Mulai Istirahat',
        onConfirm: () {
          setState(() {
            _isFocusSession = false;
            _secondsRemaining = 10 * 60; // 10 minutes
            _startTimer();
          });
        },
        onCancel: () {
          setState(() {
            _resetTimerState();
          });
        },
      );
    } else {
      // Break session finished
      _showSessionDialog(
        title: 'Sesi Istirahat Selesai!',
        message: 'Waktu istirahat habis. Siap untuk kembali fokus mengerjakan tugas Anda?',
        confirmText: 'Mulai Fokus',
        onConfirm: () {
          setState(() {
            _isFocusSession = true;
            _secondsRemaining = 25 * 60; // 25 minutes
            _startedAt = DateTime.now();
            _startTimer();
          });
        },
        onCancel: () {
          setState(() {
            _resetTimerState();
          });
        },
      );
    }
  }

  void _showSessionDialog({
    required String title,
    required String message,
    required String confirmText,
    required VoidCallback onConfirm,
    required VoidCallback onCancel,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                onCancel();
              },
              child: const Text('Nanti Saja', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                onConfirm();
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              child: Text(confirmText, style: const TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void _stopTimerAndLog() async {
    _timer?.cancel();
    setState(() { _isRunning = false; });

    if (_elapsedFocusSeconds > 0) {
      final durasiMenit = max(1, (_elapsedFocusSeconds / 60).round());
      final user = Supabase.instance.client.auth.currentUser;

      if (user != null && widget.task != null && !_activeTask.id.startsWith('local-')) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Mencatat sesi Pomodoro: $durasiMenit menit fokus...'),
            duration: const Duration(seconds: 1),
          ),
        );

        try {
          await ref.read(projectTaskListProvider(_activeTask.projectId).notifier).submitPomodoroSession(
            taskId: _activeTask.id,
            userId: user.id,
            durasiMenit: durasiMenit,
            status: 'completed',
            startedAt: _startedAt ?? DateTime.now().subtract(Duration(seconds: _elapsedFocusSeconds)),
            endedAt: DateTime.now(),
          );

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Sesi Pomodoro berhasil dicatat ke database!'),
                backgroundColor: AppColors.successText,
              ),
            );
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Gagal mencatat sesi: $e'), backgroundColor: AppColors.alertText),
            );
          }
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sesi simulasi: $durasiMenit menit fokus diselesaikan.'),
            backgroundColor: AppColors.successText,
          ),
        );
      }
    }

    setState(() {
      _resetTimerState();
    });
  }

  void _resetTimerState() {
    _secondsRemaining = 25 * 60;
    _isRunning = false;
    _isFocusSession = true;
    _elapsedFocusSeconds = 0;
    _startedAt = null;
  }

  Future<void> _updateTaskProgress() async {
    final projects = ref.read(projectListProvider).value;
    ProjectModel? project;
    if (projects != null) {
      for (var p in projects) {
        if (p.id == _activeTask.projectId) {
          project = p;
          break;
        }
      }
    }
    if (project != null && project.isReadOnly) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gagal: Akses Anda ke proyek ini dinonaktifkan oleh manajer.'),
          backgroundColor: AppColors.alertText,
        ),
      );
      return;
    }

    final now = DateTime.now();
    if (_activeTask.statusTugas == 'Dijadwalkan' && 
        _activeTask.scheduledFor != null && 
        _activeTask.scheduledFor!.isAfter(now)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gagal: Tugas belum aktif (masih dijadwalkan).'),
          backgroundColor: AppColors.alertText,
        ),
      );
      return;
    }

    setState(() { _isUpdatingStatus = true; });

    try {
      AttachmentModel? attachment;
      if (_attachmentPathController.text.trim().isNotEmpty) {
        String finalPathOrUrl = _attachmentPathController.text.trim();
        final name = _attachmentNameController.text.trim().isNotEmpty 
            ? _attachmentNameController.text.trim() 
            : (_attachmentType == 'link' ? 'Link URL' : 'File Lampiran');

        if (_pickedAttachmentBytes != null) {
          finalPathOrUrl = await ref.read(projectTaskListProvider(_activeTask.projectId).notifier)
              .uploadAttachmentFile(_pickedAttachmentBytes!, name);
        }

        attachment = AttachmentModel(
          id: '',
          taskId: _activeTask.id,
          tipeLampiran: _attachmentType,
          filePathOrUrl: finalPathOrUrl,
          namaFile: name,
        );
      }

      await ref.read(projectTaskListProvider(_activeTask.projectId).notifier).logProgress(
        taskId: _activeTask.id,
        status: _selectedStatus,
        catatan: _catatanController.text.trim().isNotEmpty ? _catatanController.text.trim() : null,
        persenSelesai: _selectedStatus == 'Selesai' ? 100 : (_selectedStatus == 'Sedang Dikerjakan' ? 50 : 0),
        attachment: attachment,
        hambatan: _hambatanController.text.trim().isNotEmpty ? _hambatanController.text.trim() : null,
      );

      _attachmentNameController.clear();
      _attachmentPathController.clear();
      _hambatanController.clear();
      _catatanController.clear();
      _pickedAttachmentBytes = null;

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Progress tugas berhasil diperbarui!'),
            backgroundColor: AppColors.successText,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memperbarui progress: $e'), backgroundColor: AppColors.alertText),
        );
      }
    } finally {
      if (mounted) {
        setState(() { _isUpdatingStatus = false; });
      }
    }
  }

  void _bukaTautan(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Tidak dapat membuka tautan: $url')),
        );
      }
    }
  }

  Widget buildAttachmentViewer(Map<String, dynamic> attachmentData) {
    final String rawUrlMedia = attachmentData['file_path_or_url'] ?? '';
    // Harmonize bucket name to lowercase 'task_attachments'
    final String urlMedia = rawUrlMedia.replaceAll('/TASK_ATTACHMENTS/', '/task_attachments/');
    final String tipe = attachmentData['tipe_lampiran'] ?? 'file';
    final String namaFile = attachmentData['nama_file'] ?? 'Lampiran';

    // KONDISI JIKA LAMPIRAN ADALAH FOTO/GAMBAR
    if (tipe == 'foto') {
      final session = Supabase.instance.client.auth.currentSession;
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          urlMedia,
          fit: BoxFit.cover,
          width: double.infinity,
          height: 200,
          headers: {
            if (session != null) 'Authorization': 'Bearer ${session.accessToken}',
          },
          // Handler pencegah aplikasi crash jika link rusak/terhapus di storage
          errorBuilder: (context, error, stackTrace) {
            return Container(
              color: Colors.grey[800],
              height: 200,
              child: const Center(
                child: Text(
                  "⚠️ Gagal memuat gambar (404/Restricted)",
                  style: TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
            );
          },
        ),
      );
    }

    // KONDISI JIKA LAMPIRAN ADALAH DOKUMEN/LINK GOOGLE DRIVE
    return ListTile(
      leading: const Icon(Icons.insert_drive_file, color: Colors.blue),
      title: Text(namaFile),
      subtitle: const Text("Klik untuk membuka tautan berkas"),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: () async {
        // Menggunakan library url_launcher untuk membuka file PDF/Link di browser luar
        final Uri url = Uri.parse(urlMedia);
        if (await canLaunchUrl(url)) {
          await launchUrl(url, mode: LaunchMode.externalApplication);
        }
      },
    );
  }

  void _pilihLampiranTim() {
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
                  final pickedFile = await picker.pickImage(source: ImageSource.camera);
                  if (pickedFile != null) {
                    final size = await pickedFile.length();
                    // ✅ 15MB limit: 15 × 1024 × 1024 = 15,728,640 bytes
                    if (size > 15728640) {
                      if (mounted) {
                        ScaffoldMessenger.of(this.context).showSnackBar(
                          const SnackBar(
                            content: Text('⚠️ Ukuran file terlalu besar! Maksimal lampiran adalah 15 MB.'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                      return;
                    }
                    final bytes = await pickedFile.readAsBytes();
                    setState(() {
                      _attachmentType = 'foto';
                      _attachmentPathController.text = pickedFile.path;
                      _attachmentNameController.text = pickedFile.name;
                      _pickedAttachmentBytes = bytes;
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
                  final pickedFile = await picker.pickImage(source: ImageSource.gallery);
                  if (pickedFile != null) {
                    final size = await pickedFile.length();
                    // ✅ 15MB limit: 15 × 1024 × 1024 = 15,728,640 bytes
                    if (size > 15728640) {
                      if (mounted) {
                        ScaffoldMessenger.of(this.context).showSnackBar(
                          const SnackBar(
                            content: Text('⚠️ Ukuran file terlalu besar! Maksimal lampiran adalah 15 MB.'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                      return;
                    }
                    final bytes = await pickedFile.readAsBytes();
                    setState(() {
                      _attachmentType = 'foto';
                      _attachmentPathController.text = pickedFile.path;
                      _attachmentNameController.text = pickedFile.name;
                      _pickedAttachmentBytes = bytes;
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
                    // ✅ 15MB limit: 15 × 1024 × 1024 = 15,728,640 bytes
                    if (size > 15728640) {
                      if (mounted) {
                        ScaffoldMessenger.of(this.context).showSnackBar(
                          const SnackBar(
                            content: Text('⚠️ Ukuran file terlalu besar! Maksimal lampiran adalah 15 MB.'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                      return;
                    }
                    final bytes = result.files.single.bytes ?? (kIsWeb ? null : await XFile(result.files.single.path!).readAsBytes());
                    if (bytes != null) {
                      setState(() {
                        _attachmentType = 'file';
                        _attachmentPathController.text = kIsWeb ? result.files.single.name : (result.files.single.path ?? result.files.single.name);
                        _attachmentNameController.text = result.files.single.name;
                        _pickedAttachmentBytes = bytes;
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
                  setState(() {
                    _pickedAttachmentBytes = null;
                  });
                  _showLinkInputDialogTim();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showLinkInputDialogTim() {
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
                    _attachmentType = 'link';
                    _attachmentPathController.text = url;
                    _attachmentNameController.text = url.length > 30 ? '${url.substring(0, 30)}...' : url;
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

  @override
  void dispose() {
    _timer?.cancel();
    _attachmentNameController.dispose();
    _attachmentPathController.dispose();
    _hambatanController.dispose();
    _catatanController.dispose();
    super.dispose();
  }

  Widget _buildSectionLabel(String text, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(top: 24.0, bottom: 8.0),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: isDark ? AppDarkColors.textSecondary : AppColors.textSecondary,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildManagerDetailBody(bool isDark, ProjectModel? project) {
    final membersAsync = ref.watch(projectMembersProvider(_activeTask.projectId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title card
        Text(
          _activeTask.taskNumber != null ? '#${_activeTask.taskNumber} ${_activeTask.judulTugas}' : _activeTask.judulTugas,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black,
            height: 1.3,
          ),
        ),
        const SizedBox(height: 16),

        _buildSectionLabel('Deskripsi Tugas', isDark),
        Text(
          _activeTask.deskripsiTugas,
          style: TextStyle(
            fontSize: 14,
            color: isDark ? AppDarkColors.textMain : AppColors.textMain,
            height: 1.6,
          ),
        ),
        const SizedBox(height: 12),

        _buildSectionLabel('Prioritas & Deadline', isDark),
        Row(
          children: [
            Chip(
              label: Text(_activeTask.prioritas.toUpperCase()),
              backgroundColor: _activeTask.prioritas == 'Do' 
                  ? Colors.red.withValues(alpha: 0.1) 
                  : (_activeTask.prioritas == 'Schedule' ? Colors.orange.withValues(alpha: 0.1) : Colors.blue.withValues(alpha: 0.1)),
              labelStyle: TextStyle(
                color: _activeTask.prioritas == 'Do' 
                    ? Colors.red 
                    : (_activeTask.prioritas == 'Schedule' ? Colors.orange : Colors.blue),
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
            const SizedBox(width: 8),
            Chip(
              avatar: const Icon(Icons.calendar_today, size: 14),
              label: Text(_activeTask.deadlineDate != null ? DateFormat('dd MMMM yyyy').format(_activeTask.deadlineDate!) : 'Tanpa Tenggat'),
              backgroundColor: isDark ? AppDarkColors.surface : Colors.grey[200],
              labelStyle: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 12),
            ),
          ],
        ),

        // Assigned members list
        _buildSectionLabel('Ditugaskan Ke', isDark),
        membersAsync.when(
          loading: () => const CircularProgressIndicator(),
          error: (err, stack) => Text('Error: $err'),
          data: (membersList) {
            final assignedMembers = membersList.where((m) => _activeTask.assignees.contains(m['user_id'])).toList();
            
            return ref.watch(projectTeamsProvider(_activeTask.projectId)).when(
              loading: () => const CircularProgressIndicator(),
              error: (err, stack) => Text('Error: $err'),
              data: (teamsList) {
                final assignedTeams = teamsList.where((t) => _activeTask.projectTeamId == t['id']).toList();
                
                if (assignedMembers.isEmpty && assignedTeams.isEmpty) {
                  return Text('Tidak ada anggota ditugaskan.', style: TextStyle(color: isDark ? Colors.white70 : Colors.black87, fontSize: 13));
                }
                
                return Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ...assignedTeams.map((t) {
                      return Chip(
                        avatar: CircleAvatar(
                          backgroundColor: Colors.amber.withValues(alpha: 0.2),
                          child: const Icon(Icons.group, color: Colors.amber, size: 14),
                        ),
                        label: Text(t['nama_tim'] ?? 'Tim'),
                        backgroundColor: isDark ? AppDarkColors.surface : Colors.grey[200],
                        labelStyle: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 12),
                      );
                    }),
                    ...assignedMembers.map((m) {
                      return Chip(
                        avatar: CircleAvatar(
                          backgroundColor: AppColors.primary.withValues(alpha: 0.2),
                          child: Text(m['nama'][0].toUpperCase(), style: const TextStyle(color: AppColors.primary, fontSize: 10)),
                        ),
                        label: Text(m['nama']),
                        backgroundColor: isDark ? AppDarkColors.surface : Colors.grey[200],
                        labelStyle: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 12),
                      );
                    }),
                  ],
                );
              },
            );
          },
        ),

        // Initial attachments
        _buildSectionLabel('Lampiran Tugas Awal', isDark),
        () {
          final initialAttachments = _activeTask.attachments.where((att) => att.logId == null).toList();
          if (initialAttachments.isEmpty) {
            return Text('Tidak ada lampiran tugas awal.', style: TextStyle(color: isDark ? Colors.white70 : Colors.black87, fontSize: 13));
          }
          return Column(
            children: initialAttachments.map((att) {
              return Card(
                color: isDark ? AppDarkColors.surface : Colors.white,
                clipBehavior: Clip.antiAlias,
                child: buildAttachmentViewer({
                  'file_path_or_url': att.filePathOrUrl,
                  'tipe_lampiran': att.tipeLampiran,
                  'nama_file': att.namaFile,
                }),
              );
            }).toList(),
          );
        }(),

        // GitHub repository
        if (project != null && project.githubRepo.isNotEmpty) ...[
          _buildSectionLabel('Repositori GitHub Proyek', isDark),
          InkWell(
            onTap: () => _bukaTautan(project.githubRepo),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? AppDarkColors.surface : Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: isDark ? AppDarkColors.border : AppColors.border, width: 0.5),
              ),
              child: Row(
                children: [
                  const Icon(Icons.link, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      project.githubRepo,
                      style: const TextStyle(color: AppColors.primary, decoration: TextDecoration.underline, fontSize: 13),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],

        _buildGithubCommitsSection(isDark),

        // Riwayat Progress Tim
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            _buildSectionLabel('Riwayat Progress Tim', isDark),
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: TextButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => TeamProgressScreen(task: _activeTask),
                    ),
                  );
                },
                icon: const Icon(Icons.history, size: 16, color: AppColors.primary),
                label: const Text(
                  'Lihat Progress Tim',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
          ],
        ),
        FutureBuilder<List<Map<String, dynamic>>>(
          future: ref.read(taskRepositoryProvider).getTaskProgressLogs(_activeTask.id),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
              return Text('Belum ada riwayat pembaruan status dari tim.', style: TextStyle(color: isDark ? Colors.white70 : Colors.black87, fontSize: 13));
            }
            final logs = snapshot.data!;
            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: logs.length,
              separatorBuilder: (context, index) => const Divider(height: 24),
              itemBuilder: (context, index) {
                final log = logs[index];
                final profile = log['profiles'] as Map<String, dynamic>? ?? {};
                final name = profile['nama'] ?? 'Anggota';
                final email = profile['email'] ?? '';
                final roleStr = profile['role'] ?? 'Tim';
                final date = DateTime.tryParse(log['created_at'] as String? ?? '')?.toLocal();
                final dateStr = date != null ? DateFormat('dd MMMM yyyy HH:mm').format(date) : '-';
                final attachments = log['task_attachments'] as List<dynamic>? ?? [];

                return InkWell(
                  onTap: () => _showProgressLogDetailDialog(context, log, isDark),
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 4.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CircleAvatar(
                              backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                              child: Text(name[0].toUpperCase(), style: const TextStyle(color: AppColors.primary)),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                  Text('$email • $roleStr', style: const TextStyle(fontSize: 10, color: Colors.grey)),
                                  const SizedBox(height: 6),
                                  Text(log['catatan'] ?? '', style: TextStyle(color: isDark ? Colors.white70 : Colors.black87, fontSize: 13)),
                                  Text('Progress Selesai: ${log['persen_selesai']}%', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                                  Text(dateStr, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                                ],
                              ),
                            ),
                          ],
                        ),
                        if (attachments.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Padding(
                            padding: const EdgeInsets.only(left: 52),
                            child: Column(
                              children: attachments.map<Widget>((att) {
                                return Card(
                                  color: isDark ? AppDarkColors.surface : Colors.grey[100],
                                  clipBehavior: Clip.antiAlias,
                                  child: buildAttachmentViewer(att as Map<String, dynamic>),
                                );
                              }).toList(),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }

  void _showProgressLogDetailDialog(BuildContext context, Map<String, dynamic> log, bool isDark) {
    final profile = log['profiles'] as Map<String, dynamic>? ?? {};
    final name = profile['nama'] ?? 'Anggota';
    final email = profile['email'] ?? '';
    final roleStr = profile['role'] ?? 'Tim';
    final date = DateTime.tryParse(log['created_at'] as String? ?? '')?.toLocal();
    final dateStr = date != null ? DateFormat('dd MMMM yyyy HH:mm').format(date) : '-';
    final attachments = log['task_attachments'] as List<dynamic>? ?? [];
    final hambatan = log['hambatan'] as String?;
    final statusProgress = log['status_progress'] as String? ?? 'Sedang Dikerjakan';

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: isDark ? AppDarkColors.surface : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const Icon(Icons.assignment_turned_in_outlined, color: AppColors.primary, size: 22),
              const SizedBox(width: 8),
              const Text(
                'Detail Progress Tugas',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark ? AppDarkColors.background : Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                          child: Text(name.isNotEmpty ? name[0].toUpperCase() : 'U', style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              Text('$email • $roleStr', style: const TextStyle(fontSize: 10, color: Colors.grey)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildSectionLabel('Catatan Progress', isDark),
                  Text(
                    log['catatan'] ?? '-',
                    style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 13, height: 1.5),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionLabel('Status', isDark),
                          Text(statusProgress, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionLabel('Persen Selesai', isDark),
                          Text('${log['persen_selesai']}%', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildSectionLabel('Tanggal Submit', isDark),
                  Text(dateStr, style: TextStyle(color: isDark ? Colors.white70 : Colors.black87, fontSize: 12)),
                  const SizedBox(height: 16),
                  _buildSectionLabel('Lampiran Progress', isDark),
                  if (attachments.isEmpty)
                    const Text('Tidak ada lampiran.', style: TextStyle(color: Colors.grey, fontSize: 12))
                  else
                    ...attachments.map<Widget>((att) {
                      return Card(
                        color: isDark ? AppDarkColors.background : Colors.grey[50],
                        margin: const EdgeInsets.only(bottom: 8),
                        clipBehavior: Clip.antiAlias,
                        child: buildAttachmentViewer(att as Map<String, dynamic>),
                      );
                    }),
                  if (hambatan != null && hambatan.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF4A1D1D) : const Color(0xFFFFF5F5),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: const [
                              Icon(Icons.warning_amber_rounded, color: Colors.red, size: 16),
                              SizedBox(width: 6),
                              Text(
                                'Hambatan / Kendala',
                                style: TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            hambatan,
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? const Color(0xFFFCA5A5) : Colors.red[900],
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Tutup', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTeamDetailBody(bool isDark, ProjectModel? project) {
    final bool isDone = _activeTask.statusTugas == 'Selesai';
    final Color priorityColor = isDone
        ? const Color(0xFF10B981)
        : (_activeTask.prioritas == 'Do'
            ? const Color(0xFFEF4444)
            : (_activeTask.prioritas == 'Schedule' ? const Color(0xFFF59E0B) : const Color(0xFF3B82F6)));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title & Priority Badge
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                _activeTask.taskNumber != null ? '#${_activeTask.taskNumber} ${_activeTask.judulTugas}' : _activeTask.judulTugas,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppDarkColors.textMain : AppColors.textMain,
                  height: 1.3,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: priorityColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: priorityColor.withValues(alpha: 0.3)),
              ),
              child: Text(
                isDone ? 'DONE' : _activeTask.prioritas.toUpperCase(),
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: priorityColor),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Icon(Icons.calendar_today, size: 14, color: isDark ? AppDarkColors.textSecondary : AppColors.textSecondary),
            const SizedBox(width: 6),
            Text(
              _activeTask.deadlineDate != null 
                  ? 'Tenggat: ${DateFormat('dd MMMM yyyy').format(_activeTask.deadlineDate!)}'
                  : 'Tanpa Tenggat',
              style: TextStyle(
                fontSize: 12,
                color: isDark ? AppDarkColors.textSecondary : AppColors.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        if (!widget.isReadOnly) ...[
          // Pomodoro Card
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: _isFocusSession ? AppColors.rank1Background : const Color(0xFF0F766E), // Focus Teal vs Break Cyan/Teal
              borderRadius: BorderRadius.circular(16),
              border: isDark ? Border.all(color: AppDarkColors.border, width: 1) : null,
            ),
            child: Stack(
              children: [
                Positioned(
                  right: -20,
                  top: -20,
                  child: Icon(
                    _isFocusSession ? Icons.timer_outlined : Icons.coffee_outlined,
                    size: 120,
                    color: Colors.white.withValues(alpha: 0.06),
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      _isFocusSession ? 'POMODORO FOCUS SESSION (25M)' : 'POMODORO BREAK SESSION (10M)',
                      style: const TextStyle(
                        color: Color(0xFFCBD5E1),
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _timerText,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 64,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -2,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _startTimer,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: _isFocusSession ? AppColors.rank1Background : const Color(0xFF0F766E),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              elevation: 0,
                            ),
                            child: Text(
                              _isRunning ? 'JEDA' : 'MULAI',
                              style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1),
                            ),
                          ),
                        ),
                        if (_isRunning || _elapsedFocusSeconds > 0) ...[
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton(
                              onPressed: _stopTimerAndLog,
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.white,
                                side: const BorderSide(color: Colors.white24, width: 1),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                              ),
                              child: const Text(
                                'BERHENTI',
                                style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],

        // Description
        _buildSectionLabel('Deskripsi Tugas', isDark),
        Text(
          _activeTask.deskripsiTugas,
          style: TextStyle(
            fontSize: 14,
            color: isDark ? AppDarkColors.textMain : AppColors.textMain,
            height: 1.6,
          ),
        ),

        // GitHub project repo
        if (project != null && project.githubRepo.isNotEmpty) ...[
          _buildSectionLabel('Repositori GitHub Proyek', isDark),
          InkWell(
            onTap: () => _bukaTautan(project.githubRepo),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? AppDarkColors.surface : Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: isDark ? AppDarkColors.border : AppColors.border, width: 0.5),
              ),
              child: Row(
                children: [
                  const Icon(Icons.link, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      project.githubRepo,
                      style: const TextStyle(color: AppColors.primary, decoration: TextDecoration.underline, fontSize: 13),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],

        _buildGithubCommitsSection(isDark),

        // Initial attachments
        _buildSectionLabel('Lampiran Tugas Awal', isDark),
        () {
          final initialAttachments = _activeTask.attachments.where((att) => att.logId == null).toList();
          if (initialAttachments.isEmpty) {
            return Text('Tidak ada lampiran tugas awal.', style: TextStyle(color: isDark ? Colors.white70 : Colors.black87, fontSize: 13));
          }
          return Column(
            children: initialAttachments.map((att) {
              return Card(
                color: isDark ? AppDarkColors.surface : Colors.white,
                clipBehavior: Clip.antiAlias,
                child: buildAttachmentViewer({
                  'file_path_or_url': att.filePathOrUrl,
                  'tipe_lampiran': att.tipeLampiran,
                  'nama_file': att.namaFile,
                }),
              );
            }).toList(),
          );
        }(),

        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Riwayat Progress Tim',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: isDark ? AppDarkColors.textMain : AppColors.textMain,
              ),
            ),
            TextButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TeamProgressScreen(task: _activeTask),
                  ),
                );
              },
              icon: const Icon(Icons.history, size: 16, color: AppColors.primary),
              label: const Text(
                'Lihat Progress',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        const Divider(),

        // Form Update Status Progress
        _buildSectionLabel('Pembaruan Status & Progress', isDark),
        if ((project != null && project.isReadOnly) || widget.isReadOnly)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? AppDarkColors.surface : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isDark ? AppDarkColors.border : AppColors.border, width: 0.5),
            ),
            child: Row(
              children: [
                const Icon(Icons.lock_outline, color: AppColors.alertText),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.isReadOnly 
                      ? 'Anda hanya dapat melihat detail tugas ini karena Anda bukan penerima tugas.'
                      : 'Anda tidak memiliki akses edit untuk proyek ini karena dinonaktifkan oleh manajer.',
                    style: TextStyle(
                      color: isDark ? AppDarkColors.textSecondary : AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          )
        else
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? AppDarkColors.surface : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isDark ? AppDarkColors.border : AppColors.border, width: 0.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionLabel('Status Tugas', isDark),
                DropdownButtonFormField<String>(
                  initialValue: _selectedStatus,
                  dropdownColor: isDark ? AppDarkColors.surface : Colors.white,
                  style: TextStyle(color: isDark ? Colors.white : Colors.black),
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'Akan Dikerjakan', child: Text('Akan Dikerjakan')),
                    DropdownMenuItem(value: 'Sedang Dikerjakan', child: Text('Sedang Dikerjakan')),
                    DropdownMenuItem(value: 'Selesai', child: Text('Selesai')),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _selectedStatus = val;
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),

                _buildSectionLabel('Catatan Progress (Opsional)', isDark),
                TextField(
                  controller: _catatanController,
                  maxLines: 2,
                  style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Tulis progress pekerjaan Anda (misal: mulai mengerjakan proses A...)',
                    hintStyle: TextStyle(color: isDark ? AppDarkColors.textSecondary : AppColors.textSecondary, fontSize: 13),
                    fillColor: isDark ? AppDarkColors.background : Colors.grey[50],
                    filled: true,
                    border: const OutlineInputBorder(),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                ),
                const SizedBox(height: 16),

                _buildSectionLabel('Hambatan / Kendala (Opsional)', isDark),
                TextField(
                  controller: _hambatanController,
                  maxLines: 2,
                  style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Tulis kendala jika ada...',
                    hintStyle: TextStyle(color: isDark ? AppDarkColors.textSecondary : AppColors.textSecondary, fontSize: 13),
                    fillColor: isDark ? AppDarkColors.background : Colors.grey[50],
                    filled: true,
                    border: const OutlineInputBorder(),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                ),
                const SizedBox(height: 16),

                _buildSectionLabel('Lampiran Progress (Opsional)', isDark),
                if (_attachmentPathController.text.isEmpty) ...[
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _pilihLampiranTim,
                          icon: const Icon(Icons.attach_file, size: 16),
                          label: const Text('Tambah Lampiran', style: TextStyle(fontSize: 12)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ] else ...[
                  Card(
                    color: isDark ? AppDarkColors.background : Colors.grey[100],
                    child: ListTile(
                      leading: Icon(
                        _attachmentType == 'foto'
                            ? Icons.camera_alt_outlined
                            : (_attachmentType == 'file' ? Icons.file_present_outlined : Icons.link),
                        color: AppColors.primary,
                      ),
                      title: Text(_attachmentNameController.text, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13)),
                      subtitle: Text(_attachmentType.toUpperCase(), style: const TextStyle(fontSize: 10)),
                      trailing: IconButton(
                        icon: const Icon(Icons.close, color: Colors.red),
                        onPressed: () {
                          setState(() {
                            _attachmentPathController.clear();
                            _attachmentNameController.clear();
                          });
                        },
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 24),

                if (_isUpdatingStatus)
                  const Center(child: CircularProgressIndicator())
                else
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _updateTaskProgress,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            elevation: 0,
                          ),
                          child: const Text('Simpan Perubahan', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.task != null) {
      final tasksList = ref.watch(projectTaskListProvider(widget.task!.projectId)).value ?? [];
      final foundTask = tasksList.firstWhere((t) => t.id == widget.task!.id, orElse: () => _activeTask);
      
      final now = DateTime.now();
      if (foundTask.statusTugas == 'Dijadwalkan' && 
          foundTask.scheduledFor != null && 
          foundTask.scheduledFor!.isBefore(now)) {
        _activeTask = foundTask.copyWith(
          statusTugas: 'Akan Dikerjakan',
          keputusanManajer: 'Setujui',
        );
      } else {
        _activeTask = foundTask;
      }
    }

    final projects = ref.watch(projectListProvider).value;
    ProjectModel? project;
    if (projects != null) {
      for (var p in projects) {
        if (p.id == _activeTask.projectId) {
          project = p;
          break;
        }
      }
    }

    final user = Supabase.instance.client.auth.currentUser;
    final role = user?.userMetadata?['role'] ?? 'Tim';
    final isManager = role == 'Manajer';

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
              Icon(
                Icons.search_rounded,
                color: isDark ? AppDarkColors.textSecondary : AppColors.textSecondary,
              ),
              const SizedBox(width: 16),
              const ProfileAvatarButton(),
              const SizedBox(width: 20),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Breadcrumb
                Row(
                  children: [
                    Icon(Icons.folder_open_outlined, size: 14, color: isDark ? AppDarkColors.textSecondary : AppColors.textSecondary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'PROYEK: ${project?.name.toUpperCase() ?? 'WORK WORKSPACE'}',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: isDark ? AppDarkColors.textSecondary : AppDarkColors.textSecondary,
                          letterSpacing: 1,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Conditional Layout based on Role
                if (isManager)
                  _buildManagerDetailBody(isDark, project)
                else
                  _buildTeamDetailBody(isDark, project),

                const SizedBox(height: 40),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildGithubCommitsSection(bool isDark) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: ref.read(taskRepositoryProvider).getTaskCommits(_activeTask.id),
      builder: (context, snapshot) {
        final commits = snapshot.data;
        final count = commits?.length ?? 0;
        final hasCommits = snapshot.hasData && count > 0;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _buildSectionLabel('Riwayat Commit GitHub', isDark),
                if (hasCommits)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: TextButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => GithubCommitsScreen(task: _activeTask),
                          ),
                        );
                      },
                      icon: const Icon(Icons.history, size: 16, color: AppColors.primary),
                      label: Text(
                        'Lihat Commit ($count)',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            if (!hasCommits && snapshot.connectionState != ConnectionState.waiting)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Text(
                  'Belum ada commit GitHub yang terhubung dengan tugas ini.',
                  style: TextStyle(
                    color: isDark ? Colors.white70 : Colors.black87,
                    fontSize: 13,
                  ),
                ),
              ),
            if (hasCommits)
              const SizedBox(height: 16)
            else
              const SizedBox(height: 24),
          ],
        );
      },
    );
  }
}
