import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/network/supabase_provider.dart';
import '../../data/models/task_model.dart';
import '../../data/models/attachment_model.dart';
import '../../data/repositories/task_repository.dart';

final taskRepositoryProvider = Provider<TaskRepository>((ref) {
  final supabase = ref.watch(supabaseClientProvider);
  return TaskRepository(supabase);
});

class TaskListNotifier extends StateNotifier<AsyncValue<List<TaskModel>>> {
  final TaskRepository _repository;
  final String _projectId;
  final SupabaseClient _supabase;
  RealtimeChannel? _taskChannel;
  Timer? _autoActivateTimer;
  final Set<String> _deadlineNotifiedTaskIds = {};

  TaskListNotifier(this._repository, this._projectId, this._supabase) : super(const AsyncValue.loading()) {
    fetchTasks();
    _initRealtime();
    _autoActivateTimer = Timer.periodic(const Duration(seconds: 15), (_) => _checkScheduledTasks());
  }

  void _initRealtime() {
    _taskChannel = _supabase.channel('public:tasks:project_$_projectId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'tasks',
          filter: PostgresChangeFilter(type: PostgresChangeFilterType.eq, column: 'project_id', value: _projectId),
          callback: (payload) {
            fetchTasks();
          },
        )
        .subscribe();
  }

  @override
  void dispose() {
    _autoActivateTimer?.cancel();
    _taskChannel?.unsubscribe();
    super.dispose();
  }

  void _checkScheduledTasks() {
    if (!state.hasValue || state.value == null) return;
    final now = DateTime.now();
    final tomorrow = now.add(const Duration(hours: 24));
    
    bool needsRefresh = false;
    for (final t in state.value!) {
      if (t.statusTugas == 'Dijadwalkan' && t.scheduledFor != null && t.scheduledFor!.isBefore(now)) {
        needsRefresh = true;
        break;
      }
      
      if (t.statusTugas != 'Selesai' && t.statusTugas != 'Draft' && t.statusTugas != 'Ditinjau') {
        if (t.deadlineDate != null && t.deadlineDate!.isAfter(now) && t.deadlineDate!.isBefore(tomorrow)) {
          if (!_deadlineNotifiedTaskIds.contains(t.id)) {
            _deadlineNotifiedTaskIds.add(t.id);
            needsRefresh = true;
            break;
          }
        }
      }
    }
    
    if (needsRefresh) {
      fetchTasks();
    }
  }

  Future<void> fetchTasks() async {
    state = const AsyncValue.loading();
    try {
      final tasks = await _repository.getTasks(_projectId);
      state = AsyncValue.data(tasks);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> addTask(TaskModel task, List<Map<String, dynamic>> assignees) async {
    try {
      final newT = await _repository.createTask(task, assignees);
      if (state.hasValue) {
        state = AsyncValue.data([...state.value!, newT]);
      } else {
        await fetchTasks();
      }
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      rethrow; // Agar UI bisa catch error
    }
  }

  Future<void> editTask(TaskModel task, List<Map<String, dynamic>> assignees) async {
    try {
      final updatedT = await _repository.updateTask(task, assignees);
      if (state.hasValue) {
        state = AsyncValue.data(
          state.value!.map((t) => t.id == task.id ? updatedT : t).toList()
        );
      } else {
        await fetchTasks();
      }
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      rethrow; // Agar UI bisa catch error
    }
  }

  Future<void> removeTask(String id) async {
    try {
      await _repository.deleteTask(id);
      if (state.hasValue) {
        state = AsyncValue.data(state.value!.where((t) => t.id != id).toList());
      } else {
        await fetchTasks();
      }
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> updateStatus(String id, String status) async {
    try {
      await _repository.updateTaskStatus(id, status);
      if (state.hasValue) {
        state = AsyncValue.data(
          state.value!.map((t) => t.id == id ? t.copyWith(statusTugas: status) : t).toList()
        );
      } else {
        await fetchTasks();
      }
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> approveOrRejectTask(String id, String keputusan, String statusTugas) async {
    try {
      await _repository.updateTaskManagerDecision(id, keputusan, statusTugas);
      if (state.hasValue) {
        state = AsyncValue.data(
          state.value!.map((t) => t.id == id ? t.copyWith(keputusanManajer: keputusan, statusTugas: statusTugas) : t).toList()
        );
      } else {
        await fetchTasks();
      }
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> attachFile(String taskId, AttachmentModel attachment) async {
    try {
      await _repository.addAttachment(taskId, attachment);
      if (state.hasValue) {
        state = AsyncValue.data(
          state.value!.map((t) {
            if (t.id == taskId) {
              final newAttachments = [...t.attachments, attachment];
              return t.copyWith(attachments: newAttachments);
            }
            return t;
          }).toList()
        );
      } else {
        await fetchTasks();
      }
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> submitPomodoroSession({
    required String taskId,
    required String userId,
    required int durasiMenit,
    required String status,
    required DateTime startedAt,
    required DateTime endedAt,
  }) async {
    try {
      await _repository.logPomodoroSession(
        taskId: taskId,
        userId: userId,
        durasiMenit: durasiMenit,
        status: status,
        startedAt: startedAt,
        endedAt: endedAt,
      );
    } catch (e) {
      // Log error internal
      debugPrint("Failed logging pomodoro session: $e");
    }
  }

  Future<void> logProgress({
    required String taskId,
    required String status,
    String? catatan,
    int? persenSelesai,
    AttachmentModel? attachment,
    String? hambatan,
  }) async {
    try {
      await _repository.logTaskProgress(
        taskId: taskId,
        status: status,
        catatan: catatan,
        persenSelesai: persenSelesai,
        attachment: attachment,
        hambatan: hambatan,
      );
      await fetchTasks();
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }

  Future<String> uploadAttachmentFile(Uint8List bytes, String fileName) async {
    return await _repository.uploadAttachmentFile(bytes, fileName);
  }
}

// Provider tracker tugas proyek
final projectTaskListProvider = StateNotifierProvider.family<TaskListNotifier, AsyncValue<List<TaskModel>>, String>((ref, projectId) {
  final repo = ref.watch(taskRepositoryProvider);
  final supabase = ref.watch(supabaseClientProvider);
  return TaskListNotifier(repo, projectId, supabase);
});

// Provider filter tab tugas
final taskFilterProvider = StateProvider<String>((ref) => 'Tugas Aktif');

final _myTasksDeadlineNotified = <String>{};

final myTasksProvider = FutureProvider<List<TaskModel>>((ref) async {
  final repo = ref.watch(taskRepositoryProvider);
  final tasks = await repo.getMyTasks();
  
  final timer = Timer.periodic(const Duration(seconds: 15), (_) {
     final now = DateTime.now();
     final tomorrow = now.add(const Duration(hours: 24));
     bool needsRefresh = false;
     
     for (var t in tasks) {
        if (t.statusTugas == 'Dijadwalkan' && t.scheduledFor != null && t.scheduledFor!.isBefore(now)) {
           needsRefresh = true;
           break;
        }
        
        if (t.statusTugas != 'Selesai' && t.statusTugas != 'Draft' && t.statusTugas != 'Ditinjau') {
          if (t.deadlineDate != null && t.deadlineDate!.isAfter(now) && t.deadlineDate!.isBefore(tomorrow)) {
            if (!_myTasksDeadlineNotified.contains(t.id)) {
               _myTasksDeadlineNotified.add(t.id);
               needsRefresh = true;
               break;
            }
          }
        }
     }
     
     if (needsRefresh) {
         ref.invalidateSelf();
     }
  });
  
  ref.onDispose(() => timer.cancel());
  return tasks;
});
