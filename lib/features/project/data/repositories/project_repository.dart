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
      date: '24 Okt',
    ),
    ProjectModel(
      id: 'local-2',
      name: 'Migrasi Cloud Fase 2',
      description: 'Mohon fokus pada optimasi migration pipeline dan database replication di cloud server baru.',
      labels: ['IT Infrastruktur'],
      githubRepo: 'https://github.com/cloud-migration-fase2',
      progress: 0.32,
      category: 'IT INFRA',
      date: '12 Nov',
    ),
    ProjectModel(
      id: 'local-3',
      name: 'Persiapan Audit Tahunan',
      description: 'Persiapan data keuangan, laporan operasional, dan dokumentasi kepatuhan untuk audit tahunan eksternal.',
      labels: ['Finance'],
      githubRepo: 'https://github.com/finance-audit-preparation',
      progress: 0.90,
      category: 'FINANCE',
      date: 'Minggu Depan',
    ),
    ProjectModel(
      id: 'local-4',
      name: 'Optimasi Rantai Pasok',
      description: 'Implementasi machine learning untuk forecasting permintaan gudang dan optimasi rute armada logistik.',
      labels: ['Operations'],
      githubRepo: 'https://github.com/supply-chain-optimization',
      progress: 0.55,
      category: 'OPERATIONS',
      date: '01 Des',
    ),
  ];

  ProjectRepository(this._supabaseClient);

  /// Fetch all projects
  Future<List<ProjectModel>> getProjects() async {
    try {
      debugPrint("=== INFO: [Supabase] Fetching projects ===");
      final response = await _supabaseClient
          .from('projects')
          .select()
          .order('name', ascending: true);
      
      final data = response as List<dynamic>;
      return data.map((json) => ProjectModel.fromJson(json)).toList();
    } catch (e) {
      debugPrint("=== WARNING: Supabase query failed, using local fallback. Error: $e ===");
      // Return local fallback list
      return List.of(_localProjects);
    }
  }

  /// Create a new project
  Future<ProjectModel> createProject(ProjectModel project) async {
    try {
      debugPrint("=== INFO: [Supabase] Creating project: ${project.name} ===");
      final response = await _supabaseClient
          .from('projects')
          .insert(project.toJson())
          .select()
          .single();
      
      return ProjectModel.fromJson(response);
    } catch (e) {
      debugPrint("=== WARNING: Supabase insert failed, inserting locally. Error: $e ===");
      final newProject = project.copyWith(
        id: 'local-${DateTime.now().millisecondsSinceEpoch}',
      );
      _localProjects.add(newProject);
      return newProject;
    }
  }

  /// Update an existing project
  Future<ProjectModel> updateProject(ProjectModel project) async {
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

  /// Delete a project by ID
  Future<void> deleteProject(String id) async {
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