import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/task_model.dart';
import '../models/attachment_model.dart';

class TaskRepository {
  final SupabaseClient _supabaseClient;

  // Local fallback database
  final List<TaskModel> _localTasks = [];

  TaskRepository(this._supabaseClient);

  Future<List<TaskModel>> getTasks(String projectId) async {
    if (projectId.startsWith('local-')) {
      return _localTasks.where((t) => t.projectId == projectId).toList();
    }
    try {
      final response = await _supabaseClient
          .from('tasks')
          .select()
          .eq('project_id', projectId);
      
      final tasksData = response as List<dynamic>;
      if (tasksData.isEmpty) {
        return [];
      }

      final taskIds = tasksData.map((t) => t['id'] as String).toList();

      // FETCH DARI TASK_ASSIGNEES (MENGGANTIKAN TASK_ASSIGNMENTS)
      final assigneesResponse = await _supabaseClient
          .from('task_assignees')
          .select('task_id, user_id, project_member_id, project_team_id')
          .inFilter('task_id', taskIds);
      
      final assigneesData = assigneesResponse as List<dynamic>;
      final Map<String, List<String>> taskAssigneesMap = {};
      final Map<String, String?> taskProjectTeamIdMap = {};
      final Map<String, String?> taskProjectMemberIdMap = {};

      for (final item in assigneesData) {
        final taskId = item['task_id'] as String;
        final userId = item['user_id'] as String?;
        if (userId != null) {
          taskAssigneesMap.putIfAbsent(taskId, () => []).add(userId);
        }
        if (item['project_team_id'] != null) {
          taskProjectTeamIdMap[taskId] = item['project_team_id'] as String;
        }
        if (item['project_member_id'] != null) {
          taskProjectMemberIdMap[taskId] = item['project_member_id'] as String;
        }
      }

      // Fetch attachments
      final attachmentsResponse = await _supabaseClient
          .from('task_attachments')
          .select()
          .inFilter('task_id', taskIds);
      
      final attachmentsData = attachmentsResponse as List<dynamic>;
      final Map<String, List<AttachmentModel>> taskAttachmentsMap = {};
      for (final item in attachmentsData) {
        final attachment = AttachmentModel.fromJson(item);
        taskAttachmentsMap.putIfAbsent(attachment.taskId, () => []).add(attachment);
      }

      // ── AUTO-AKTIVASI TUGAS TERJADWAL ─────────────────────────────────
      // Cari tugas berstatus 'scheduled' yang scheduled_for-nya sudah lewat.
      // Jika ada, langsung update ke 'accept' di Supabase agar tim bisa melihat.
      final now = DateTime.now().toUtc();
      final scheduledExpiredIds = <String>{};

      for (final json in tasksData) {
        if ((json['status_tugas'] as String?) != 'scheduled') continue;
        final sfRaw = json['scheduled_for'] as String?;
        if (sfRaw == null) continue;
        final sf = DateTime.tryParse(sfRaw);
        // Bandingkan UTC dengan UTC — scheduled_for dari Supabase sudah UTC
        if (sf != null && sf.isBefore(now)) {
          scheduledExpiredIds.add(json['id'] as String);
        }
      }

      if (scheduledExpiredIds.isNotEmpty) {
        try {
          await _supabaseClient
              .from('tasks')
              .update({'status_tugas': 'accept', 'keputusan_manajer': 'Setujui'})
              .inFilter('id', scheduledExpiredIds.toList());
          debugPrint('=== INFO: Auto-activated ${scheduledExpiredIds.length} scheduled task(s): $scheduledExpiredIds ===');
        } catch (activateErr) {
          debugPrint('=== WARNING: Auto-activate scheduled tasks failed: $activateErr ===');
        }
      }
      // ─────────────────────────────────────────────────────────────────────

      // Bangun TaskModel. Untuk tugas yang di-auto-aktifkan, buat Map baru
      // (spread operator) karena Supabase mengembalikan UnmodifiableMapView.
      return tasksData.map((json) {
        final taskId = json['id'] as String;
        final effectiveJson = scheduledExpiredIds.contains(taskId)
            ? <String, dynamic>{
                ...json as Map<String, dynamic>,
                'status_tugas': 'accept',
                'keputusan_manajer': 'Setujui',
              }
            : json;
        return TaskModel.fromJson(
          effectiveJson,
          assignees: taskAssigneesMap[taskId],
          attachments: taskAttachmentsMap[taskId],
          projectTeamId: taskProjectTeamIdMap[taskId],
          projectMemberId: taskProjectMemberIdMap[taskId],
        );
      }).toList();

    } catch (e) {
      debugPrint("=== WARNING: Task Supabase query failed. Error: $e ===");
      return _localTasks.where((t) => t.projectId == projectId).toList();
    }
  }

  Future<List<TaskModel>> getMyTasks() async {
    try {
      final user = _supabaseClient.auth.currentUser;
      if (user == null) return [];

      // Fetch task IDs assigned to the user
      final assigneesResponse = await _supabaseClient
          .from('task_assignees')
          .select('task_id')
          .eq('user_id', user.id);
      
      final assigneesData = assigneesResponse as List<dynamic>;
      if (assigneesData.isEmpty) return [];

      final taskIds = assigneesData.map((e) => e['task_id'] as String).toList();

      // Fetch the tasks
      final tasksResponse = await _supabaseClient
          .from('tasks')
          .select()
          .inFilter('id', taskIds);
      
      final tasksData = tasksResponse as List<dynamic>;
      if (tasksData.isEmpty) return [];

      // We should also fetch project names to display on the dashboard if needed, 
      // but ProjectListProvider can handle project info mapping.
      
      // Fetch assignees for these tasks
      final allAssigneesResponse = await _supabaseClient
          .from('task_assignees')
          .select('task_id, user_id, project_member_id, project_team_id')
          .inFilter('task_id', taskIds);
      
      final allAssigneesData = allAssigneesResponse as List<dynamic>;
      final Map<String, List<String>> taskAssigneesMap = {};
      final Map<String, String?> taskProjectTeamIdMap = {};
      final Map<String, String?> taskProjectMemberIdMap = {};

      for (final item in allAssigneesData) {
        final taskId = item['task_id'] as String;
        final userId = item['user_id'] as String?;
        if (userId != null) {
          taskAssigneesMap.putIfAbsent(taskId, () => []).add(userId);
        }
        if (item['project_team_id'] != null) {
          taskProjectTeamIdMap[taskId] = item['project_team_id'] as String;
        }
        if (item['project_member_id'] != null) {
          taskProjectMemberIdMap[taskId] = item['project_member_id'] as String;
        }
      }

      // Fetch attachments
      final attachmentsResponse = await _supabaseClient
          .from('task_attachments')
          .select()
          .inFilter('task_id', taskIds);
      
      final attachmentsData = attachmentsResponse as List<dynamic>;
      final Map<String, List<AttachmentModel>> taskAttachmentsMap = {};
      for (final item in attachmentsData) {
        final attachment = AttachmentModel.fromJson(item);
        taskAttachmentsMap.putIfAbsent(attachment.taskId, () => []).add(attachment);
      }

      return tasksData.map((json) {
        final taskId = json['id'] as String;
        return TaskModel.fromJson(
          json,
          assignees: taskAssigneesMap[taskId],
          attachments: taskAttachmentsMap[taskId],
          projectTeamId: taskProjectTeamIdMap[taskId],
          projectMemberId: taskProjectMemberIdMap[taskId],
        );
      }).toList();
    } catch (e) {
      debugPrint("=== WARNING: Fetching My Tasks failed. Error: $e ===");
      return [];
    }
  }

  Future<TaskModel> createTask(TaskModel task, List<Map<String, dynamic>> assignees) async {
    if (task.projectId.startsWith('local-')) {
      final localId = 'local-task-${DateTime.now().millisecondsSinceEpoch}';
      final newTask = task.copyWith(
        id: localId,
        createdBy: 'local-manager',
        assignees: assignees.map((a) => (a['user_id'] ?? '') as String).toList(),
      );
      _localTasks.add(newTask);
      return newTask;
    }

    final user = _supabaseClient.auth.currentUser;
    final taskWithCreator = task.copyWith(
      createdBy: user?.id ?? '',
    );

    // Timeout 10 detik: jika Supabase hang (misal trigger/constraint DB live),
    // langsung gagal dan tampilkan error ke user — tidak stuck loading selamanya.
    final response = await _supabaseClient
        .from('tasks')
        .insert(taskWithCreator.toJson())
        .select()
        .single()
        .timeout(
          const Duration(seconds: 10),
          onTimeout: () => throw Exception(
            'Koneksi ke server timeout. Pastikan koneksi internet stabil dan coba lagi.'
          ),
        );

    final createdTask = TaskModel.fromJson(response);

    // INSERT KE TASK_ASSIGNEES (DENGAN CO-CREATOR/ASSIGNED_BY)
    if (assignees.isNotEmpty) {
      final List<Map<String, dynamic>> assignments = assignees.map((a) {
        return {
          'task_id': createdTask.id,
          'user_id': a['user_id'],
          'project_member_id': a['project_member_id'],
          'project_team_id': a['project_team_id'],
          'assigned_by': user?.id,
        };
      }).toList();
      await _supabaseClient.from('task_assignees').insert(assignments)
          .timeout(const Duration(seconds: 10));
    }

    // Create initial attachments
    if (task.attachments.isNotEmpty) {
      final List<Map<String, dynamic>> attachments = task.attachments.map((att) {
        return {
          'task_id': createdTask.id,
          'tipe_lampiran': att.tipeLampiran,
          'file_path_or_url': att.filePathOrUrl,
          'nama_file': att.namaFile,
        };
      }).toList();
      await _supabaseClient.from('task_attachments').insert(attachments)
          .timeout(const Duration(seconds: 10));
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

    return createdTask.copyWith(
      assignees: assignees.map((a) => (a['user_id'] ?? '') as String).where((uid) => uid.isNotEmpty).toList(),
      attachments: task.attachments,
      projectTeamId: resolvedTeamId,
      projectMemberId: resolvedMemberId,
    );
  }

  Future<TaskModel> updateTask(TaskModel task, List<Map<String, dynamic>> assignees) async {
    if (task.id.startsWith('local-') || task.projectId.startsWith('local-')) {
      final index = _localTasks.indexWhere((t) => t.id == task.id);
      if (index != -1) {
        final updatedTask = task.copyWith(assignees: assignees.map((a) => (a['user_id'] ?? '') as String).toList());
        _localTasks[index] = updatedTask;
        return updatedTask;
      }
      return task;
    }

    final user = _supabaseClient.auth.currentUser;
    final response = await _supabaseClient
        .from('tasks')
        .update(task.toJson())
        .eq('id', task.id)
        .select()
        .single()
        .timeout(
          const Duration(seconds: 10),
          onTimeout: () => throw Exception(
            'Koneksi ke server timeout. Pastikan koneksi internet stabil dan coba lagi.'
          ),
        );

    // SYNC KE TASK_ASSIGNEES (DELETE LALU RE-INSERT)
    await _supabaseClient.from('task_assignees').delete().eq('task_id', task.id)
        .timeout(const Duration(seconds: 10));
    if (assignees.isNotEmpty) {
      final List<Map<String, dynamic>> assignments = assignees.map((a) {
        return {
          'task_id': task.id,
          'user_id': a['user_id'],
          'project_member_id': a['project_member_id'],
          'project_team_id': a['project_team_id'],
          'assigned_by': user?.id,
        };
      }).toList();
      await _supabaseClient.from('task_assignees').insert(assignments)
          .timeout(const Duration(seconds: 10));
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

    return TaskModel.fromJson(
      response,
      assignees: assignees.map((a) => (a['user_id'] ?? '') as String).where((uid) => uid.isNotEmpty).toList(),
      attachments: task.attachments,
      projectTeamId: resolvedTeamId,
      projectMemberId: resolvedMemberId,
    );
  }

  Future<void> deleteTask(String id) async {
    if (id.startsWith('local-')) {
      _localTasks.removeWhere((t) => t.id == id);
      return;
    }
    try {
      await _supabaseClient.from('tasks').delete().eq('id', id);
    } catch (e) {
      debugPrint("=== WARNING: Task Supabase delete failed. Error: $e ===");
      _localTasks.removeWhere((t) => t.id == id);
    }
  }

  Future<void> updateTaskStatus(String id, String status) async {
    if (id.startsWith('local-')) {
      final index = _localTasks.indexWhere((t) => t.id == id);
      if (index != -1) {
        _localTasks[index] = _localTasks[index].copyWith(statusTugas: status);
      }
      return;
    }
    try {
      // Pastikan status dikonversi ke lowercase jika fungsi pemanggil belum memetakan ke format DB
      String dbStatus = status.toLowerCase().trim();
      if (dbStatus == 'akan dikerjakan' || dbStatus == 'sedang dikerjakan' || dbStatus == 'accept') {
        dbStatus = 'accept';
      } else if (dbStatus == 'selesai' || dbStatus == 'done') {
        dbStatus = 'done';
      } else if (dbStatus == 'draft' || dbStatus == 'draf') {
        dbStatus = 'draft';
      } else if (dbStatus == 'ditinjau' || dbStatus == 'review' || dbStatus == 'sedang direview') {
        dbStatus = 'review';
      } else if (dbStatus == 'dijadwalkan' || dbStatus == 'scheduled') {
        dbStatus = 'scheduled';
      }

      await _supabaseClient.from('tasks').update({'status_tugas': dbStatus}).eq('id', id);
    } catch (e) {
      debugPrint("=== WARNING: Task Supabase status update failed. Error: $e ===");
      final index = _localTasks.indexWhere((t) => t.id == id);
      if (index != -1) {
        _localTasks[index] = _localTasks[index].copyWith(statusTugas: status);
      }
    }
  }

  Future<void> updateTaskManagerDecision(String id, String keputusan, String statusTugas) async {
    if (id.startsWith('local-')) {
      final index = _localTasks.indexWhere((t) => t.id == id);
      if (index != -1) {
        _localTasks[index] = _localTasks[index].copyWith(
          keputusanManajer: keputusan,
          statusTugas: statusTugas,
        );
      }
      return;
    }
    try {
      String dbStatus = statusTugas.toLowerCase().trim();
      if (dbStatus == 'akan dikerjakan' || dbStatus == 'sedang dikerjakan' || dbStatus == 'accept') {
        dbStatus = 'accept';
      } else if (dbStatus == 'selesai' || dbStatus == 'done') {
        dbStatus = 'done';
      } else if (dbStatus == 'draft' || dbStatus == 'draf') {
        dbStatus = 'draft';
      } else if (dbStatus == 'ditinjau' || dbStatus == 'review') {
        dbStatus = 'review';
      } else if (dbStatus == 'dijadwalkan' || dbStatus == 'scheduled') {
        dbStatus = 'scheduled';
      }

      await _supabaseClient.from('tasks').update({
        'keputusan_manajer': keputusan,
        'status_tugas': dbStatus,
      }).eq('id', id);
    } catch (e) {
      debugPrint("=== WARNING: Task Supabase manager decision update failed. Error: $e ===");
      final index = _localTasks.indexWhere((t) => t.id == id);
      if (index != -1) {
        _localTasks[index] = _localTasks[index].copyWith(
          keputusanManajer: keputusan,
          statusTugas: statusTugas,
        );
      }
    }
  }

  Future<void> addAttachment(String taskId, AttachmentModel attachment) async {
    if (taskId.startsWith('local-')) {
      final index = _localTasks.indexWhere((t) => t.id == taskId);
      if (index != -1) {
        final currentAttachments = List<AttachmentModel>.from(_localTasks[index].attachments);
        currentAttachments.add(attachment);
        _localTasks[index] = _localTasks[index].copyWith(attachments: currentAttachments);
      }
      return;
    }
    try {
      await _supabaseClient.from('task_attachments').insert({
        'task_id': taskId,
        'tipe_lampiran': attachment.tipeLampiran,
        'file_path_or_url': attachment.filePathOrUrl,
        'nama_file': attachment.namaFile,
      });
    } catch (e) {
      debugPrint("=== WARNING: Attachment Supabase insert failed. Error: $e ===");
      final index = _localTasks.indexWhere((t) => t.id == taskId);
      if (index != -1) {
        final currentAttachments = List<AttachmentModel>.from(_localTasks[index].attachments);
        currentAttachments.add(attachment);
        _localTasks[index] = _localTasks[index].copyWith(attachments: currentAttachments);
      }
    }
  }

  Future<void> logPomodoroSession({
    required String taskId,
    required String userId,
    required int durasiMenit,
    required String status,
    required DateTime startedAt,
    required DateTime endedAt,
  }) async {
    if (taskId.startsWith('local-') || userId.startsWith('local-')) {
      debugPrint("=== INFO: [Local] Skipping Pomodoro session log to Supabase for local task/user ===");
      return;
    }
    try {
      await _supabaseClient.from('pomodoro_sessions').insert({
        'task_id': taskId,
        'user_id': userId,
        'durasi_menit': durasiMenit,
        'status': status,
        'started_at': startedAt.toIso8601String(),
        'ended_at': endedAt.toIso8601String(),
      });
      debugPrint("=== INFO: [Supabase] Pomodoro session logged successfully ===");
    } catch (e) {
      debugPrint("=== WARNING: Pomodoro session log to Supabase failed. Error: $e ===");
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getTaskProgressLogs(String taskId) async {
    if (taskId.startsWith('local-')) {
      return [];
    }
    try {
      final response = await _supabaseClient
          .from('task_progress_logs')
          .select('''
            id,
            catatan,
            persen_selesai,
            created_at,
            jenis_aksi,
            hambatan,
            status_progress,
            profiles:logged_by ( nama, email, role ),
            task_attachments:task_attachments ( id, tipe_lampiran, file_path_or_url, nama_file )
          ''')
          .eq('task_id', taskId)
          .order('created_at', ascending: false);
      
      return List<Map<String, dynamic>>.from(response as List);
    } catch (e) {
      debugPrint("=== WARNING: Fetching task progress logs failed. Error: $e ===");
      return [];
    }
  }

  Future<void> logTaskProgress({
    required String taskId,
    required String status, // Input dari UI: 'Sedang Dikerjakan', 'Selesai', dll.
    String? catatan,
    int? persenSelesai,
    AttachmentModel? attachment,
    String? hambatan,
  }) async {
    if (taskId.startsWith('local-')) {
      await updateTaskStatus(taskId, status);
      return;
    }
    try {
      final user = _supabaseClient.auth.currentUser;
      if (user == null) {
        throw Exception("Pengguna tidak terautentikasi!");
      }

      // 1. MAPPING STATUS: Konversi Bahasa UI ke Kode Database PostgreSQL
      String dbStatus = 'accept';
      if (status == 'Akan Dikerjakan' || status == 'accept') {
        dbStatus = 'accept';
      } else if (status == 'Sedang Dikerjakan') {
        dbStatus = 'accept'; 
      } else if (status == 'Selesai' || status == 'done') {
        dbStatus = 'done';
      }

      // 2. KONDISI PENDUKUNG CONSTRAINT (chk_done_at)
      // Buat payload untuk update data tabel 'tasks'
      final Map<String, dynamic> taskUpdatePayload = {
        'status_tugas': dbStatus,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      };

      // Jika statusnya selesai, WAJIB isi done_at agar lolos constraint chk_done_at
      if (dbStatus == 'done') {
        taskUpdatePayload['done_at'] = DateTime.now().toUtc().toIso8601String();
      }

      // 3. Insert ke tabel 'task_progress_logs'
      final logResponse = await _supabaseClient.from('task_progress_logs').insert({
        'task_id': taskId,
        'logged_by': user.id,
        'catatan': catatan ?? 'Mengubah status status tugas menjadi $status',
        'persen_selesai': persenSelesai ?? (status == 'Selesai' ? 100 : (status == 'Sedang Dikerjakan' ? 50 : 0)),
        'jenis_aksi': 'memperbarui',
        'hambatan': hambatan,
        'status_progress': status,
      }).select('id').single();

      final logId = logResponse['id'] as String;

      // 4. Jika ada file lampiran progress dari tim, simpan ke database
      if (attachment != null) {
        await _supabaseClient.from('task_attachments').insert({
          'task_id': taskId,
          'log_id': logId,
          'tipe_lampiran': attachment.tipeLampiran,
          'file_path_or_url': attachment.filePathOrUrl,
          'nama_file': attachment.namaFile,
        });
      }

      // 5. Update tabel 'tasks' dengan payload yang sudah aman dan lolos check constraint
      await _supabaseClient
          .from('tasks')
          .update(taskUpdatePayload)
          .eq('id', taskId);

      debugPrint("=== INFO: [Supabase] Tim berhasil memperbarui progress tugas ===");
    } catch (e) {
      debugPrint("=== WARNING: Log task progress failed. Error: $e ===");
      rethrow;
    }
  }

  Future<String> uploadAttachmentFile(Uint8List bytes, String fileName) async {
    final extension = fileName.split('.').last;
    final finalFileName = '${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(1000000)}.$extension';

    try {
      await _supabaseClient.storage.createBucket('task_attachments', const BucketOptions(public: true));
    } catch (_) {
      // Bucket might already exist
    }

    await _supabaseClient.storage.from('task_attachments').uploadBinary(
      finalFileName,
      bytes,
      fileOptions: FileOptions(
        contentType: _determineContentType(extension),
        upsert: true,
      ),
    );

    return _supabaseClient.storage.from('task_attachments').getPublicUrl(finalFileName);
  }

  String _determineContentType(String extension) {
    switch (extension.toLowerCase()) {
      case 'png': return 'image/png';
      case 'jpg':
      case 'jpeg': return 'image/jpeg';
      case 'pdf': return 'application/pdf';
      case 'doc':
      case 'docx': return 'application/msword';
      case 'xls':
      case 'xlsx': return 'application/vnd.ms-excel';
      case 'txt': return 'text/plain';
      default: return 'application/octet-stream';
    }
  }
}
