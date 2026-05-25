import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../../../../core/network/supabase_provider.dart';
import '../../data/models/activity_model.dart';
import '../../data/repositories/kudos_repository.dart';

final kudosRepositoryProvider = Provider<KudosRepository>((ref) {
  final supabase = ref.watch(supabaseClientProvider);
  return KudosRepository(supabase);
});

final collabActivitiesProvider = FutureProvider<List<ActivityModel>>((ref) async {
  final repo = ref.watch(kudosRepositoryProvider);
  return repo.getActivities();
});

final projectLeaderboardProvider = FutureProvider.family<List<Map<String, dynamic>>, String>((ref, projectId) async {
  if (projectId.isEmpty) return [];
  final repo = ref.watch(kudosRepositoryProvider);
  return repo.getLeaderboard(projectId);
});

class KudosActionNotifier extends StateNotifier<AsyncValue<void>> {
  final KudosRepository _repository;
  final Ref _ref;

  KudosActionNotifier(this._repository, this._ref) : super(const AsyncValue.data(null));

  Future<void> sendKudos({
    required String projectId,
    String? taskId,
    required String receiverId,
    required String emoji,
    String? commitSha,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _repository.giveKudos(
        projectId: projectId,
        taskId: taskId,
        receiverId: receiverId,
        emoji: emoji,
        commitSha: commitSha,
      );
      state = const AsyncValue.data(null);
      // Invalidate the data providers to force a reload in the UI
      _ref.invalidate(collabActivitiesProvider);
      _ref.invalidate(projectLeaderboardProvider(projectId));
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }
}

final kudosActionNotifierProvider = StateNotifierProvider<KudosActionNotifier, AsyncValue<void>>((ref) {
  final repo = ref.watch(kudosRepositoryProvider);
  return KudosActionNotifier(repo, ref);
});
