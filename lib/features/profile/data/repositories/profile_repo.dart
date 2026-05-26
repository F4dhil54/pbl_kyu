import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileRepository {
  final SupabaseClient _supabaseClient;

  ProfileRepository(this._supabaseClient);

  // Load invitations / members
  Future<List<dynamic>> getInvitations(String invitedById) async {
    final response = await _supabaseClient
        .from('invitations')
        .select('id, user_id, status, role, profiles!invitations_user_id_fkey(nama, email, avatar_url)')
        .eq('invited_by', invitedById);
    return response as List<dynamic>;
  }

  // Load projects
  Future<List<dynamic>> getProjects(String pembuatId) async {
    final response = await _supabaseClient
        .from('projects')
        .select('id, nama_proyek')
        .eq('pembuat_id', pembuatId);
    return response as List<dynamic>;
  }

  // Load teams
  Future<List<dynamic>> getTeams(String manajerId) async {
    final response = await _supabaseClient
        .from('teams')
        .select('id, nama_tim')
        .eq('manajer_id', manajerId);
    return response as List<dynamic>;
  }

  // Create team, assign member
  Future<void> createTeam({
    required String teamName,
    required String managerId,
    required String memberId,
    required String managerName,
  }) async {
    // 1. Insert team
    final teamResponse = await _supabaseClient.from('teams').insert({
      'nama_tim': teamName,
      'manajer_id': managerId,
      'deskripsi': 'Tim Kerja',
    }).select('id').single();

    final teamId = teamResponse['id'] as String;

    // 2. Insert team member
    await _supabaseClient.from('team_members').insert({
      'team_id': teamId,
      'user_id': memberId,
    });
  }

  // Upload avatar to storage bucket (MODULE B: Profile Picture Update Workflow)
  Future<String> uploadAvatar(String userId, Uint8List imageBytes) async {
    // Step 1: Upload ke bucket 'avatars' dengan nama file kanonik
    // Menggunakan upsert: true agar foto lama tertimpa secara seamless
    const bucketName = 'avatars';
    final canonicalFileName = 'avatar_$userId.png';

    try {
      await _supabaseClient.storage.from(bucketName).uploadBinary(
        canonicalFileName,
        imageBytes,
        fileOptions: const FileOptions(
          contentType: 'image/png',
          upsert: true, // overwrite existing avatar without error
        ),
      );
      debugPrint('=== INFO: Avatar uploaded to $bucketName/$canonicalFileName ===');
    } catch (uploadErr) {
      debugPrint('=== ERROR: Avatar upload failed: $uploadErr ===');
      rethrow;
    }

    // Step 2: Resolve public URL — harus berupa string HTTP/HTTPS bersih
    final publicUrl = _supabaseClient.storage.from(bucketName).getPublicUrl(canonicalFileName);
    debugPrint('=== INFO: Avatar public URL: $publicUrl ===');

    // Step 3: Commit ke public.profiles.avatar_url (Pure String Rule: hanya HTTP/HTTPS)
    await updateProfileTable(userId: userId, avatarUrl: publicUrl);

    return publicUrl;
  }

  // Update public.profiles table — dipisah agar bisa dipanggil mandiri
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

  // Update user profile metadata
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
    return await _supabaseClient.auth.updateUser(attributes);
  }

  // Invite member by email
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

    // Send Notification
    await _supabaseClient.from('notifications').insert({
      'user_id': userId,
      'sender_id': invitedBy,
      'tipe_notifikasi': 'undangan',
      'judul': 'Undangan Bergabung',
      'pesan': 'Anda telah diundang untuk bergabung sebagai $role.',
      'is_read': false,
    });
  }

  // Delete invitation/member
  Future<void> deleteInvitation(String invitationId) async {
    await _supabaseClient.from('invitations').delete().eq('id', invitationId);
  }

  // Delete team
  Future<void> deleteTeam(String teamId) async {
    await _supabaseClient.from('teams').delete().eq('id', teamId);
  }

  // Update invitation status (edit member)
  Future<void> updateInvitationStatus(String invitationId, String status) async {
    await _supabaseClient
        .from('invitations')
        .update({'status': status})
        .eq('id', invitationId);
  }

  // Respond to invitation (from notification)
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

  // Load Pomodoro sessions (profile view team stats)
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

  // Load team members (edit team screen)
  Future<List<dynamic>> getTeamMembers(String teamId) async {
    final response = await _supabaseClient
        .from('team_members')
        .select('user_id, profiles!inner(nama)')
        .eq('team_id', teamId);
    return response as List<dynamic>;
  }

  // Load colleagues (edit team screen)
  Future<List<dynamic>> getActiveColleagues(String invitedBy) async {
    final response = await _supabaseClient
        .from('invitations')
        .select('user_id, profiles!invitations_user_id_fkey(nama)')
        .eq('invited_by', invitedBy)
        .eq('status', 'aktif');
    return response as List<dynamic>;
  }

  // Update team name (edit team screen)
  Future<void> updateTeamName(String teamId, String teamName) async {
    await _supabaseClient.from('teams').update({'nama_tim': teamName}).eq('id', teamId);
  }

  // Sync team members (edit team screen)
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

  // Upsert project members (edit team screen)
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
