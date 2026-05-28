import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/supabase_provider.dart';
import '../../data/repositories/profile_repo.dart';

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  final supabase = ref.watch(supabaseClientProvider);
  return ProfileRepository(supabase);
});

final managerInvitationsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final supabase = ref.watch(supabaseClientProvider);
  final user = supabase.auth.currentUser;
  if (user == null) return [];
  
  final profileRepo = ref.watch(profileRepositoryProvider);
  try {
    final response = await profileRepo.getInvitations(user.id);
    return response.map((item) {
      final profile = item['profiles'] as Map<String, dynamic>? ?? {};
      final name = profile['nama'] ?? 'Anggota';
      final email = profile['email'] ?? 'Tidak ada email';
      final role = item['role'] ?? 'Anggota';
      final status = item['status'] as String;
      return {
        'id': item['user_id'] as String,
        'invitation_id': item['id'] as String,
        'name': name,
        'email': email,
        'role': role,
        'status': status,
      };
    }).toList();
  } catch (e) {
    return [];
  }
});
