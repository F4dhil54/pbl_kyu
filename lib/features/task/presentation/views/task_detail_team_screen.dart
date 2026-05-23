import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/theme_mode.dart';
import 'package:pbl_kyu/shared/widgets/profile_avatar.dart';
import '../../data/models/task_model.dart';
import '../../data/models/attachment_model.dart';
import '../../../project/data/models/project_model.dart';
import '../providers/task_provider.dart';
import '../../../project/presentation/providers/project_provider.dart';

class TaskDetailTeamScreen extends ConsumerStatefulWidget {
  final TaskModel? task;
  const TaskDetailTeamScreen({super.key, this.task});

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
  bool _isUpdatingStatus = false;

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
    _selectedStatus = _activeTask.statusTugas;
  }

  void _startTimer() {
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
    setState(() { _isUpdatingStatus = true; });

    try {
      AttachmentModel? attachment;
      if (_attachmentPathController.text.trim().isNotEmpty) {
        attachment = AttachmentModel(
          id: '',
          taskId: _activeTask.id,
          tipeLampiran: _attachmentType,
          filePathOrUrl: _attachmentPathController.text.trim(),
          namaFile: _attachmentNameController.text.trim().isNotEmpty 
              ? _attachmentNameController.text.trim() 
              : (_attachmentType == 'link' ? 'Link URL' : 'File Lampiran'),
        );
      }

      await ref.read(projectTaskListProvider(_activeTask.projectId).notifier).logProgress(
        taskId: _activeTask.id,
        status: _selectedStatus,
        catatan: 'Mengubah status tugas menjadi $_selectedStatus',
        persenSelesai: _selectedStatus == 'Selesai' ? 100 : (_selectedStatus == 'Sedang Dikerjakan' ? 50 : 0),
        attachment: attachment,
      );

      _attachmentNameController.clear();
      _attachmentPathController.clear();

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
                title: const Text('Ambil Foto'),
                onTap: () async {
                  Navigator.pop(context);
                  final picker = ImagePicker();
                  final pickedFile = await picker.pickImage(source: ImageSource.camera);
                  if (pickedFile != null) {
                    setState(() {
                      _attachmentType = 'foto';
                      _attachmentPathController.text = pickedFile.path;
                      _attachmentNameController.text = pickedFile.name;
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
                      _attachmentType = 'file';
                      _attachmentPathController.text = pickedFile.path;
                      _attachmentNameController.text = pickedFile.name;
                    });
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.link, color: AppColors.primary),
                title: const Text('Sisipkan Link'),
                onTap: () {
                  Navigator.pop(context);
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
          _activeTask.judulTugas,
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
                  ? Colors.red.withOpacity(0.1) 
                  : (_activeTask.prioritas == 'Schedule' ? Colors.orange.withOpacity(0.1) : Colors.blue.withOpacity(0.1)),
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
            if (assignedMembers.isEmpty) {
              return Text('Tidak ada anggota ditugaskan.', style: TextStyle(color: isDark ? Colors.white70 : Colors.black87, fontSize: 13));
            }
            return Wrap(
              spacing: 8,
              runSpacing: 8,
              children: assignedMembers.map((m) {
                return Chip(
                  avatar: CircleAvatar(
                    backgroundColor: AppColors.primary.withOpacity(0.2),
                    child: Text(m['nama'][0].toUpperCase(), style: const TextStyle(color: AppColors.primary, fontSize: 10)),
                  ),
                  label: Text(m['nama']),
                  backgroundColor: isDark ? AppDarkColors.surface : Colors.grey[200],
                  labelStyle: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 12),
                );
              }).toList(),
            );
          },
        ),

        // Initial attachments
        _buildSectionLabel('Lampiran Tugas Awal', isDark),
        if (_activeTask.attachments.isEmpty)
          Text('Tidak ada lampiran tugas awal.', style: TextStyle(color: isDark ? Colors.white70 : Colors.black87, fontSize: 13))
        else
          Column(
            children: _activeTask.attachments.map((att) {
              return Card(
                color: isDark ? AppDarkColors.surface : Colors.white,
                child: ListTile(
                  leading: Icon(
                    att.tipeLampiran == 'foto'
                        ? Icons.camera_alt_outlined
                        : (att.tipeLampiran == 'file' ? Icons.file_present_outlined : Icons.link),
                    color: AppColors.primary,
                  ),
                  title: Text(att.namaFile, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13)),
                  subtitle: Text(att.tipeLampiran.toUpperCase(), style: const TextStyle(fontSize: 10)),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                  onTap: () => _bukaTautan(att.filePathOrUrl),
                ),
              );
            }).toList(),
          ),

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

        // Riwayat Progress Tim
        _buildSectionLabel('Riwayat Progress Tim', isDark),
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

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          backgroundColor: AppColors.primary.withOpacity(0.1),
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
                              child: ListTile(
                                leading: Icon(
                                  att['tipe_lampiran'] == 'foto'
                                      ? Icons.camera_alt_outlined
                                      : (att['tipe_lampiran'] == 'file' ? Icons.file_present_outlined : Icons.link),
                                  color: AppColors.primary,
                                  size: 18,
                                ),
                                title: Text(att['nama_file'] ?? '', style: const TextStyle(fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
                                trailing: const Icon(Icons.arrow_forward_ios, size: 12),
                                onTap: () => _bukaTautan(att['file_path_or_url'] ?? ''),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ],
                );
              },
            );
          },
        ),
      ],
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
                _activeTask.judulTugas,
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
                color: priorityColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: priorityColor.withOpacity(0.3)),
              ),
              child: Text(
                isDone ? 'DONE' : _activeTask.prioritas.toUpperCase(),
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: priorityColor),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

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
                  color: Colors.white.withOpacity(0.06),
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

        // Task attachments
        _buildSectionLabel('Lampiran Tugas Awal', isDark),
        if (_activeTask.attachments.isEmpty)
          Text('Tidak ada lampiran tugas awal.', style: TextStyle(color: isDark ? Colors.white70 : Colors.black87, fontSize: 13))
        else
          Column(
            children: _activeTask.attachments.map((att) {
              return Card(
                color: isDark ? AppDarkColors.surface : Colors.white,
                child: ListTile(
                  leading: Icon(
                    att.tipeLampiran == 'foto'
                        ? Icons.camera_alt_outlined
                        : (att.tipeLampiran == 'file' ? Icons.file_present_outlined : Icons.link),
                    color: AppColors.primary,
                  ),
                  title: Text(att.namaFile, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13)),
                  subtitle: Text(att.tipeLampiran.toUpperCase(), style: const TextStyle(fontSize: 10)),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                  onTap: () => _bukaTautan(att.filePathOrUrl),
                ),
              );
            }).toList(),
          ),

        const SizedBox(height: 16),
        const Divider(),

        // Form Update Status Progress
        _buildSectionLabel('Pembaruan Status & Progress', isDark),
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
      _activeTask = tasksList.firstWhere((t) => t.id == widget.task!.id, orElse: () => _activeTask);
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
}