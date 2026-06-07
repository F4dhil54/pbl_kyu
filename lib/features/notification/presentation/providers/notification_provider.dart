import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/services/notification_service.dart';
import '../../data/models/notification_model.dart';
import '../../data/repositories/notification_repo.dart';
import '../../../kudos/presentation/providers/kudos_provider.dart';

enum NotificationFilter { semua, belumDibaca, mention, tugas }

class NotificationNotifier extends StateNotifier<AsyncValue<List<NotificationModel>>> {
  final NotificationRepository _repository;
  final String _userId;
  final Ref _ref;
  RealtimeChannel? _subscription;

  NotificationNotifier(this._repository, this._userId, this._ref) : super(const AsyncValue.loading()) {
    loadNotifications();
    if (_userId.isNotEmpty) {
      _setupRealtime();
    }
  }

  void _setupRealtime() {
    _subscription = Supabase.instance.client
        .channel('public:notifications:user_$_userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'notifications',
          callback: (payload) {
            final newRecord = payload.newRecord;
            
            // Cek notifikasi diri sendiri
            if (newRecord['user_id'] == _userId || newRecord['sender_id'] == _userId) {
              loadNotifications();
              
              // Trigger suara/popup untuk penerima
              if (newRecord['user_id'] == _userId && newRecord['sender_id'] != _userId) {
                LocalNotificationService.showNotification(
                  id: (newRecord['id'] ?? '').hashCode,
                  title: newRecord['judul'] ?? 'Notifikasi Baru',
                  body: newRecord['pesan'] ?? 'Anda memiliki pesan baru',
                );

                // Auto-refresh bubble kudos
                final tipe = newRecord['tipe_notifikasi'] as String?;
                if (tipe != null && tipe.contains('kudos')) {
                  try {
                    // Refresh aktivitas untuk bubble
                    _ref.read(collabActivitiesProvider.notifier).loadPage(_ref.read(collabActivitiesProvider).currentPage, isRefresh: true);
                  } catch (_) {}
                }
              }
            }
          },
        )
        .subscribe();
  }

  @override
  void dispose() {
    _subscription?.unsubscribe();
    super.dispose();
  }

  Future<void> loadNotifications() async {
    state = const AsyncValue.loading();
    try {
      final notifications = await _repository.getNotifications(_userId);
      state = AsyncValue.data(notifications);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> markAsRead(String id) async {
    try {
      await _repository.markAsRead(id);
      // Update lokal
      if (state.hasValue) {
        final currentList = state.value!;
        final updatedList = currentList.map((n) {
          if (n.id == id) {
             return NotificationModel(
              id: n.id,
              userId: n.userId,
              senderId: n.senderId,
              projectId: n.projectId,
              projectName: n.projectName,
              tipeNotifikasi: n.tipeNotifikasi,
              judul: n.judul,
              pesan: n.pesan,
              isRead: true,
              createdAt: n.createdAt,
              senderName: n.senderName,
              senderEmail: n.senderEmail,
              senderAvatar: n.senderAvatar,
            );
          }
          return n;
        }).toList();
        state = AsyncValue.data(updatedList);
      }
    } catch (e) {
      // Abaikan/log error
    }
  }

  Future<void> deleteNotification(String id) async {
    try {
      await _repository.deleteNotification(id);
      if (state.hasValue) {
        final currentList = state.value!;
        final updatedList = currentList.where((n) => n.id != id).toList();
        state = AsyncValue.data(updatedList);
      }
    } catch (e) {
      // Abaikan/log error
    }
  }

  Future<void> updateNotificationStatus(String id, String pesan) async {
    try {
      await _repository.updateNotification(id, {
        'pesan': pesan,
        'is_read': true,
        'read_at': DateTime.now().toUtc().toIso8601String(),
      });
      if (state.hasValue) {
        final currentList = state.value!;
        final updatedList = currentList.map((n) {
          if (n.id == id) {
            return NotificationModel(
              id: n.id,
              userId: n.userId,
              senderId: n.senderId,
              projectId: n.projectId,
              projectName: n.projectName,
              tipeNotifikasi: n.tipeNotifikasi,
              judul: n.judul,
              pesan: pesan,
              isRead: true,
              createdAt: n.createdAt,
              senderName: n.senderName,
              senderEmail: n.senderEmail,
              senderAvatar: n.senderAvatar,
            );
          }
          return n;
        }).toList();
        state = AsyncValue.data(updatedList);
      }
    } catch (e) {
      debugPrint('Error updating notification status: $e');
      rethrow;
    }
  }

  Future<void> sendMessage(String receiverEmail, String judul, String pesan) async {
    try {
      final receiver = await _repository.getUserByEmail(receiverEmail);
      if (receiver == null) {
        throw Exception('Pengguna dengan email tersebut tidak ditemukan.');
      }
      
      await _repository.sendNotification(
        receiverId: receiver['id'] as String,
        tipeNotifikasi: 'pesan',
        judul: judul,
        pesan: pesan,
        senderId: _userId,
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<void> replyMessage(String receiverId, String judul, String pesan) async {
    try {
      await _repository.sendNotification(
        receiverId: receiverId,
        tipeNotifikasi: 'pesan',
        judul: judul.startsWith('Re:') ? judul : 'Re: $judul',
        pesan: pesan,
        senderId: _userId,
      );
    } catch (e) {
      rethrow;
    }
  }
}

final notificationFilterProvider = StateProvider<NotificationFilter>((ref) => NotificationFilter.semua);
final notificationSearchProvider = StateProvider<String>((ref) => '');

final notificationNotifierProvider = StateNotifierProvider<NotificationNotifier, AsyncValue<List<NotificationModel>>>((ref) {
  final repo = ref.watch(notificationRepositoryProvider);
  final userId = Supabase.instance.client.auth.currentUser?.id ?? '';
  return NotificationNotifier(repo, userId, ref);
});

final filteredNotificationsProvider = Provider<AsyncValue<List<NotificationModel>>>((ref) {
  final asyncNotifications = ref.watch(notificationNotifierProvider);
  final filter = ref.watch(notificationFilterProvider);
  final search = ref.watch(notificationSearchProvider).toLowerCase();

  return asyncNotifications.whenData((notifications) {
    var filtered = notifications;

    // Pencarian
    if (search.isNotEmpty) {
      filtered = filtered.where((n) {
        final titleMatch = n.judul.toLowerCase().contains(search);
        final messageMatch = n.pesan.toLowerCase().contains(search);
        final senderMatch = (n.senderName ?? '').toLowerCase().contains(search);
        return titleMatch || messageMatch || senderMatch;
      }).toList();
    }

    // Filter
    switch (filter) {
      case NotificationFilter.belumDibaca:
        final currentUserId = Supabase.instance.client.auth.currentUser?.id;
        filtered = filtered.where((n) {
          final isSentByMe = n.senderId == currentUserId && n.userId != currentUserId;
          return !n.isRead && !isSentByMe;
        }).toList();
        break;
      case NotificationFilter.mention:
        filtered = filtered.where((n) => n.tipeNotifikasi == 'mention' || n.tipeNotifikasi == 'pesan').toList();
        break;
      case NotificationFilter.tugas:
        filtered = filtered.where((n) => n.tipeNotifikasi == 'tugas' || n.tipeNotifikasi == 'proyek').toList();
        break;
      case NotificationFilter.semua:
        break;
    }

    return filtered;
  });
});
