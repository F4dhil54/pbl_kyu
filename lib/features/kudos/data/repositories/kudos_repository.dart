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
      final role = user.userMetadata?['role'] ?? 'Tim';

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

      // 2. Ambil semua Tugas terkait proyek-proyek ini
      final tasksRes = await _supabaseClient
          .from('tasks')
          .select('id, judul_tugas, project_id')
          .inFilter('project_id', projectIds);
      
      final tasksList = tasksRes as List<dynamic>;
      Map<String, Map<String, String>> taskMeta = {}; // taskId -> {judulTugas, projectId, projectName}
      List<String> taskIds = [];
      for (var t in tasksList) {
        final id = t['id'] as String;
        final pId = t['project_id'] as String;
        taskIds.add(id);
        taskMeta[id] = {
          'judul_tugas': t['judul_tugas'] as String? ?? 'Tugas Tanpa Judul',
          'project_id': pId,
          'projectName': projectNames[pId] ?? 'Proyek',
        };
      }

      // 3. Ambil log progress tugas (task_progress_logs)
      List<Map<String, dynamic>> rawLogs = [];
      if (taskIds.isNotEmpty) {
        final logsRes = await _supabaseClient
            .from('task_progress_logs')
            .select('*, profiles:logged_by(*)')
            .inFilter('task_id', taskIds)
            .order('created_at', ascending: false)
            .range(offset, offset + limit - 1);
        rawLogs = List<Map<String, dynamic>>.from(logsRes as List);
      }

      // 4. Ambil semua Kudos untuk proyek ini (untuk dimuat di card)
      final kudosRes = await _supabaseClient
          .from('kudos')
          .select('*, profiles:profiles!kudos_pengirim_id_fkey(id, nama, avatar_url)')
          .inFilter('project_id', projectIds);
      final listKudos = kudosRes as List<dynamic>;

      // Kelompokkan Kudos (dari Supabase)
      // Key: taskId untuk tugas, atau 'commit:sha' untuk commit
      Map<String, List<KudosReaction>> reactionsMap = {};
      for (var k in listKudos) {
        final r = KudosReaction.fromJson(k);
        final tId = k['task_id'] as String?;
        final pesan = k['pesan_apresiasi'] as String? ?? '';
        
        if (tId != null) {
          reactionsMap.putIfAbsent(tId, () => []).add(r);
        } else if (pesan.startsWith('commit:')) {
          final sha = pesan.replaceFirst('commit:', '');
          reactionsMap.putIfAbsent(sha, () => []).add(r);
        }
      }

      // Gabungkan dengan Kudos lokal (fallback) agar UI langsung update jika RLS/Supabase gagal
      for (var k in _localKudos) {
        final r = KudosReaction(
          id: k['id'] ?? '',
          pengirimId: k['pengirim_id'] ?? userId, // asumsi pengirim adalah user saat ini
          pengirimNama: 'Anda (Offline)',
          reaksiEmoji: k['reaksi_emoji'] ?? '👏🏻',
        );
        final tId = k['task_id'] as String?;
        final pesan = k['pesan_apresiasi'] as String? ?? '';
        
        if (tId != null) {
          reactionsMap.putIfAbsent(tId, () => []).add(r);
        } else if (pesan.startsWith('commit:')) {
          final sha = pesan.replaceFirst('commit:', '');
          reactionsMap.putIfAbsent(sha, () => []).add(r);
        }
      }

      // 5. Ambil Anggota Proyek untuk mensimulasikan commit GitHub nyata
      final membersRes = await _supabaseClient
          .from('project_members')
          .select('project_id, user_id, profiles:profiles!project_members_user_id_fkey(*)')
          .inFilter('project_id', projectIds)
          .eq('status_akses', 'aktif');
      
      final membersList = membersRes as List<dynamic>;
      Map<String, List<Map<String, dynamic>>> projectMembers = {}; // projectId -> member profiles
      for (var m in membersList) {
        final pId = m['project_id'] as String;
        final profile = m['profiles'] as Map<String, dynamic>?;
        if (profile != null) {
          projectMembers.putIfAbsent(pId, () => []).add(profile);
        }
      }

      List<ActivityModel> activities = [];

      // A. Masukkan aktivitas asli dari progress tugas
      for (var log in rawLogs) {
        final tId = log['task_id'] as String;
        final meta = taskMeta[tId];
        if (meta == null) continue;

        final status = log['status_progress'] as String? ?? 'Sedang Dikerjakan';
        final persen = log['persen_selesai'] as int? ?? 0;

        // Validasi status: Hanya "Sedang Dikerjakan", "Selesai Dikerjakan", atau "Selesai"
        if (status != 'Sedang Dikerjakan' && status != 'Selesai Dikerjakan' && status != 'Selesai') {
          continue;
        }

        final profile = log['profiles'] as Map<String, dynamic>? ?? {};
        final userName = profile['nama'] as String? ?? 'Anggota';
        final userAvatar = profile['avatar_url'] as String?;
        final time = DateTime.tryParse(log['created_at'] as String) ?? DateTime.now();

        final actionText = (status == 'Selesai' || status == 'Selesai Dikerjakan')
            ? 'sudah menyelesaikan'
            : 'sedang mengerjakan';

        activities.add(ActivityModel(
          id: log['id'] as String,
          userName: userName,
          userAvatar: userAvatar,
          actionText: actionText,
          linkText: meta['judul_tugas']!,
          time: time,
          type: 'progress',
          taskId: tId,
          projectId: meta['project_id']!,
          projectName: meta['projectName']!,
          userId: log['logged_by'] as String,
          reactions: reactionsMap[tId] ?? [],
        ));
      }

      // B. Masukkan aktivitas commit GitHub buatan (Deterministic mock commits agar terhubung dengan Kudos)
      final now = DateTime.now();
      for (var pId in projectIds) {
        final pName = projectNames[pId] ?? 'Proyek';
        final members = projectMembers[pId] ?? [];
        if (members.isEmpty) continue;

        // Buat 2 commit per proyek berdasarkan anggota proyek tersebut
        for (int i = 0; i < members.length; i++) {
          if (i >= 2) break; // Cukup 2 commit per anggota proyek agar tidak terlalu padat
          
          final member = members[i];
          final mName = member['nama'] as String? ?? 'Anggota';
          final mId = member['id'] as String;
          final mAvatar = member['avatar_url'] as String?;

          // Commit 1: Hari ini
          final sha1 = 'git-commit-${pId.substring(0,4)}-$i-1';
          final shortSha1 = sha1.substring(sha1.length - 7);
          activities.add(ActivityModel(
            id: sha1,
            userName: mName,
            userAvatar: mAvatar,
            actionText: 'melakukan commit "$shortSha1"',
            linkText: i == 0 
                ? 'Refactor: navigation logic and layout bindings'
                : 'Feat: implement responsive components and styles',
            time: now.subtract(Duration(hours: 2 + i * 3, minutes: 15)),
            type: 'commit',
            projectId: pId,
            projectName: pName,
            userId: mId,
            commitSha: shortSha1,
            reactions: reactionsMap[shortSha1] ?? [],
          ));

          // Commit 2: Kemarin
          final sha2 = 'git-commit-${pId.substring(0,4)}-$i-2';
          final shortSha2 = sha2.substring(sha2.length - 7);
          activities.add(ActivityModel(
            id: sha2,
            userName: mName,
            userAvatar: mAvatar,
            actionText: 'melakukan commit "$shortSha2"',
            linkText: i == 0
                ? 'Fix: database connection leak on fast refresh'
                : 'Docs: update codebase architecture documentation',
            time: now.subtract(Duration(days: 1, hours: i * 2)),
            type: 'commit',
            projectId: pId,
            projectName: pName,
            userId: mId,
            commitSha: shortSha2,
            reactions: reactionsMap[shortSha2] ?? [],
          ));
        }
      }

      // Urutkan aktivitas berdasarkan waktu terbaru
      activities.sort((a, b) => b.time.compareTo(a.time));
      
      // Terapkan pagination lokal pada aktivitas gabungan (jika menggunakan mix)
      if (activities.length > offset) {
        activities = activities.sublist(offset, (offset + limit > activities.length) ? activities.length : offset + limit);
      } else {
        activities = [];
      }
      if (activities.isEmpty) {
        final localActs = _getLocalActivities();
        if (projectIds.isNotEmpty) {
          final realProjectId = projectIds.first;
          final realProjectName = projectNames[realProjectId] ?? 'Proyek';
          return localActs.map((act) => ActivityModel(
            id: act.id,
            userName: act.userName,
            userAvatar: act.userAvatar,
            actionText: act.actionText,
            linkText: act.linkText,
            time: act.time,
            type: act.type,
            taskId: act.taskId,
            projectId: realProjectId,
            projectName: realProjectName,
            userId: act.userId,
            commitSha: act.commitSha,
            reactions: act.reactions,
          )).toList();
        }
        return localActs;
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
        final targetPesan = commitSha != null ? 'commit:$commitSha' : 'Apresiasi Umum';

        await _supabaseClient.from('kudos').insert({
          'pengirim_id': userId,
          'penerima_id': receiverId,
          'project_id': projectId,
          'task_id': null,
          'reaksi_emoji': emoji,
          'pesan_apresiasi': targetPesan,
          'poin_kudos': poinKudos,
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

      // Gabungkan hasil dari view Supabase
      List<Map<String, dynamic>> combinedList = list.map((item) => {
        'penerima_id': item['penerima_id'],
        'nama': item['nama'] ?? 'User',
        'avatar_url': item['avatar_url'],
        'total_kudos': item['total_kudos'] ?? 0,
        'score': item['total_kudos'] ?? 0, // di view total_kudos adalah poin totalnya
        'emojis': item['emojis'] ?? [],
      }).toList();

      // Tambahkan poin dari kudos lokal yang tertahan (fallback)
      for (var k in _localKudos) {
        if (k['project_id'] == projectId) {
          final pId = k['penerima_id'] as String;
          final emoji = k['reaksi_emoji'] as String;
          final pts = getEmojiPoints(emoji);

          int index = combinedList.indexWhere((e) => e['penerima_id'] == pId);
          if (index != -1) {
            combinedList[index]['score'] = (combinedList[index]['score'] as int) + pts;
            combinedList[index]['total_kudos'] = (combinedList[index]['total_kudos'] as int) + 1;
            
            // Gabungkan emojis (List)
            var currentEmojis = combinedList[index]['emojis'];
            Set<String> emojiSet = {};
            if (currentEmojis is List) {
              emojiSet.addAll(currentEmojis.map((e) => e.toString()));
            } else if (currentEmojis is Set) {
              emojiSet.addAll(currentEmojis.map((e) => e.toString()));
            }
            emojiSet.add(emoji);
            combinedList[index]['emojis'] = emojiSet.toList();
          } else {
            // Jika penerima belum ada di leaderboard
            combinedList.add({
              'penerima_id': pId,
              'nama': 'User (Lokal)',
              'avatar_url': null,
              'total_kudos': 1,
              'score': pts,
              'emojis': [emoji],
            });
          }
        }
      }

      // Urutkan ulang berdasarkan skor terbaru
      combinedList.sort((a, b) => (b['score'] as int).compareTo(a['score'] as int));

      return combinedList;

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
