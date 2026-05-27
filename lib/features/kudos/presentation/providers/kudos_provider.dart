import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/network/supabase_provider.dart';
import '../../data/models/activity_model.dart';
import '../../data/repositories/kudos_repository.dart';

final kudosRepositoryProvider = Provider<KudosRepository>((ref) {
  final supabase = ref.watch(supabaseClientProvider);
  return KudosRepository(supabase);
});

class ActivitiesState {
  final bool isLoading;
  final bool isLoadMore;
  final List<ActivityModel> activities;
  final String? error;
  final int offset;
  final bool hasMore;

  ActivitiesState({
    this.isLoading = true,
    this.isLoadMore = false,
    this.activities = const [],
    this.error,
    this.offset = 0,
    this.hasMore = true,
  });

  ActivitiesState copyWith({
    bool? isLoading,
    bool? isLoadMore,
    List<ActivityModel>? activities,
    String? error,
    int? offset,
    bool? hasMore,
  }) {
    return ActivitiesState(
      isLoading: isLoading ?? this.isLoading,
      isLoadMore: isLoadMore ?? this.isLoadMore,
      activities: activities ?? this.activities,
      error: error ?? this.error,
      offset: offset ?? this.offset,
      hasMore: hasMore ?? this.hasMore,
    );
  }
}

class ActivitiesNotifier extends StateNotifier<ActivitiesState> {
  final KudosRepository _repo;
  final SupabaseClient _supabase;
  RealtimeChannel? _taskChannel;
  RealtimeChannel? _kudosChannel;
  final int _limit = 10;

  ActivitiesNotifier(this._repo, this._supabase) : super(ActivitiesState()) {
    _initRealtime();
    loadActivities(isInitial: true);
  }

  Future<void> loadActivities({bool isRefresh = false, bool isInitial = false}) async {
    if (isRefresh) {
      state = state.copyWith(isLoading: true, offset: 0, hasMore: true, activities: []);
    } else if (isInitial) {
      state = state.copyWith(isLoading: true, offset: 0, hasMore: true);
    } else if (state.isLoading || state.isLoadMore || !state.hasMore) {
      return;
    } else {
      state = state.copyWith(isLoadMore: true);
    }

    try {
      final newActs = await _repo.getActivities(limit: _limit, offset: state.offset);
      state = state.copyWith(
        isLoading: false,
        isLoadMore: false,
        activities: isRefresh ? newActs : [...state.activities, ...newActs],
        offset: state.offset + newActs.length,
        hasMore: newActs.length >= _limit,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, isLoadMore: false, error: e.toString());
    }
  }

  void _initRealtime() {
    _taskChannel = _supabase.channel('public:task_progress_logs')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'task_progress_logs',
          callback: (payload) {
            // Silently refresh to keep top items updated
            loadActivities(isRefresh: true);
          },
        )
        .subscribe();

    _kudosChannel = _supabase.channel('public:kudos')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'kudos',
          callback: (payload) {
            loadActivities(isRefresh: true);
          },
        )
        .subscribe();
  }

  @override
  void dispose() {
    _taskChannel?.unsubscribe();
    _kudosChannel?.unsubscribe();
    super.dispose();
  }
}

final collabActivitiesProvider = StateNotifierProvider<ActivitiesNotifier, ActivitiesState>((ref) {
  final repo = ref.watch(kudosRepositoryProvider);
  final supabase = ref.watch(supabaseClientProvider);
  return ActivitiesNotifier(repo, supabase);
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
      // Invalidate leaderboard to refresh points
      _ref.invalidate(projectLeaderboardProvider(projectId));
      // No need to invalidate collabActivitiesProvider manually, realtime will catch it, but we can do it if no realtime
      _ref.read(collabActivitiesProvider.notifier).loadActivities(isRefresh: true);
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
