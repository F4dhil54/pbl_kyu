import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/activity_model.dart';

class KudosRepository {
  final SupabaseClient _supabaseClient;
  
  // Fallback lokal offline
  static final List<Map<String, dynamic>> _localKudos = [];

  KudosRepository(this._supabaseClient);

  /// Hitung poin dari emoji
  int getEmojiPoints(String emoji) {
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
    return 10;
  }

  /// Ambil daftar aktivitas proyek
  Future<List<ActivityModel>> getActivities({int limit = 10, int offset = 0}) async {
    final user = _supabaseClient.auth.currentUser;
    if (user == null) {
      return [];
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

      // Ambil proyek sesuai peran
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

      if (projectIds.isEmpty) return [];

      // Query view timeline
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

      // Resolve profil untuk avatar
      final Set<String> activityUserIds = {};
      final List<String> progressLogIds = [];
      final List<String> commitIds = [];
      
      for (var row in rows) {
        activityUserIds.add(row['user_id'] as String);
        final type = row['tipe_aktivitas'] as String? ?? 'progress';
        final id = row['aktivitas_id'] as String;
        if (type == 'progress') {
          progressLogIds.add(id);
        } else if (type == 'commit' || type == 'github') {
          commitIds.add(id);
        }
      }

      final profilesFuture = _supabaseClient
          .from('profiles')
          .select('id, nama, avatar_url')
          .inFilter('id', activityUserIds.toList());

      final logsFuture = progressLogIds.isNotEmpty
          ? _supabaseClient
              .from('task_progress_logs')
              .select('id, task_id')
              .inFilter('id', progressLogIds)
          : Future.value([]);

      final commitsFuture = commitIds.isNotEmpty
          ? _supabaseClient
              .from('github_commits')
              .select('id, commit_sha, task_id')
              .inFilter('id', commitIds)
          : Future.value([]);

      final kudosFuture = _supabaseClient
          .from('kudos')
          .select('*, profiles:profiles!kudos_pengirim_id_fkey(id, nama, avatar_url)')
          .inFilter('project_id', projectIds);

      final results = await Future.wait([
        profilesFuture,
        logsFuture,
        commitsFuture,
        kudosFuture,
      ]);

      final profilesRes = results[0];
      final logsRes = results[1];
      final commitsRes = results[2];
      final listKudos = results[3];

      final Map<String, String?> userAvatars = {};
      final Map<String, String> userNames = {};
      for (var p in profilesRes) {
        userAvatars[p['id'] as String] = p['avatar_url'] as String?;
        userNames[p['id'] as String] = p['nama'] as String? ?? 'Anggota';
      }

      final Map<String, String> logIdToTaskId = {};
      for (var l in logsRes) {
        logIdToTaskId[l['id'] as String] = l['task_id'] as String;
      }

      final Map<String, String> commitIdToSha = {};
      final Map<String, String?> commitIdToTaskId = {};
      for (var c in commitsRes) {
        commitIdToSha[c['id'] as String] = c['commit_sha'] as String;
        commitIdToTaskId[c['id'] as String] = c['task_id'] as String?;
      }

      // Kelompokkan Kudos Supabase
      Map<String, List<KudosReaction>> reactionsByLogId = {};
      Map<String, List<KudosReaction>> reactionsByCommitSha = {};
      Map<String, List<KudosReaction>> reactionsByTaskId = {};
      Map<String, List<KudosReaction>> reactionsByGithubCommitId = {};

      for (var k in listKudos) {
        final r = KudosReaction.fromJson(k);
        final tId = k['task_id'] as String?;
        final logId = k['task_progress_log_id'] as String?;
        final commitId = k['github_commit_id'] as String?;
        final pesan = k['pesan_apresiasi'] as String? ?? '';
        
        if (logId != null) {
          reactionsByLogId.putIfAbsent(logId, () => []).add(r);
        } 
        if (tId != null) {
          reactionsByTaskId.putIfAbsent(tId, () => []).add(r);
        } 
        if (commitId != null) {
          reactionsByGithubCommitId.putIfAbsent(commitId, () => []).add(r);
        } 
        if (pesan.startsWith('commit:')) {
          final sha = pesan.replaceFirst('commit:', '');
          reactionsByCommitSha.putIfAbsent(sha, () => []).add(r);
        }
      }

      // Gabung Kudos lokal (fallback)
      for (var k in _localKudos) {
        final r = KudosReaction(
          id: k['id'] ?? '',
          pengirimId: k['pengirim_id'] ?? userId,
          pengirimNama: 'Anda (Offline)',
          reaksiEmoji: k['reaksi_emoji'] ?? '👏🏻',
        );
        final tId = k['task_id'] as String?;
        final logId = k['task_progress_log_id'] as String?;
        final commitId = k['github_commit_id'] as String?;
        final pesan = k['pesan_apresiasi'] as String? ?? '';
        
        if (logId != null) {
          reactionsByLogId.putIfAbsent(logId, () => []).add(r);
        } 
        if (tId != null) {
          reactionsByTaskId.putIfAbsent(tId, () => []).add(r);
        } 
        if (commitId != null) {
          reactionsByGithubCommitId.putIfAbsent(commitId, () => []).add(r);
        } 
        
        if (pesan.startsWith('commit_id:')) {
          final cid = pesan.replaceFirst('commit_id:', '');
          reactionsByGithubCommitId.putIfAbsent(cid, () => []).add(r);
        } else if (pesan.startsWith('commit:')) {
          final sha = pesan.replaceFirst('commit:', '');
          reactionsByCommitSha.putIfAbsent(sha, () => []).add(r);
        }
      }

      // Map ke ActivityModel
      final List<ActivityModel> activities = [];
      for (var row in rows) {
        final id = row['aktivitas_id'] as String;
        final type = row['tipe_aktivitas'] as String? ?? 'progress';
        final pId = row['project_id'] as String;
        final pName = row['nama_proyek'] as String? ?? projectNames[pId] ?? 'Proyek';
        final userId = row['user_id'] as String;
        final userName = userNames[userId] ?? row['nama_user'] as String? ?? 'Anggota';
        final userAvatar = userAvatars[userId] ?? row['avatar_user'] as String? ?? row['avatar_url'] as String?;
        final time = DateTime.tryParse(row['waktu_aktivitas'] as String? ?? '')?.toLocal() ?? DateTime.now();

        String actionText = '';
        String linkText = row['konten_utama'] as String? ?? '';
        String? taskId;
        String? commitSha;
        List<KudosReaction> reactions = [];

        if (type == 'progress') {
          final status = (row['status_detail'] as String? ?? 'Sedang Dikerjakan').trim();
          final cleanStatus = status.toLowerCase();
          if (cleanStatus != 'sedang dikerjakan' && cleanStatus != 'selesai' && cleanStatus != 'selesai dikerjakan') {
            continue;
          }
          
          actionText = (status == 'Selesai' || status == 'Selesai Dikerjakan')
              ? 'sudah menyelesaikan'
              : 'sedang mengerjakan';
          taskId = logIdToTaskId[id];
          if (taskId != null) {
            reactions = (reactionsByLogId[id] ?? reactionsByTaskId[taskId]) ?? [];
          }
        } else if (type == 'commit' || type == 'github') {
          // Sembunyikan 'initial commit'
          if (linkText.toLowerCase().contains('initial commit')) {
            continue;
          }
          
          commitSha = commitIdToSha[id];
          final shortSha = (commitSha != null && commitSha.length > 7) ? commitSha.substring(0, 7) : (commitSha ?? '');
          actionText = 'melakukan commit "$shortSha"';
          taskId = commitIdToTaskId[id];
          
          reactions = reactionsByGithubCommitId[id] ?? [];
          if (reactions.isEmpty && commitSha != null) {
            reactions = reactionsByCommitSha[commitSha] ?? [];
          }
          
          // Fallback Darurat
          if (reactions.isEmpty) {
            for (var r in listKudos) {
              final kId = r['github_commit_id'] as String?;
              final kPesan = r['pesan_apresiasi'] as String? ?? '';
              if (kId == id || kPesan == 'commit:$commitSha' || kPesan == 'commit_id:$id') {
                final profile = r['profiles'] as Map<String, dynamic>?;
                reactions.add(KudosReaction(
                  id: r['id'] as String,
                  pengirimId: r['pengirim_id'] as String,
                  pengirimNama: profile?['nama'] as String? ?? 'Anggota',
                  reaksiEmoji: r['reaksi_emoji'] as String? ?? '👏',
                ));
              }
            }
          }
          
          debugPrint("=== DEBUG KUDOS === type: $type, id: $id, reactionsCount: ${reactions.length}");
          if (reactions.isEmpty) {
            debugPrint("=== DEBUG KUDOS === Check keys in reactionsByGithubCommitId: ${reactionsByGithubCommitId.keys.toList()}");
          }
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
      return [];
    }
  }

  /// Kirim Kudos
  Future<String> giveKudos({
    required String projectId,
    required String? taskId,
    required String? taskProgressLogId,
    required String receiverId,
    required String emoji,
    required String? commitSha,
    required String? githubCommitId,
  }) async {
    final user = _supabaseClient.auth.currentUser;
    if (user == null) {
      _giveLocalKudos(projectId, taskId, taskProgressLogId, receiverId, emoji, commitSha);
      return 'local';
    }

    final userId = user.id;
    if (userId == receiverId) {
      throw Exception('Tidak bisa memberikan kudos kepada diri sendiri.');
    }

    try {
      final poinKudos = getEmojiPoints(emoji);

      if (taskProgressLogId != null) {
        // Kudos Log Tugas
        final existing = await _supabaseClient
            .from('kudos')
            .select('id, reaksi_emoji')
            .eq('pengirim_id', userId)
            .eq('task_progress_log_id', taskProgressLogId)
            .maybeSingle();

        if (existing != null) {
          final oldEmoji = existing['reaksi_emoji'] as String?;
          if (oldEmoji != null && oldEmoji.runes.first == emoji.runes.first) {
            // Tarik
            await _supabaseClient.from('kudos').delete().eq('id', existing['id']);
            debugPrint("=== INFO: Retracted kudos emoji $emoji for progress log ===");
            return 'retracted';
          } else {
            // Tukar
            await _supabaseClient.from('kudos').update({
              'reaksi_emoji': emoji,
            }).eq('id', existing['id']);
            debugPrint("=== INFO: Swapped kudos emoji to $emoji for progress log ===");
            await _sendKudosNotification(receiverId: receiverId, senderId: userId, projectId: projectId, taskId: taskId, emoji: emoji, isSwap: true);
            return 'swapped';
          }
        }

        await _supabaseClient.from('kudos').insert({
          'pengirim_id': userId,
          'penerima_id': receiverId,
          'project_id': projectId,
          'task_id': taskId,
          'task_progress_log_id': taskProgressLogId,
          'reaksi_emoji': emoji,
          'pesan_apresiasi': 'Apresiasi log progres',
          'poin_kudos': poinKudos,
        });
      } else if (githubCommitId != null || commitSha != null) {
        // Kudos Commit
        final targetPesan = commitSha != null ? 'commit:$commitSha' : (githubCommitId != null ? 'commit_id:$githubCommitId' : 'Apresiasi Umum');

        // Cek reaksi yang ada
        var query = _supabaseClient
            .from('kudos')
            .select('id, reaksi_emoji')
            .eq('pengirim_id', userId)
            .eq('project_id', projectId);

        if (githubCommitId != null && commitSha != null) {
          query = query.or('github_commit_id.eq.$githubCommitId,pesan_apresiasi.eq.commit:$commitSha');
        } else if (githubCommitId != null) {
          query = query.eq('github_commit_id', githubCommitId);
        } else if (commitSha != null) {
          query = query.eq('pesan_apresiasi', targetPesan);
        } else {
          query = query.eq('pesan_apresiasi', targetPesan);
        }

        final existing = await query.maybeSingle();

        if (existing != null) {
          final oldEmoji = existing['reaksi_emoji'] as String?;
          if (oldEmoji != null && oldEmoji.runes.first == emoji.runes.first) {
            // Tarik
            await _supabaseClient.from('kudos').delete().eq('id', existing['id']);
            debugPrint("=== INFO: Retracted kudos emoji $emoji for commit ===");
            return 'retracted';
          } else {
            // Tukar
            await _supabaseClient.from('kudos').update({
              'reaksi_emoji': emoji,
            }).eq('id', existing['id']);
            debugPrint("=== INFO: Swapped kudos emoji to $emoji for commit ===");
            await _sendKudosNotification(receiverId: receiverId, senderId: userId, projectId: projectId, taskId: taskId, emoji: emoji, isSwap: true);
            return 'swapped';
          }
        }

        if (receiverId.isEmpty) {
          throw Exception("Pengguna ini belum menautkan akun GitHub-nya ke KYU.");
        }

        try {
          await _supabaseClient.from('kudos').insert({
            'pengirim_id': userId,
            'penerima_id': receiverId,
            'project_id': projectId,
            'task_id': githubCommitId != null ? null : taskId, // Bypass konflik unik
            'task_progress_log_id': null, 
            'reaksi_emoji': emoji,
            'pesan_apresiasi': targetPesan,
            'github_commit_id': githubCommitId,
            'poin_kudos': poinKudos,
          });
        } catch (e) {
          rethrow;
        }
      } else if (taskId != null) {
        // Kudos Tugas (Fallback)
        final existing = await _supabaseClient
            .from('kudos')
            .select('id, reaksi_emoji')
            .eq('pengirim_id', userId)
            .eq('task_id', taskId)
            .isFilter('task_progress_log_id', null)
            .isFilter('github_commit_id', null)
            .maybeSingle();

        if (existing != null) {
          final oldEmoji = existing['reaksi_emoji'] as String?;
          if (oldEmoji != null && oldEmoji.runes.first == emoji.runes.first) {
            // Tarik
            await _supabaseClient.from('kudos').delete().eq('id', existing['id']);
            debugPrint("=== INFO: Retracted kudos emoji $emoji for task ===");
            return 'retracted';
          } else {
            // Tukar
            await _supabaseClient.from('kudos').update({
              'reaksi_emoji': emoji,
            }).eq('id', existing['id']);
            debugPrint("=== INFO: Swapped kudos emoji to $emoji for task ===");
            await _sendKudosNotification(receiverId: receiverId, senderId: userId, projectId: projectId, taskId: taskId, emoji: emoji, isSwap: true);
            return 'swapped';
          }
        }

        await _supabaseClient.from('kudos').insert({
          'pengirim_id': userId,
          'penerima_id': receiverId,
          'project_id': projectId,
          'task_id': taskId,
          'task_progress_log_id': null,
          'reaksi_emoji': emoji,
          'pesan_apresiasi': 'Apresiasi tugas',
          'poin_kudos': poinKudos,
        });
      } else {
        // Kudos Umum
        final targetPesan = 'Apresiasi Umum';

        var query = _supabaseClient
            .from('kudos')
            .select('id, reaksi_emoji')
            .eq('pengirim_id', userId)
            .eq('project_id', projectId)
            .eq('pesan_apresiasi', targetPesan);

        final existing = await query.maybeSingle();

        if (existing != null) {
          final oldEmoji = existing['reaksi_emoji'] as String?;
          if (oldEmoji != null && oldEmoji.runes.first == emoji.runes.first) {
            // Tarik
            await _supabaseClient.from('kudos').delete().eq('id', existing['id']);
            debugPrint("=== INFO: Retracted kudos emoji $emoji for general appreciation ===");
            return 'retracted';
          } else {
            // Tukar
            await _supabaseClient.from('kudos').update({
              'reaksi_emoji': emoji,
            }).eq('id', existing['id']);
            debugPrint("=== INFO: Swapped kudos emoji to $emoji for general appreciation ===");
            await _sendKudosNotification(receiverId: receiverId, senderId: userId, projectId: projectId, taskId: taskId, emoji: emoji, isSwap: true);
            return 'swapped';
          }
        }

        try {
          await _supabaseClient.from('kudos').insert({
            'pengirim_id': userId,
            'penerima_id': receiverId,
            'project_id': projectId,
            'task_id': null, 
            'task_progress_log_id': null, 
            'reaksi_emoji': emoji,
            'pesan_apresiasi': targetPesan,
            'github_commit_id': null,
            'poin_kudos': poinKudos,
          });
        } catch (e) {
          rethrow;
        }
      }

      // Kirim notifikasi
      await _sendKudosNotification(
        receiverId: receiverId,
        senderId: userId,
        projectId: projectId,
        taskId: taskId,
        emoji: emoji,
        isSwap: false,
      );
    } catch (e, stack) {
      debugPrint("Error sending kudos to Supabase: $e\n$stack");
      if (e.toString().contains('42501') || e.toString().contains('Unauthorized')) {
        throw Exception('Kudos sudah diberikan sebelumnya dan tidak dapat diubah karena aturan keamanan database.');
      }
      rethrow;
    }
    return 'inserted';
  }

  Future<void> _sendKudosNotification({
    required String receiverId,
    required String senderId,
    required String projectId,
    required String? taskId,
    required String emoji,
    required bool isSwap,
  }) async {
    try {
      await _supabaseClient.from('notifications').insert({
        'user_id': receiverId,
        'sender_id': senderId,
        'project_id': projectId,
        'tipe_notifikasi': 'kudos_received',
        'judul': isSwap ? 'Kudos Diubah!' : 'Kudos Diterima!',
        'pesan': 'Seseorang memberikan reaksi $emoji untuk kontribusi Anda.',
        'peran_penerima': 'member',
        'link_type': taskId != null ? 'task' : 'project',
        'link_id': taskId ?? projectId,
      });
    } catch (e) {
      debugPrint("Error inserting notification: $e");
    }
  }

  /// Ambil leaderboard proyek
  Future<List<Map<String, dynamic>>> getLeaderboard(String projectId) async {
    final user = _supabaseClient.auth.currentUser;
    if (user == null) {
      return [];
    }

    try {
      // 1. Ambil member proyek
      final pmRes = await _supabaseClient
          .from('project_members')
          .select('user_id, profiles:profiles!project_members_user_id_fkey(id, nama, email, avatar_url)')
          .eq('project_id', projectId)
          .eq('status_akses', 'aktif');
      
      final membersList = pmRes as List<dynamic>;
      Map<String, Map<String, dynamic>> leaderboardMap = {};
      
      for (var pm in membersList) {
        final profile = pm['profiles'] as Map<String, dynamic>?;
        if (profile != null) {
          final uId = profile['id'] as String;
          leaderboardMap[uId] = {
            'penerima_id': uId,
            'nama': profile['nama'] ?? 'Anggota',
            'avatar_url': profile['avatar_url'],
            'total_kudos': 0,
            'score': 0,
            'emojis': <String>{},
          };
        }
      }

      // 2. Ambil data kudos
      final kudosRes = await _supabaseClient
          .from('kudos')
          .select('penerima_id, reaksi_emoji')
          .eq('project_id', projectId);
          
      final kudosList = kudosRes as List<dynamic>;
      
      // Ambil profil yang tidak aktif
      final Set<String> missingProfileIds = {};
      for (var k in kudosList) {
        final pId = k['penerima_id'] as String;
        if (!leaderboardMap.containsKey(pId)) {
          missingProfileIds.add(pId);
        }
      }
      
      if (missingProfileIds.isNotEmpty) {
        final missingProfilesRes = await _supabaseClient
            .from('profiles')
            .select('id, nama, avatar_url')
            .inFilter('id', missingProfileIds.toList());
            
        for (var p in missingProfilesRes as List<dynamic>) {
          final uId = p['id'] as String;
          leaderboardMap[uId] = {
            'penerima_id': uId,
            'nama': p['nama'] ?? 'Anggota',
            'avatar_url': p['avatar_url'],
            'total_kudos': 0,
            'score': 0,
            'emojis': <String>{},
          };
        }
      }
      
      // 3. Hitung skor manual
      for (var k in kudosList) {
        final pId = k['penerima_id'] as String;
        final emoji = k['reaksi_emoji'] as String?;
        if (emoji == null) continue;
        
        final pts = getEmojiPoints(emoji);
        
        if (leaderboardMap.containsKey(pId)) {
          leaderboardMap[pId]!['score'] = (leaderboardMap[pId]!['score'] as int) + pts;
          leaderboardMap[pId]!['total_kudos'] = (leaderboardMap[pId]!['total_kudos'] as int) + 1;
          (leaderboardMap[pId]!['emojis'] as Set<String>).add(emoji);
        } else {
          // Fallback user terhapus
          leaderboardMap[pId] = {
            'penerima_id': pId,
            'nama': 'Mantan Anggota',
            'avatar_url': null,
            'total_kudos': 1,
            'score': pts,
            'emojis': <String>{emoji},
          };
        }
      }

      // Tambahkan poin kudos lokal
      for (var k in _localKudos) {
        if (k['project_id'] == projectId) {
          final pId = k['penerima_id'] as String;
          final emoji = k['reaksi_emoji'] as String;
          final pts = getEmojiPoints(emoji);

          if (leaderboardMap.containsKey(pId)) {
            leaderboardMap[pId]!['score'] = (leaderboardMap[pId]!['score'] as int) + pts;
            leaderboardMap[pId]!['total_kudos'] = (leaderboardMap[pId]!['total_kudos'] as int) + 1;
            (leaderboardMap[pId]!['emojis'] as Set<String>).add(emoji);
          } else {
            leaderboardMap[pId] = {
              'penerima_id': pId,
              'nama': 'User (Lokal)',
              'avatar_url': null,
              'total_kudos': 1,
              'score': pts,
              'emojis': <String>{emoji},
            };
          }
        }
      }

      // 4. Konversi Map ke List
      List<Map<String, dynamic>> combinedList = leaderboardMap.values.map((item) {
        return {
          ...item,
          'emojis': (item['emojis'] as Set<String>).toList(),
        };
      }).toList();

      // Urutkan berdasar skor
      combinedList.sort((a, b) => (b['score'] as int).compareTo(a['score'] as int));

      return combinedList;

    } catch (e) {
      debugPrint("Error fetching leaderboard: $e");
      return [];
    }
  }

  // Logika Fallback Lokal

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
    String? taskProgressLogId,
    String receiverId,
    String emoji,
    String? commitSha,
  ) {
    
    _localKudos.add({
      'id': 'local-kudos-${DateTime.now().millisecondsSinceEpoch}',
      'pengirim_id': 'local-sender',
      'penerima_id': receiverId,
      'project_id': projectId,
      'task_id': taskId,
      'task_progress_log_id': taskProgressLogId,
      'reaksi_emoji': emoji,
      'pesan_apresiasi': commitSha != null ? 'commit:$commitSha' : 'Apresiasi tugas',
    });
  }

  List<Map<String, dynamic>> _getLocalLeaderboard(String projectId) {
    // Buat leaderboard simulasi offline
    Map<String, Map<String, dynamic>> scores = {
      'local-sukma': {'score': 1205, 'total_kudos': 20, 'emojis': <String>{'👏🏻', '🔥', '👍🏻'}},
      'local-dea': {'score': 840, 'total_kudos': 15, 'emojis': <String>{'👏🏻', '🥰'}},
      'local-dian': {'score': 790, 'total_kudos': 12, 'emojis': <String>{'👍🏻', '🥰'}},
    };
    
    // Tambah poin lokal
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
    
    // Tambahkan entri user lokal
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
