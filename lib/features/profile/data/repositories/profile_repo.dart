import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileRepository {
  final SupabaseClient _supabaseClient;

  ProfileRepository(this._supabaseClient);

  // Load undangan
  Future<List<dynamic>> getInvitations(String invitedById) async {
    final response = await _supabaseClient
        .from('invitations')
        .select('id, user_id, status, role, profiles!invitations_user_id_fkey(nama, email, avatar_url)')
        .eq('invited_by', invitedById);
    return response as List<dynamic>;
  }

  // Load proyek
  Future<List<dynamic>> getProjects(String pembuatId) async {
    final response = await _supabaseClient
        .from('projects')
        .select('id, nama_proyek')
        .eq('pembuat_id', pembuatId);
    return response as List<dynamic>;
  }

  // Load tim
  Future<List<dynamic>> getTeams(String manajerId) async {
    final response = await _supabaseClient
        .from('teams')
        .select('id, nama_tim')
        .eq('manajer_id', manajerId);
    return response as List<dynamic>;
  }

  // Buat tim, tetapkan anggota
  Future<void> createTeam({
    required String teamName,
    required String managerId,
    required String memberId,
    required String managerName,
  }) async {
    // Insert tim
    final teamResponse = await _supabaseClient.from('teams').insert({
      'nama_tim': teamName,
      'manajer_id': managerId,
      'deskripsi': 'Tim Kerja',
    }).select('id').single();

    final teamId = teamResponse['id'] as String;

    // Insert tim member
    await _supabaseClient.from('team_members').insert({
      'team_id': teamId,
      'user_id': memberId,
    });
  }

  // Upload avatar ke bucket
  Future<String> uploadAvatar(String userId, Uint8List imageBytes) async {
    // Upload ke bucket 'avatars'
    const bucketName = 'avatars';
    final canonicalFileName = 'avatar_$userId.png';

    try {
      await _supabaseClient.storage.from(bucketName).uploadBinary(
        canonicalFileName,
        imageBytes,
        fileOptions: const FileOptions(
          contentType: 'image/png',
          upsert: true,
        ),
      );
      debugPrint('=== INFO: Avatar uploaded to $bucketName/$canonicalFileName ===');
    } catch (uploadErr) {
      debugPrint('=== ERROR: Avatar upload failed: $uploadErr ===');
      rethrow;
    }

    // Ambil URL publik bersih
    // Tambahkan timestamp cegah cache
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final publicUrl = '${_supabaseClient.storage.from(bucketName).getPublicUrl(canonicalFileName)}?t=$timestamp';
    debugPrint('=== INFO: Avatar public URL: $publicUrl ===');

    // Commit ke avatar_url
    await updateProfileTable(userId: userId, avatarUrl: publicUrl);

    return publicUrl;
  }

  // Update tabel profiles
  Future<void> updateProfileTable({
    required String userId,
    String? avatarUrl,
    String? nama,
    String? bio,
  }) async {
    final updates = <String, dynamic>{};
    if (avatarUrl != null && (avatarUrl.startsWith('http://') || avatarUrl.startsWith('https://'))) {
      updates['avatar_url'] = avatarUrl;
    }
    if (nama != null && nama.trim().length >= 2) {
      updates['nama'] = nama.trim();
    }
    if (bio != null) {
      updates['bio'] = bio.trim().isEmpty ? null : bio.trim();
    }

    if (updates.isEmpty) return;

    try {
      await _supabaseClient
          .from('profiles')
          .update(updates)
          .eq('id', userId);
      debugPrint('=== INFO: public.profiles updated for $userId: $updates ===');
    } catch (e) {
      debugPrint('=== ERROR: profiles table update failed: $e ===');
      rethrow;
    }
  }

  // Update metadata user
  Future<UserResponse> updateUserProfile({
    required String name,
    String? avatarUrl,
    required Map<String, dynamic> currentUserMetadata,
  }) async {
    final data = Map<String, dynamic>.from(currentUserMetadata);
    data['nama'] = name;
    if (avatarUrl != null) {
      data['avatar_url'] = avatarUrl;
    }
    
    final attributes = UserAttributes(data: data);
    final response = await _supabaseClient.auth.updateUser(attributes);
    
    // Refresh sesi auth
    await _supabaseClient.auth.refreshSession();
    
    // Update tabel public.profiles
    final userId = _supabaseClient.auth.currentUser?.id;
    if (userId != null) {
      await updateProfileTable(
        userId: userId, 
        nama: name, 
        avatarUrl: avatarUrl
      );
    }
    
    return response;
  }

  // Undang dengan email
  Future<Map<String, dynamic>?> getProfileByEmail(String email) async {
    final response = await _supabaseClient
        .from('profiles')
        .select()
        .eq('email', email)
        .maybeSingle();
    return response;
  }

  Future<void> inviteMember({
    required String invitedBy,
    required String userId,
    required String role,
    required String status,
  }) async {
    await _supabaseClient.from('invitations').insert({
      'invited_by': invitedBy,
      'user_id': userId,
      'role': role,
      'status': status,
    });

    // Kirim Notifikasi
    await _supabaseClient.from('notifications').insert({
      'user_id': userId,
      'sender_id': invitedBy,
      'tipe_notifikasi': 'undangan',
      'judul': 'Undangan Bergabung',
      'pesan': 'Anda telah diundang untuk bergabung sebagai $role.',
      'is_read': false,
    });
  }

  // Hapus undangan/anggota
  Future<void> deleteInvitation(String invitationId) async {
    await _supabaseClient.from('invitations').delete().eq('id', invitationId);
  }

  // Hapus tim
  Future<void> deleteTeam(String teamId) async {
    await _supabaseClient.from('teams').delete().eq('id', teamId);
  }

  // Update status undangan
  Future<void> updateInvitationStatus(String invitationId, String status) async {
    await _supabaseClient
        .from('invitations')
        .update({'status': status})
        .eq('id', invitationId);
  }

  // Respon undangan
  Future<void> respondToInvitation(String invitedBy, String userId, String newStatus) async {
    await _supabaseClient
        .from('invitations')
        .update({'status': newStatus})
        .eq('invited_by', invitedBy)
        .eq('user_id', userId)
        .eq('status', 'pending');
  }

  Future<void> rejectInvitation(String invitedBy, String userId) async {
    await _supabaseClient
        .from('invitations')
        .delete()
        .eq('invited_by', invitedBy)
        .eq('user_id', userId)
        .eq('status', 'pending');
  }

  // Load sesi Pomodoro
  Future<List<dynamic>> getPomodoroSessions({
    required String userId,
    required DateTime startOfWeek,
    required DateTime endOfWeek,
  }) async {
    final response = await _supabaseClient
        .from('pomodoro_sessions')
        .select('durasi_menit, started_at')
        .eq('user_id', userId)
        .eq('status', 'completed')
        .gte('started_at', startOfWeek.toIso8601String())
        .lt('started_at', endOfWeek.toIso8601String());
    return response as List<dynamic>;
  }

  // Load anggota tim
  Future<List<dynamic>> getTeamMembers(String teamId) async {
    final response = await _supabaseClient
        .from('team_members')
        .select('user_id, profiles!inner(nama)')
        .eq('team_id', teamId);
    return response as List<dynamic>;
  }

  // Load rekan kerja
  Future<List<dynamic>> getActiveColleagues(String invitedBy) async {
    final response = await _supabaseClient
        .from('invitations')
        .select('user_id, profiles!invitations_user_id_fkey(nama)')
        .eq('invited_by', invitedBy)
        .eq('status', 'aktif');
    return response as List<dynamic>;
  }

  // Update nama tim
  Future<void> updateTeamName(String teamId, String teamName) async {
    await _supabaseClient.from('teams').update({'nama_tim': teamName}).eq('id', teamId);
  }

  // Sync anggota tim
  Future<void> syncTeamMembers(String teamId, List<String> memberIds) async {
    await _supabaseClient.from('team_members').delete().eq('team_id', teamId);
    if (memberIds.isNotEmpty) {
      final inserts = memberIds.map((uid) => {
        'team_id': teamId,
        'user_id': uid,
      }).toList();
      await _supabaseClient.from('team_members').insert(inserts);
    }
  }

  // Upsert anggota proyek
  Future<void> upsertProjectMembers({
    required String projectId,
    required List<String> memberIds,
    required String invitedBy,
  }) async {
    for (final uid in memberIds) {
      await _supabaseClient.from('project_members').upsert({
        'project_id': projectId,
        'user_id': uid,
        'invited_by': invitedBy,
        'status_akses': 'aktif',
      }, onConflict: 'project_id, user_id');
    }
  }
}
