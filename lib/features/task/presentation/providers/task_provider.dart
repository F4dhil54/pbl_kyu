import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
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

  TaskListNotifier(this._repository, this._projectId) : super(const AsyncValue.loading()) {
    fetchTasks();
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
      rethrow; // Agar UI dapat menangkap error & mereset _isSaving
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
      rethrow; // Agar UI dapat menangkap error & mereset _isSaving
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
      // Log error internally, do not set state error since it doesn't affect list UI directly
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

// StateNotifierProvider family to track task lists of multiple projects
final projectTaskListProvider = StateNotifierProvider.family<TaskListNotifier, AsyncValue<List<TaskModel>>, String>((ref, projectId) {
  final repo = ref.watch(taskRepositoryProvider);
  return TaskListNotifier(repo, projectId);
});

// A provider for task tab filters
final taskFilterProvider = StateProvider<String>((ref) => 'Tugas Aktif');
