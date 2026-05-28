import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
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
      
      String role = 'Tim';
      try {
        final profileResponse = await _supabaseClient
            .from('profiles')
            .select('role')
            .eq('id', userId)
            .single();
        final dbRole = profileResponse['role'] as String? ?? 'Tim';
        final metaRole = user.userMetadata?['role'] as String?;
        if (metaRole != null && (dbRole == metaRole || dbRole.split(',').map((e) => e.trim()).contains(metaRole))) {
          role = metaRole;
        } else {
          role = dbRole.split(',').first.trim();
        }
      } catch (profileError) {
        debugPrint("=== WARNING: Failed to fetch role from profiles table, falling back to metadata. Error: $profileError ===");
        role = user.userMetadata?['role'] ?? 'Tim';
      }

      debugPrint("=== INFO: [Supabase] Fetching projects for user: $userId, role: $role ===");

      if (role == 'Manajer') {
        final response = await _supabaseClient
            .from('projects')
            .select()
            .eq('pembuat_id', userId)
            .order('nama_proyek', ascending: true);
        
        final data = response as List<dynamic>;
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
          return [];
        }

        // Ambil status undangan dari manajer untuk menentukan status read-only
        final invitationsResponse = await _supabaseClient
            .from('invitations')
            .select('invited_by, status')
            .eq('user_id', userId);
        
        final invitationsData = invitationsResponse as List<dynamic>;
        final Map<String, String> managerInvitationStatus = {};
        for (var inv in invitationsData) {
          final managerId = inv['invited_by'] as String?;
          final status = inv['status'] as String?;
          if (managerId != null && status != null) {
            managerInvitationStatus[managerId] = status;
          }
        }

        final response = await _supabaseClient
            .from('projects')
            .select()
            .inFilter('id', projectIds)
            .eq('status_aktif', true)
            .order('nama_proyek', ascending: true);

        final data = response as List<dynamic>;
        return data.map((json) {
          final proj = ProjectModel.fromJson(json);
          final invitationStatus = managerInvitationStatus[proj.creatorId];
          final isReadOnly = invitationStatus == 'nonaktif';
          return proj.copyWith(isReadOnly: isReadOnly);
        }).toList();
      }
    } catch (e) {
      debugPrint("=== WARNING: Supabase query failed. Error: $e ===");
      return [];
    }
  }

  Future<String?> _getGithubToken(String userId) async {
    try {
      final res = await _supabaseClient
          .from('profiles')
          .select('github_token')
          .eq('id', userId)
          .maybeSingle();
      return res?['github_token'] as String?;
    } catch (e) {
      debugPrint("Error fetching github token: $e");
      return null;
    }
  }

  /// Create a new project
  Future<ProjectModel> createProject(ProjectModel project) async {
    try {
      final user = _supabaseClient.auth.currentUser;
      final creatorId = user?.id ?? 'local-manager';

      String? parsedRepoUrl;
      String? githubToken;
      if (project.githubRepo.isNotEmpty) {
        parsedRepoUrl = parseGithubUrl(project.githubRepo);
        githubToken = await _getGithubToken(creatorId);
      }

      final projectWithCreator = project.copyWith(
        creatorId: creatorId,
        statusAktif: true,
        githubRepoUrl: parsedRepoUrl,
        managerGithubToken: githubToken,
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
      final user = _supabaseClient.auth.currentUser;
      final creatorId = user?.id ?? project.creatorId;

      String? parsedRepoUrl;
      String? githubToken;
      if (project.githubRepo.isNotEmpty) {
        parsedRepoUrl = parseGithubUrl(project.githubRepo);
        githubToken = await _getGithubToken(creatorId);
      }

      final updatedProject = project.copyWith(
        githubRepoUrl: parsedRepoUrl,
        managerGithubToken: githubToken,
      );

      debugPrint("=== INFO: [Supabase] Updating project: ${project.id} ===");
      final response = await _supabaseClient
          .from('projects')
          .update(updatedProject.toJson())
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

  static String parseGithubUrl(String url) {
    var sanitized = url.trim();
    sanitized = sanitized.replaceAll(RegExp(r'^(https?:\/\/)?(www\.)?github\.com\/'), '');
    sanitized = sanitized.replaceAll(RegExp(r'^git@github\.com:'), '');
    sanitized = sanitized.replaceAll(RegExp(r'\.git$'), '');
    if (sanitized.endsWith('/')) {
      sanitized = sanitized.substring(0, sanitized.length - 1);
    }
    return sanitized;
  }

  Future<String?> _getTaskIdByNumber(String projectId, int taskNumber) async {
    try {
      final res = await _supabaseClient
          .from('tasks')
          .select('id')
          .eq('project_id', projectId)
          .eq('task_number', taskNumber)
          .maybeSingle();
      return res?['id'] as String?;
    } catch (e) {
      debugPrint("Error fetching task ID by number: $e");
      return null;
    }
  }

  Future<void> jalankanSyncGithub(String projectId) async {
    if (projectId.startsWith('local-')) {
      debugPrint("=== INFO: Local project sync is skipped ===");
      return;
    }

    // 1. Fetch project repository details
    final projectRes = await _supabaseClient
        .from('projects')
        .select('github_repo_url, manager_github_token, pembuat_id')
        .eq('id', projectId)
        .single();

    final repoUrl = projectRes['github_repo_url'] as String?;
    var token = projectRes['manager_github_token'] as String?;
    final creatorId = projectRes['pembuat_id'] as String;

    if (token == null || token.isEmpty) {
      token = await _getGithubToken(creatorId);
    }

    if (repoUrl == null || repoUrl.isEmpty) {
      throw Exception("Tautan repositori GitHub proyek belum diatur.");
    }
    if (token == null || token.isEmpty) {
      throw Exception("Token GitHub manajer tidak ditemukan. Silakan hubungkan akun GitHub terlebih dahulu.");
    }

    // 2. Fetch all members with their github usernames
    final membersRes = await _supabaseClient
        .from('project_members')
        .select('user_id, profiles:profiles!project_members_user_id_fkey(id, github_username)')
        .eq('project_id', projectId);

    final Map<String, String> usernameToUserId = {};

    for (var m in membersRes as List<dynamic>) {
      final profile = m['profiles'] as Map<String, dynamic>?;
      if (profile != null) {
        final uid = profile['id'] as String?;
        final ghUser = profile['github_username'] as String?;
        if (uid != null && ghUser != null && ghUser.isNotEmpty) {
          usernameToUserId[ghUser.toLowerCase()] = uid;
        }
      }
    }

    // Include the manager/creator
    final creatorProfile = await _supabaseClient
        .from('profiles')
        .select('id, github_username')
        .eq('id', creatorId)
        .maybeSingle();

    if (creatorProfile != null) {
      final uid = creatorProfile['id'] as String?;
      final ghUser = creatorProfile['github_username'] as String?;
      if (uid != null && ghUser != null && ghUser.isNotEmpty) {
        usernameToUserId[ghUser.toLowerCase()] = uid;
      }
    }

    // 3. Make HTTP request to GitHub API to pull the 100 latest commits
    final url = Uri.parse('https://api.github.com/repos/$repoUrl/commits?per_page=100');
    final response = await http.get(
      url,
      headers: {
        'Accept': 'application/vnd.github+json',
        'Authorization': 'Bearer $token',
        'X-GitHub-Api-Version': '2022-11-28',
      },
    );

    if (response.statusCode != 200) {
      throw Exception("Gagal mengambil data commit dari GitHub: ${response.reasonPhrase} (${response.body})");
    }

    final List<dynamic> commitsJson = jsonDecode(response.body);

    // 4. Parse and Upsert each commit
    final List<Map<String, dynamic>> commitsToUpsert = [];
    final regex = RegExp(r'#(\d+)');

    for (var commitData in commitsJson) {
      final sha = commitData['sha'] as String;
      final commitInfo = commitData['commit'] as Map<String, dynamic>;
      final message = commitInfo['message'] as String;
      final authorInfo = commitInfo['author'] as Map<String, dynamic>?;
      final dateStr = authorInfo?['date'] as String?;

      String? userId;
      final authorLogin = commitData['author']?['login'] as String?;
      if (authorLogin != null) {
        userId = usernameToUserId[authorLogin.toLowerCase()];
      }
      userId ??= creatorId;

      // Extract task ID from commit message
      final match = regex.firstMatch(message);
      String? taskId;
      if (match != null) {
        final taskNumberStr = match.group(1);
        if (taskNumberStr != null) {
          final taskNumber = int.tryParse(taskNumberStr);
          if (taskNumber != null) {
            taskId = await _getTaskIdByNumber(projectId, taskNumber);
          }
        }
      }

      commitsToUpsert.add({
        'project_id': projectId,
        'user_id': userId,
        'commit_sha': sha,
        'message': message,
        'task_id': taskId,
        'created_at': dateStr ?? DateTime.now().toIso8601String(),
      });
    }

    if (commitsToUpsert.isNotEmpty) {
      await _supabaseClient
          .from('github_commits')
          .upsert(
            commitsToUpsert,
            onConflict: 'project_id, commit_sha',
          );
    }
  }
}
