import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../../../../core/network/supabase_provider.dart';
import '../../data/models/project_model.dart';
import '../../data/repositories/project_repository.dart';

final projectRepositoryProvider = Provider<ProjectRepository>((ref) {
  final supabase = ref.watch(supabaseClientProvider);
  return ProjectRepository(supabase);
});

class ProjectListNotifier extends StateNotifier<AsyncValue<List<ProjectModel>>> {
  final ProjectRepository _repository;

  ProjectListNotifier(this._repository) : super(const AsyncValue.loading()) {
    fetchProjects();
  }

  Future<void> fetchProjects() async {
    state = const AsyncValue.loading();
    try {
      final projects = await _repository.getProjects();
      state = AsyncValue.data(projects);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> addProject(ProjectModel project) async {
    try {
      final newProj = await _repository.createProject(project);
      state.whenData((projects) {
        state = AsyncValue.data([...projects, newProj]);
      });
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> updateProject(ProjectModel project) async {
    try {
      final updatedProj = await _repository.updateProject(project);
      state.whenData((projects) {
        state = AsyncValue.data(
          projects.map((p) => p.id == project.id ? updatedProj : p).toList()
        );
      });
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> deleteProject(String id) async {
    try {
      await _repository.deleteProject(id);
      state.whenData((projects) {
        state = AsyncValue.data(projects.where((p) => p.id != id).toList());
      });
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}

final projectListProvider = StateNotifierProvider<ProjectListNotifier, AsyncValue<List<ProjectModel>>>((ref) {
  final repo = ref.watch(projectRepositoryProvider);
  return ProjectListNotifier(repo);
});

// A provider for search query
final projectSearchQueryProvider = StateProvider<String>((ref) => '');