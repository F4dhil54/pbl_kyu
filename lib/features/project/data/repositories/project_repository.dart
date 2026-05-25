import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/project_model.dart';

class ProjectRepository {
  final SupabaseClient _supabaseClient;

  // Local fallback database to make sure the app works even without Supabase setup
  final List<ProjectModel> _localProjects = [
    ProjectModel(
      id: 'local-1',
      name: 'Kampanye Brand Q4',
      description: 'Proyek Kampanye Brand Q4 adalah strategi promosi akhir tahun untuk meningkatkan awareness, engagement, dan penjualan brand melalui media digital.',
      labels: ['Research'],
      githubRepo: 'https://github.com/kampanye-brand-q4',
      progress: 0.75,
      category: 'MARKETING',
      date: '2026-10-24',
      creatorId: 'local-manager',
      statusAktif: true,
    ),
    ProjectModel(
      id: 'local-2',
      name: 'Migrasi Cloud Fase 2',
      description: 'Mohon fokus pada optimasi migration pipeline dan database replication di cloud server baru.',
      labels: ['IT Infrastruktur'],
      githubRepo: 'https://github.com/cloud-migration-fase2',
      progress: 0.32,
      category: 'IT INFRA',
      date: '2026-11-12',
      creatorId: 'local-manager',
      statusAktif: true,
    ),
    ProjectModel(
      id: 'local-3',
      name: 'Persiapan Audit Tahunan',
      description: 'Persiapan data keuangan, laporan operasional, dan dokumentasi kepatuhan untuk audit tahunan eksternal.',
      labels: ['Finance'],
      githubRepo: 'https://github.com/finance-audit-preparation',
      progress: 0.90,
      category: 'FINANCE',
      date: '2026-06-01',
      creatorId: 'local-manager',
      statusAktif: false,
    ),
    ProjectModel(
      id: 'local-4',
      name: 'Optimasi Rantai Pasok',
      description: 'Implementasi machine learning untuk forecasting permintaan gudang dan optimasi rute armada logistik.',
      labels: ['Operations'],
      githubRepo: 'https://github.com/supply-chain-optimization',
      progress: 0.55,
      category: 'OPERATIONS',
      date: '2026-12-01',
      creatorId: 'local-manager',
      statusAktif: true,
    ),
  ];

  ProjectRepository(this._supabaseClient);

  /// Fetch projects depending on role
  Future<List<ProjectModel>> getProjects() async {
    try {
      final user = _supabaseClient.auth.currentUser;
      if (user == null) {
        return List.of(_localProjects);
      }
      final userId = user.id;
      final role = user.userMetadata?['role'] ?? 'Tim';

      debugPrint("=== INFO: [Supabase] Fetching projects for user: $userId, role: $role ===");

      if (role == 'Manajer') {
        final response = await _supabaseClient
            .from('projects')
            .select()
            .eq('pembuat_id', userId)
            .order('nama_proyek', ascending: true);
        
        final data = response as List<dynamic>;
        if (data.isEmpty) {
          return List.of(_localProjects);
        }
        return data.map((json) => ProjectModel.fromJson(json)).toList();
      } else {
        // Team member sees only active projects they are joined in
        final memberResponse = await _supabaseClient
            .from('project_members')
            .select('project_id')
            .eq('user_id', userId)
            .eq('status_akses', 'aktif');
        
        final memberData = memberResponse as List<dynamic>;
        final projectIds = memberData.map((m) => m['project_id'] as String).toList();

        if (projectIds.isEmpty) {
          return _localProjects.where((p) => p.statusAktif).toList();
        }

        final response = await _supabaseClient
            .from('projects')
            .select()
            .inFilter('id', projectIds)
            .eq('status_aktif', true)
            .order('nama_proyek', ascending: true);

        final data = response as List<dynamic>;
        return data.map((json) => ProjectModel.fromJson(json)).toList();
      }
    } catch (e) {
      debugPrint("=== WARNING: Supabase query failed, using local fallback. Error: $e ===");
      final user = _supabaseClient.auth.currentUser;
      final role = user?.userMetadata?['role'] ?? 'Tim';
      if (role == 'Tim') {
        return _localProjects.where((p) => p.statusAktif).toList();
      }
      return List.of(_localProjects);
    }
  }

  /// Create a new project
  Future<ProjectModel> createProject(ProjectModel project) async {
    try {
      final user = _supabaseClient.auth.currentUser;
      final projectWithCreator = project.copyWith(
        creatorId: user?.id ?? 'local-manager',
        statusAktif: true,
      );
      debugPrint("=== INFO: [Supabase] Creating project: ${projectWithCreator.name} ===");
      final response = await _supabaseClient
          .from('projects')
          .insert(projectWithCreator.toJson())
          .select()
          .single();
      
      return ProjectModel.fromJson(response);
    } catch (e) {
      debugPrint("=== WARNING: Supabase insert failed, inserting locally. Error: $e ===");
      final newProject = project.copyWith(
        id: 'local-${DateTime.now().millisecondsSinceEpoch}',
        creatorId: 'local-manager',
        statusAktif: true,
      );
      _localProjects.add(newProject);
      return newProject;
    }
  }

  /// Update an existing project
  Future<ProjectModel> updateProject(ProjectModel project) async {
    if (project.id.startsWith('local-')) {
      final index = _localProjects.indexWhere((p) => p.id == project.id);
      if (index != -1) {
        _localProjects[index] = project;
      }
      return project;
    }
    try {
      debugPrint("=== INFO: [Supabase] Updating project: ${project.id} ===");
      final response = await _supabaseClient
          .from('projects')
          .update(project.toJson())
          .eq('id', project.id)
          .select()
          .single();
      
      return ProjectModel.fromJson(response);
    } catch (e) {
      debugPrint("=== WARNING: Supabase update failed, updating locally. Error: $e ===");
      final index = _localProjects.indexWhere((p) => p.id == project.id);
      if (index != -1) {
        _localProjects[index] = project;
      }
      return project;
    }
  }

  /// Update project active/inactive status
  Future<void> updateProjectStatus(String id, bool statusAktif) async {
    if (id.startsWith('local-')) {
      final index = _localProjects.indexWhere((p) => p.id == id);
      if (index != -1) {
        _localProjects[index] = _localProjects[index].copyWith(statusAktif: statusAktif);
      }
      return;
    }
    try {
      debugPrint("=== INFO: [Supabase] Updating project status: $id to $statusAktif ===");
      await _supabaseClient
          .from('projects')
          .update({'status_aktif': statusAktif})
          .eq('id', id);
    } catch (e) {
      debugPrint("=== WARNING: Supabase status update failed. Error: $e ===");
      final index = _localProjects.indexWhere((p) => p.id == id);
      if (index != -1) {
        _localProjects[index] = _localProjects[index].copyWith(statusAktif: statusAktif);
      }
    }
  }

  /// Delete a project by ID
  Future<void> deleteProject(String id) async {
    if (id.startsWith('local-')) {
      _localProjects.removeWhere((p) => p.id == id);
      return;
    }
    try {
      debugPrint("=== INFO: [Supabase] Deleting project: $id ===");
      await _supabaseClient
          .from('projects')
          .delete()
          .eq('id', id);
    } catch (e) {
      debugPrint("=== WARNING: Supabase delete failed, deleting locally. Error: $e ===");
      _localProjects.removeWhere((p) => p.id == id);
    }
  }
}
