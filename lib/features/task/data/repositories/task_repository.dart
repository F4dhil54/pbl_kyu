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
          .select('task_id, user_id')
          .inFilter('task_id', taskIds);
      
      final assigneesData = assigneesResponse as List<dynamic>;
      final Map<String, List<String>> taskAssigneesMap = {};
      for (final item in assigneesData) {
        final taskId = item['task_id'] as String;
        final userId = item['user_id'] as String;
        taskAssigneesMap.putIfAbsent(taskId, () => []).add(userId);
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
        );
      }).toList();

    } catch (e) {
      debugPrint("=== WARNING: Task Supabase query failed. Error: $e ===");
      return _localTasks.where((t) => t.projectId == projectId).toList();
    }
  }

  Future<TaskModel> createTask(TaskModel task, List<String> assignees) async {
    if (task.projectId.startsWith('local-')) {
      final localId = 'local-task-${DateTime.now().millisecondsSinceEpoch}';
      final newTask = task.copyWith(
        id: localId,
        createdBy: 'local-manager',
        assignees: assignees,
      );
      _localTasks.add(newTask);
      return newTask;
    }
    try {
      final user = _supabaseClient.auth.currentUser;
      final taskWithCreator = task.copyWith(
        createdBy: user?.id ?? 'local-manager',
      );

      final response = await _supabaseClient
          .from('tasks')
          .insert(taskWithCreator.toJson())
          .select()
          .single();

      final createdTask = TaskModel.fromJson(response);

      // INSERT KE TASK_ASSIGNEES (DENGAN CO-CREATOR/ASSIGNED_BY)
      if (assignees.isNotEmpty) {
        final List<Map<String, dynamic>> assignments = assignees.map((userId) {
          return {
            'task_id': createdTask.id,
            'user_id': userId,
            'assigned_by': user?.id, // Mencatat manajer yang menugaskan
          };
        }).toList();
        await _supabaseClient.from('task_assignees').insert(assignments);
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
        await _supabaseClient.from('task_attachments').insert(attachments);
      }

      return createdTask.copyWith(assignees: assignees, attachments: task.attachments);
    } catch (e) {
      debugPrint("=== WARNING: Task Supabase insert failed. Error: $e ===");
      final localId = 'local-task-${DateTime.now().millisecondsSinceEpoch}';
      final newTask = task.copyWith(
        id: localId,
        createdBy: 'local-manager',
        assignees: assignees,
      );
      _localTasks.add(newTask);
      return newTask;
    }
  }

  Future<TaskModel> updateTask(TaskModel task, List<String> assignees) async {
    if (task.id.startsWith('local-') || task.projectId.startsWith('local-')) {
      final index = _localTasks.indexWhere((t) => t.id == task.id);
      if (index != -1) {
        final updatedTask = task.copyWith(assignees: assignees);
        _localTasks[index] = updatedTask;
        return updatedTask;
      }
      return task;
    }
    try {
      final user = _supabaseClient.auth.currentUser;
      final response = await _supabaseClient
          .from('tasks')
          .update(task.toJson())
          .eq('id', task.id)
          .select()
          .single();
      
      // SYNC KE TASK_ASSIGNEES (DELETE LALU RE-INSERT)
      await _supabaseClient.from('task_assignees').delete().eq('task_id', task.id);
      if (assignees.isNotEmpty) {
        final List<Map<String, dynamic>> assignments = assignees.map((userId) {
          return {
            'task_id': task.id,
            'user_id': userId,
            'assigned_by': user?.id,
          };
        }).toList();
        await _supabaseClient.from('task_assignees').insert(assignments);
      }

      return TaskModel.fromJson(response, assignees: assignees, attachments: task.attachments);
    } catch (e) {
      debugPrint("=== WARNING: Task Supabase update failed. Error: $e ===");
      final index = _localTasks.indexWhere((t) => t.id == task.id);
      if (index != -1) {
        final updatedTask = task.copyWith(assignees: assignees);
        _localTasks[index] = updatedTask;
        return updatedTask;
      }
      return task;
    }
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
      String dbStatus = status;
      if (status == 'Akan Dikerjakan') dbStatus = 'accept';
      if (status == 'Selesai') dbStatus = 'done';
      if (status == 'Draft') dbStatus = 'draft';
      if (status == 'Sedang Direview') dbStatus = 'review';

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
      String dbStatus = statusTugas;
      if (statusTugas == 'Akan Dikerjakan') dbStatus = 'accept';
      if (statusTugas == 'Selesai') dbStatus = 'done';

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
      String dbStatus = 'draft';
      if (status == 'Akan Dikerjakan' || status == 'accept') {
        dbStatus = 'accept';
      } else if (status == 'Sedang Dikerjakan' || status == 'review') {
        // 'review' di skema kamu setara dengan pengerjaan/peninjauan tim
        dbStatus = 'review'; 
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
        'catatan': catatan ?? 'Mengubah status tugas menjadi $status',
        'persen_selesai': persenSelesai ?? (dbStatus == 'done' ? 100 : (dbStatus == 'review' ? 50 : 0)),
        'jenis_aksi': 'memperbarui',
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
}