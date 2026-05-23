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

  Future<void> updateProjectStatus(String id, bool statusAktif) async {
    try {
      await _repository.updateProjectStatus(id, statusAktif);
      state.whenData((projects) {
        state = AsyncValue.data(
          projects.map((p) => p.id == id ? p.copyWith(statusAktif: statusAktif) : p).toList()
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

// Provider to fetch members of a project
final projectMembersProvider = FutureProvider.family<List<Map<String, dynamic>>, String>((ref, projectId) async {
  if (projectId.startsWith('local-')) {
    return [
      {
        'member_id': 'mock-1',
        'user_id': 'mock-user-1',
        'nama': 'Ahmad Fauzi',
        'email': 'ahmad@example.com',
        'avatar_url': '',
        'role': 'Tim',
      },
      {
        'member_id': 'mock-2',
        'user_id': 'mock-user-2',
        'nama': 'Siti Aminah',
        'email': 'siti@example.com',
        'avatar_url': '',
        'role': 'Tim',
      }
    ];
  }
  final supabase = ref.watch(supabaseClientProvider);
  try {
    final response = await supabase
        .from('project_members')
        .select('id, user_id, profiles(id, nama, email, avatar_url, role)')
        .eq('project_id', projectId)
        .eq('status_akses', 'aktif');
    
    final list = response as List<dynamic>;
    return list.map((item) {
      final profile = item['profiles'] as Map<String, dynamic>? ?? {};
      return {
        'member_id': item['id'] as String,
        'user_id': item['user_id'] as String,
        'nama': profile['nama'] ?? 'Anggota',
        'email': profile['email'] ?? '',
        'avatar_url': profile['avatar_url'] ?? '',
        'role': profile['role'] ?? 'Tim',
      };
    }).toList();
  } catch (e) {
    // Return empty list or local mock
    return [
      {
        'member_id': 'mock-1',
        'user_id': 'mock-user-1',
        'nama': 'Ahmad Fauzi',
        'email': 'ahmad@example.com',
        'avatar_url': '',
        'role': 'Tim',
      },
      {
        'member_id': 'mock-2',
        'user_id': 'mock-user-2',
        'nama': 'Siti Aminah',
        'email': 'siti@example.com',
        'avatar_url': '',
        'role': 'Tim',
      }
    ];
  }
});

// Provider to fetch all registered user profiles
final allProfilesProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final supabase = ref.watch(supabaseClientProvider);
  try {
    final response = await supabase.from('profiles').select();
    final list = response as List<dynamic>;
    return list.map((e) => Map<String, dynamic>.from(e)).toList();
  } catch (e) {
    return [];
  }
});