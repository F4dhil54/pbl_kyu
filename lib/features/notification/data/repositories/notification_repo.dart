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
    final response = await _supabaseClient
        .from('notifications')
        .select('*, projects(nama_proyek), sender:profiles!notifications_sender_id_fkey(nama, email, avatar_url)')
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    final list = response as List<dynamic>;
    return list.map((e) => NotificationModel.fromJson(e as Map<String, dynamic>)).toList();
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

  // Find user by email for messaging
  Future<Map<String, dynamic>?> getUserByEmail(String email) async {
    final response = await _supabaseClient
        .from('profiles')
        .select('id, nama, email, avatar_url')
        .ilike('email', email) // Case insensitive
        .maybeSingle();
    return response;
  }
}
