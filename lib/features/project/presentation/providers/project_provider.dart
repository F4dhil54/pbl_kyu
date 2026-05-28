import 'package:flutter/foundation.dart';
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
  if (projectId.startsWith('local-')) return [];
  final supabase = ref.watch(supabaseClientProvider);
  try {
    final response = await supabase
        .from('project_members')
        .select('id, user_id, profiles:profiles!project_members_user_id_fkey(id, nama, email, avatar_url, role)')
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
    debugPrint("Error fetching project members for project $projectId: $e");
    rethrow;
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

// Provider to fetch active colleagues of the manager
final managerActiveColleaguesProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final supabase = ref.watch(supabaseClientProvider);
  final user = supabase.auth.currentUser;
  if (user == null) return [];
  
  try {
    final response = await supabase
        .from('invitations')
        .select('user_id, profiles!invitations_user_id_fkey(id, nama, email, avatar_url, role)')
        .eq('invited_by', user.id)
        .eq('status', 'aktif');
    
    final list = response as List<dynamic>;
    return list.map((item) {
      final profile = item['profiles'] as Map<String, dynamic>? ?? {};
      return {
        'id': item['user_id'] as String,
        'nama': profile['nama'] ?? 'Anggota',
        'email': profile['email'] ?? '',
        'avatar_url': profile['avatar_url'] ?? '',
        'role': profile['role'] ?? 'Tim',
      };
    }).toList();
  } catch (e) {
    return [];
  }
});

// Provider to fetch teams created by the manager
final managerTeamsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final supabase = ref.watch(supabaseClientProvider);
  final user = supabase.auth.currentUser;
  if (user == null) return [];
  
  try {
    final response = await supabase
        .from('teams')
        .select('id, nama_tim, deskripsi')
        .eq('manajer_id', user.id);
    
    final list = response as List<dynamic>;
    return list.map((item) => Map<String, dynamic>.from(item)).toList();
  } catch (e) {
    return [];
  }
});

// Provider to fetch teams associated with a specific project
final projectTeamsProvider = FutureProvider.family<List<Map<String, dynamic>>, String>((ref, projectId) async {
  if (projectId.startsWith('local-')) return [];
  final supabase = ref.watch(supabaseClientProvider);
  
  try {
    final response = await supabase
        .from('project_teams')
        .select('id, team_id, teams(id, nama_tim)')
        .eq('project_id', projectId);
        
    final list = response as List<dynamic>;
    return list.map((item) {
      final team = item['teams'] as Map<String, dynamic>? ?? {};
      return {
        'id': item['id'] as String,
        'team_id': item['team_id'] as String,
        'nama_tim': team['nama_tim'] ?? 'Tim',
      };
    }).toList();
  } catch (e) {
    return [];
  }
});

// Fetch which team each user in the project belongs to, restricted to teams that are actually in the project.
final projectMembersTeamsProvider = FutureProvider.family<Map<String, List<String>>, String>((ref, projectId) async {
  if (projectId.startsWith('local-')) return {};
  final supabase = ref.watch(supabaseClientProvider);
  try {
    // 1. Get teams in this project
    final projectTeamsRes = await supabase.from('project_teams').select('team_id, teams(nama_tim)').eq('project_id', projectId);
    final pTeamsList = projectTeamsRes as List<dynamic>;
    if (pTeamsList.isEmpty) return {};

    final Map<String, String> teamIdToName = {};
    for (var pt in pTeamsList) {
      final teamData = pt['teams'] as Map<String, dynamic>?;
      if (teamData != null) {
        teamIdToName[pt['team_id'] as String] = teamData['nama_tim'] as String;
      }
    }

    if (teamIdToName.isEmpty) return {};

    // 2. Get members of these teams
    final teamIds = teamIdToName.keys.toList();
    final teamMembersRes = await supabase.from('team_members').select('user_id, team_id').inFilter('team_id', teamIds);
    final tmList = teamMembersRes as List<dynamic>;

    // 3. Map user_id to List<String> (team names)
    final Map<String, List<String>> userToTeams = {};
    for (var tm in tmList) {
      final userId = tm['user_id'] as String;
      final teamId = tm['team_id'] as String;
      final teamName = teamIdToName[teamId] ?? 'Tim';
      
      if (!userToTeams.containsKey(userId)) {
        userToTeams[userId] = [];
      }
      if (!userToTeams[userId]!.contains(teamName)) {
        userToTeams[userId]!.add(teamName);
      }
    }
    
    return userToTeams;
  } catch (e) {
    debugPrint("Error fetching project member teams: $e");
    return {};
  }
});

// Provider to calculate real project progress based on task logs
final projectRealProgressProvider = FutureProvider.family<double, String>((ref, projectId) async {
  if (projectId.startsWith('local-')) {
    return 0.0;
  }
  
  final supabase = ref.watch(supabaseClientProvider);
  try {
    // Ambil semua tugas beserta logs progress-nya dalam 1 single query
    final response = await supabase
        .from('tasks')
        .select('id, task_progress_logs(persen_selesai, created_at)')
        .eq('project_id', projectId);
        
    final tasks = response as List<dynamic>;
    if (tasks.isEmpty) return 0.0;

    int totalProgress = 0;
    for (var task in tasks) {
      final logsList = task['task_progress_logs'] as List<dynamic>? ?? [];
      if (logsList.isEmpty) {
        continue;
      }
      
      // Cari log dengan created_at paling terbaru
      var latestLog = logsList.first;
      for (var log in logsList) {
        final currentLatestTime = DateTime.tryParse(latestLog['created_at'] as String? ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0);
        final logTime = DateTime.tryParse(log['created_at'] as String? ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0);
        if (logTime.isAfter(currentLatestTime)) {
          latestLog = log;
        }
      }
      
      final progressVal = latestLog['persen_selesai'] as num?;
      if (progressVal != null) {
        totalProgress += progressVal.toInt();
      }
    }
    
    return totalProgress / (tasks.length * 100);
  } catch (e) {
    debugPrint("Error calculating project real progress: $e");
    return 0.0;
  }
});
