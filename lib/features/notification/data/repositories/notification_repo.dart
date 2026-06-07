import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/notification_model.dart';

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return NotificationRepository(Supabase.instance.client);
});

class NotificationRepository {
  final SupabaseClient _supabaseClient;

  NotificationRepository(this._supabaseClient);

  Future<List<NotificationModel>> getNotifications(String userId) async {
    // Dapatkan peran aktif
    final user = _supabaseClient.auth.currentUser;
    String role = 'Tim';
    if (user != null) {
      final metaRole = user.userMetadata?['role'] as String?;
      if (metaRole != null) {
        role = metaRole;
      } else {
        try {
          final profileResponse = await _supabaseClient
              .from('profiles')
              .select('role')
              .eq('id', userId)
              .single();
          final dbRole = profileResponse['role'] as String? ?? 'Tim';
          role = dbRole.split(',').first.trim();
        } catch (_) {}
      }
    }

    // Ambil ID proyek valid
    final Set<String> allowedProjectIds = {};
    if (role == 'Manajer') {
      try {
        final projRes = await _supabaseClient
            .from('projects')
            .select('id')
            .eq('pembuat_id', userId);
        allowedProjectIds.addAll((projRes as List<dynamic>).map((p) => p['id'] as String));
      } catch (_) {}
    } else {
      try {
        final pmRes = await _supabaseClient
            .from('project_members')
            .select('project_id')
            .eq('user_id', userId)
            .eq('status_akses', 'aktif');
        allowedProjectIds.addAll((pmRes as List<dynamic>).map((m) => m['project_id'] as String));
      } catch (_) {}
    }

    // Ambil notifikasi Supabase
    final response = await _supabaseClient
        .from('notifications')
        .select('*, projects(nama_proyek), sender:profiles!sender_id(nama, email, avatar_url), receiver:profiles!user_id(nama, email, avatar_url)')
        .or('user_id.eq.$userId,sender_id.eq.$userId')
        .order('created_at', ascending: false);

    final list = response as List<dynamic>;
    final notificationsList = list.map((e) => NotificationModel.fromJson(e as Map<String, dynamic>)).toList();

    // Filter notifikasi
    return notificationsList.where((notif) {
      if ((notif.tipeNotifikasi.contains('kudos') == true) && notif.senderId == userId) {
        return false; // Sembunyikan notifikasi untuk pengirim
      }
      if (notif.projectId == null || notif.projectId!.isEmpty) {
        return true;
      }
      return allowedProjectIds.contains(notif.projectId);
    }).toList();
  }

  Future<void> markAsRead(String id) async {
    await _supabaseClient
        .from('notifications')
        .update({
          'is_read': true,
          'read_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', id);
  }

  Future<void> deleteNotification(String id) async {
    await _supabaseClient
        .from('notifications')
        .delete()
        .eq('id', id);
  }

  Future<void> updateNotification(String id, Map<String, dynamic> data) async {
    await _supabaseClient
        .from('notifications')
        .update(data)
        .eq('id', id);
  }

  Future<void> sendNotification({
    required String receiverId,
    required String tipeNotifikasi,
    required String judul,
    required String pesan,
    String? senderId,
    String? projectId,
  }) async {
    await _supabaseClient.from('notifications').insert({
      'user_id': receiverId,
      'sender_id': senderId,
      'project_id': projectId,
      'tipe_notifikasi': tipeNotifikasi,
      'judul': judul,
      'pesan': pesan,
      'is_read': false,
    });
  }

  // Cari user dari email
  Future<Map<String, dynamic>?> getUserByEmail(String email) async {
    final response = await _supabaseClient
        .from('profiles')
        .select('id, nama, email, avatar_url')
        .ilike('email', email)
        .maybeSingle();
    return response;
  }
}
