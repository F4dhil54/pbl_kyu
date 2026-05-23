import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/supabase_provider.dart';
import '../../data/repositories/profile_repo.dart';

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  final supabase = ref.watch(supabaseClientProvider);
  return ProfileRepository(supabase);
});
