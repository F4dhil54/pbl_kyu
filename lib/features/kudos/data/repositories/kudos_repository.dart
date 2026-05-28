import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/activity_model.dart';

class KudosRepository {
  final SupabaseClient _supabaseClient;
  
  // Local/memory fallback for offline or local testing
  static final List<Map<String, dynamic>> _localKudos = [];

  KudosRepository(this._supabaseClient);

  /// Menghitung poin berdasarkan emoji reaksi
  int getEmojiPoints(String emoji) {
    // Menghapus emoji modifier jika ada (seperti tone warna kulit) untuk kecocokan dasar
    final baseEmoji = emoji.runes.first;
    final thumbsUp = '👍'.runes.first;
    final fire = '🔥'.runes.first;
    final clap = '👏'.runes.first;
    final hearts = '🥰'.runes.first;

    if (baseEmoji == thumbsUp || baseEmoji == fire || baseEmoji == clap) {
      return 15;
    } else if (baseEmoji == hearts) {
      return 10;
    }
    return 10; // Default
  }

  /// Mengambil daftar aktivitas proyek (tugas progress & commit GitHub)
  Future<List<ActivityModel>> getActivities({int limit = 10, int offset = 0}) async {
    final user = _supabaseClient.auth.currentUser;
    if (user == null) {
      return _getLocalActivities();
    }

    try {
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
        debugPrint("=== WARNING: Failed to fetch role in getActivities, falling back to metadata. Error: $profileError ===");
        role = user.userMetadata?['role'] ?? 'Tim';
      }

      // 1. Ambil proyek yang relevan berdasarkan peran (Manajer vs Tim)
      List<String> projectIds = [];
      Map<String, String> projectNames = {};

      if (role == 'Manajer') {
        final projRes = await _supabaseClient
            .from('projects')
            .select('id, nama_proyek')
            .eq('pembuat_id', userId);
        
        final list = projRes as List<dynamic>;
        for (var p in list) {
          final id = p['id'] as String;
          projectIds.add(id);
          projectNames[id] = p['nama_proyek'] as String;
        }
      } else {
        final pmRes = await _supabaseClient
            .from('project_members')
            .select('project_id')
            .eq('user_id', userId)
            .eq('status_akses', 'aktif');
        
        final list = pmRes as List<dynamic>;
        final pIds = list.map((m) => m['project_id'] as String).toList();
        
        if (pIds.isNotEmpty) {
          final pRes = await _supabaseClient
              .from('projects')
              .select('id, nama_proyek')
              .inFilter('id', pIds);
              
          for (var p in pRes as List<dynamic>) {
            final id = p['id'] as String;
            projectIds.add(id);
            projectNames[id] = p['nama_proyek'] as String;
          }
        }
      }

      if (projectIds.isEmpty) return _getLocalActivities();

      // 2. Query timeline_aktivitas_terbaru view
      final response = await _supabaseClient
          .from('timeline_aktivitas_terbaru')
          .select()
          .inFilter('project_id', projectIds)
          .order('waktu_aktivitas', ascending: false)
          .range(offset, offset + limit - 1);

      final List<dynamic> rows = response as List<dynamic>;
      if (rows.isEmpty) {
        return [];
      }

      // 3. Batch resolve task_ids and commit_shas
      final List<String> progressLogIds = [];
      final List<String> commitIds = [];

      for (var row in rows) {
        final type = row['tipe_aktivitas'] as String? ?? 'progress';
        final id = row['aktivitas_id'] as String;
        if (type == 'progress') {
          progressLogIds.add(id);
        } else if (type == 'commit') {
          commitIds.add(id);
        }
      }

      final Map<String, String> logIdToTaskId = {};
      if (progressLogIds.isNotEmpty) {
        final logs = await _supabaseClient
            .from('task_progress_logs')
            .select('id, task_id')
            .inFilter('id', progressLogIds);
        for (var l in logs as List<dynamic>) {
          logIdToTaskId[l['id'] as String] = l['task_id'] as String;
        }
      }

      final Map<String, String> commitIdToSha = {};
      final Map<String, String?> commitIdToTaskId = {};
      if (commitIds.isNotEmpty) {
        final commits = await _supabaseClient
            .from('github_commits')
            .select('id, commit_sha, task_id')
            .inFilter('id', commitIds);
        for (var c in commits as List<dynamic>) {
          commitIdToSha[c['id'] as String] = c['commit_sha'] as String;
          commitIdToTaskId[c['id'] as String] = c['task_id'] as String?;
        }
      }

      // 4. Load all Kudos for grouping
      final kudosRes = await _supabaseClient
          .from('kudos')
          .select('*, profiles:profiles!kudos_pengirim_id_fkey(id, nama, avatar_url)')
          .inFilter('project_id', projectIds);
      final listKudos = kudosRes as List<dynamic>;

      Map<String, List<KudosReaction>> reactionsByTaskId = {};
      Map<String, List<KudosReaction>> reactionsByCommitId = {};

      for (var k in listKudos) {
        final r = KudosReaction.fromJson(k);
        final tId = k['task_id'] as String?;
        final cId = k['github_commit_id'] as String?;
        if (tId != null) {
          reactionsByTaskId.putIfAbsent(tId, () => []).add(r);
        }
        if (cId != null) {
          reactionsByCommitId.putIfAbsent(cId, () => []).add(r);
        }
      }

      // 5. Map to ActivityModel
      final List<ActivityModel> activities = [];
      for (var row in rows) {
        final id = row['aktivitas_id'] as String;
        final type = row['tipe_aktivitas'] as String? ?? 'progress';
        final pId = row['project_id'] as String;
        final pName = row['nama_proyek'] as String? ?? projectNames[pId] ?? 'Proyek';
        final userName = row['nama_user'] as String? ?? 'Anggota';
        final userAvatar = row['avatar_user'] as String?;
        final time = DateTime.tryParse(row['waktu_aktivitas'] as String? ?? '')?.toLocal() ?? DateTime.now();
        final userId = row['user_id'] as String;

        String actionText = '';
        String linkText = row['konten_utama'] as String? ?? '';
        String? taskId;
        String? commitSha;
        List<KudosReaction> reactions = [];

        if (type == 'progress') {
          final status = row['status_detail'] as String? ?? 'Sedang Dikerjakan';
          actionText = (status == 'Selesai' || status == 'Selesai Dikerjakan')
              ? 'sudah menyelesaikan'
              : 'sedang mengerjakan';
          taskId = logIdToTaskId[id];
          if (taskId != null) {
            reactions = reactionsByTaskId[taskId] ?? [];
          }
        } else if (type == 'commit') {
          commitSha = commitIdToSha[id];
          final shortSha = (commitSha != null && commitSha.length > 7) ? commitSha.substring(0, 7) : (commitSha ?? '');
          actionText = 'melakukan commit "$shortSha"';
          taskId = commitIdToTaskId[id];
          reactions = reactionsByCommitId[id] ?? [];
        }

        activities.add(ActivityModel(
          id: id,
          userName: userName,
          userAvatar: userAvatar,
          actionText: actionText,
          linkText: linkText,
          time: time,
          type: type,
          taskId: taskId,
          projectId: pId,
          projectName: pName,
          userId: userId,
          commitSha: commitSha,
          reactions: reactions,
        ));
      }

      return activities;

    } catch (e) {
      debugPrint("Error fetching activities from Supabase: $e");
      return _getLocalActivities();
    }
  }

  /// Mengirim Kudos (Upsert)
  Future<void> giveKudos({
    required String projectId,
    String? taskId,
    required String receiverId,
    required String emoji,
    String? commitSha,
  }) async {
    final user = _supabaseClient.auth.currentUser;
    if (user == null) {
      _giveLocalKudos(projectId, taskId, receiverId, emoji, commitSha);
      return;
    }

    final userId = user.id;
    if (userId == receiverId) {
      throw Exception('Tidak bisa memberikan kudos kepada diri sendiri.');
    }

    try {
      final poinKudos = getEmojiPoints(emoji);

      if (taskId == null) {
        // 1. Kudos Umum / Commit
        String? githubCommitId;
        if (commitSha != null) {
          final res = await _supabaseClient
              .from('github_commits')
              .select('id')
              .eq('project_id', projectId)
              .eq('commit_sha', commitSha)
              .maybeSingle();
          if (res != null) {
            githubCommitId = res['id'] as String?;
          }
        }

        final targetPesan = commitSha != null ? 'commit:$commitSha' : 'Apresiasi Umum';

        await _supabaseClient.from('kudos').insert({
          'pengirim_id': userId,
          'penerima_id': receiverId,
          'project_id': projectId,
          'task_id': null,
          'reaksi_emoji': emoji,
          'pesan_apresiasi': targetPesan,
          'poin_kudos': poinKudos,
          'github_commit_id': githubCommitId,
        });
      } else {
        // 2. Kudos Spesifik Tugas
        await _supabaseClient.from('kudos').insert({
          'pengirim_id': userId,
          'penerima_id': receiverId,
          'project_id': projectId,
          'task_id': taskId,
          'reaksi_emoji': emoji,
          'pesan_apresiasi': 'Apresiasi tugas',
          'poin_kudos': poinKudos,
          'github_commit_id': null,
        });
      }

      // 3. Masukkan notifikasi opsional
      try {
        await _supabaseClient.from('notifications').insert({
          'user_id': receiverId,
          'project_id': projectId,
          'tipe_notifikasi': 'kudos_received',
          'judul': 'Kudos Diterima!',
          'pesan': 'Seseorang memberikan reaksi $emoji untuk kontribusi Anda.',
          'peran_penerima': 'member',
          'link_type': taskId != null ? 'task' : 'project',
          'link_id': taskId ?? projectId,
        });
      } catch (_) {}

    } catch (e) {
      debugPrint("Error sending kudos to Supabase: $e");
      _giveLocalKudos(projectId, taskId, receiverId, emoji, commitSha);
    }
  }

  /// Mengambil leaderboard proyek berdasarkan poin emoji kustom
  Future<List<Map<String, dynamic>>> getLeaderboard(String projectId) async {
    final user = _supabaseClient.auth.currentUser;
    if (user == null) {
      return _getLocalLeaderboard(projectId);
    }

    try {
      final res = await _supabaseClient
          .from('kudos_leaderboard')
          .select()
          .eq('project_id', projectId)
          .order('total_kudos', ascending: false);

      final list = res as List<dynamic>;
      if (list.isEmpty) {
        // Fallback untuk mencari member saja jika view kosong
        try {
          final pmRes = await _supabaseClient
              .from('project_members')
              .select('user_id, profiles:profiles!project_members_user_id_fkey(id, nama, email, avatar_url)')
              .eq('project_id', projectId)
              .eq('status_akses', 'aktif');
          
          final membersList = pmRes as List<dynamic>;
          List<Map<String, dynamic>> emptyLeaderboard = [];
          for (var pm in membersList) {
            final profile = pm['profiles'] as Map<String, dynamic>?;
            if (profile != null) {
              final uId = profile['id'] as String;
              emptyLeaderboard.add({
                'penerima_id': uId,
                'nama': profile['nama'] ?? 'Anggota',
                'avatar_url': profile['avatar_url'],
                'total_kudos': 0,
                'score': 0,
                'emojis': [],
              });
            }
          }
          if (emptyLeaderboard.isEmpty) return _getLocalLeaderboard(projectId);
          return emptyLeaderboard;
        } catch (_) {
          return _getLocalLeaderboard(projectId);
        }
      }

      return list.map((item) => {
        'penerima_id': item['penerima_id'],
        'nama': item['nama'] ?? 'User',
        'avatar_url': item['avatar_url'],
        'total_kudos': item['total_kudos'] ?? 0,
        'score': item['total_kudos'] ?? 0, // di view total_kudos adalah poin totalnya
        'emojis': item['emojis'] ?? [],
      }).toList();

    } catch (e) {
      debugPrint("Error fetching leaderboard: $e");
      return _getLocalLeaderboard(projectId);
    }
  }

  // --- LOCAL FALLBACK LOGIC ---

  List<ActivityModel> _getLocalActivities() {
    final now = DateTime.now();
    return [
      ActivityModel(
        id: 'local-log-1',
        userName: 'Dea',
        actionText: 'sudah menyelesaikan',
        linkText: 'Task Design System',
        time: now.subtract(const Duration(hours: 2)),
        type: 'progress',
        projectId: 'local-1',
        projectName: 'Kampanye Brand Q4',
        userId: 'local-dea',
        reactions: _getLocalReactions('local-log-1'),
      ),
      ActivityModel(
        id: 'local-commit-1',
        userName: 'Dian',
        actionText: 'melakukan commit "a7f82b1"',
        linkText: 'Refactor: navigation logic and layout bindings',
        time: now.subtract(const Duration(hours: 5)),
        type: 'commit',
        projectId: 'local-1',
        projectName: 'Kampanye Brand Q4',
        userId: 'local-dian',
        commitSha: 'a7f82b1',
        reactions: _getLocalReactions('a7f82b1'),
      ),
      ActivityModel(
        id: 'local-log-2',
        userName: 'Sukma',
        actionText: 'sedang mengerjakan',
        linkText: 'Migrasi Database Utama',
        time: now.subtract(const Duration(days: 1)),
        type: 'progress',
        projectId: 'local-2',
        projectName: 'Migrasi Cloud Fase 2',
        userId: 'local-sukma',
        reactions: _getLocalReactions('local-log-2'),
      ),
    ];
  }

  List<KudosReaction> _getLocalReactions(String key) {
    return _localKudos
        .where((k) => k['task_id'] == key || k['pesan_apresiasi'] == 'commit:$key')
        .map((k) => KudosReaction(
              id: k['id'] ?? '',
              pengirimId: k['pengirim_id'] ?? 'local-sender',
              pengirimNama: 'Rekan Kerja',
              reaksiEmoji: k['reaksi_emoji'] ?? '👏🏻',
            ))
        .toList();
  }

  void _giveLocalKudos(
    String projectId,
    String? taskId,
    String receiverId,
    String emoji,
    String? commitSha,
  ) {
    // Sesuai Opsi A, hapus removeWhere agar poin selalu terakumulasi (tidak ada yang ditimpa)
    
    _localKudos.add({
      'id': 'local-kudos-${DateTime.now().millisecondsSinceEpoch}',
      'pengirim_id': 'local-sender',
      'penerima_id': receiverId,
      'project_id': projectId,
      'task_id': taskId,
      'reaksi_emoji': emoji,
      'pesan_apresiasi': commitSha != null ? 'commit:$commitSha' : 'Apresiasi tugas',
    });
  }

  List<Map<String, dynamic>> _getLocalLeaderboard(String projectId) {
    // Generate simulated dynamic leaderboard for offline mode
    Map<String, Map<String, dynamic>> scores = {
      'local-sukma': {'score': 1205, 'total_kudos': 20, 'emojis': <String>{'👏🏻', '🔥', '👍🏻'}},
      'local-dea': {'score': 840, 'total_kudos': 15, 'emojis': <String>{'👏🏻', '🥰'}},
      'local-dian': {'score': 790, 'total_kudos': 12, 'emojis': <String>{'👍🏻', '🥰'}},
    };
    
    // Add points from local kudos
    for (var k in _localKudos) {
      if (k['project_id'] == projectId) {
        final pId = k['penerima_id'] as String;
        final emoji = k['reaksi_emoji'] as String;
        final pts = getEmojiPoints(emoji);
        
        scores.putIfAbsent(pId, () => {'score': 0, 'total_kudos': 0, 'emojis': <String>{}});
        
        scores[pId]!['score'] = (scores[pId]!['score'] as int) + pts;
        scores[pId]!['total_kudos'] = (scores[pId]!['total_kudos'] as int) + 1;
        (scores[pId]!['emojis'] as Set<String>).add(emoji);
      }
    }

    final list = [
      {'penerima_id': 'local-sukma', 'nama': 'Sukma', 'avatar_url': 'image/ic_avatar_sukma.png', 'total_kudos': scores['local-sukma']!['total_kudos'], 'score': scores['local-sukma']!['score'], 'emojis': (scores['local-sukma']!['emojis'] as Set<String>).toList()},
      {'penerima_id': 'local-dea', 'nama': 'Dea', 'avatar_url': 'image/ic_avatar_dea.png', 'total_kudos': scores['local-dea']!['total_kudos'], 'score': scores['local-dea']!['score'], 'emojis': (scores['local-dea']!['emojis'] as Set<String>).toList()},
      {'penerima_id': 'local-dian', 'nama': 'Dian', 'avatar_url': 'image/ic_avatar_dian.png', 'total_kudos': scores['local-dian']!['total_kudos'], 'score': scores['local-dian']!['score'], 'emojis': (scores['local-dian']!['emojis'] as Set<String>).toList()},
    ];
    
    // tambahkan entri untuk user lokal baru yang tidak ada di hardcode
    scores.forEach((key, value) {
      if (key != 'local-sukma' && key != 'local-dea' && key != 'local-dian') {
        list.add({
          'penerima_id': key,
          'nama': key.startsWith('local-') ? key.substring(6) : 'User',
          'avatar_url': null,
          'total_kudos': value['total_kudos'],
          'score': value['score'],
          'emojis': (value['emojis'] as Set<String>).toList(),
        });
      }
    });
    
    list.sort((a, b) => (b['score'] as int).compareTo(a['score'] as int));
    return list;
  }
}
