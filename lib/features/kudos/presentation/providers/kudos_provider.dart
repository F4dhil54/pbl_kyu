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
  final List<ActivityModel> activities;
  final String? error;
  final int currentPage;
  final bool hasMore;

  ActivitiesState({
    this.isLoading = true,
    this.activities = const [],
    this.error,
    this.currentPage = 1,
    this.hasMore = true,
  });

  ActivitiesState copyWith({
    bool? isLoading,
    List<ActivityModel>? activities,
    String? error,
    int? currentPage,
    bool? hasMore,
  }) {
    return ActivitiesState(
      isLoading: isLoading ?? this.isLoading,
      activities: activities ?? this.activities,
      error: error ?? this.error,
      currentPage: currentPage ?? this.currentPage,
      hasMore: hasMore ?? this.hasMore,
    );
  }
}

class ActivitiesNotifier extends StateNotifier<ActivitiesState> {
  final KudosRepository _repo;
  final SupabaseClient _supabase;
  RealtimeChannel? _taskChannel;
  RealtimeChannel? _kudosChannel;
  RealtimeChannel? _commitChannel;
  final int _limit = 5;

  ActivitiesNotifier(this._repo, this._supabase) : super(ActivitiesState()) {
    _initRealtime();
    loadPage(1);
  }

  Future<void> loadPage(int page, {bool isRefresh = false}) async {
    if (!isRefresh && state.isLoading && state.activities.isNotEmpty) return;
    
    state = state.copyWith(
      isLoading: true, 
      currentPage: page,
      activities: isRefresh ? state.activities : [], // Kosongkan list untuk spinner
    );
    try {
      final offset = (page - 1) * _limit;
      final newActs = await _repo.getActivities(limit: _limit, offset: offset);
      state = state.copyWith(
        isLoading: false,
        activities: newActs,
        hasMore: newActs.length >= _limit,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void _initRealtime() {
    _taskChannel = _supabase.channel('public:task_progress_logs')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'task_progress_logs',
          callback: (payload) {
            loadPage(state.currentPage, isRefresh: true);
          },
        )
        .subscribe();

    _kudosChannel = _supabase.channel('public:kudos')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'kudos',
          callback: (payload) {
            loadPage(state.currentPage, isRefresh: true);
          },
        )
        .subscribe();

    _commitChannel = _supabase.channel('public:github_commits')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'github_commits',
          callback: (payload) {
            loadPage(state.currentPage, isRefresh: true);
          },
        )
        .subscribe();
  }

  void addOptimisticKudos({
    String? taskId,
    String? taskProgressLogId,
    String? commitSha,
    String? githubCommitId,
    required String emoji,
    required String userId,
  }) {
    final newActs = state.activities.map((a) {
      bool isMatch = false;
      if (a.type == 'progress' && taskProgressLogId != null && a.id == taskProgressLogId) {
        isMatch = true;
      } else if ((a.type == 'commit' || a.type == 'github') && (githubCommitId != null && a.id == githubCommitId || commitSha != null && a.commitSha == commitSha)) {
        isMatch = true;
      } else if (a.type == 'task' && taskId != null && a.taskId == taskId) {
        isMatch = true;
      }

      if (isMatch) {
        final updatedReactions = List<KudosReaction>.from(a.reactions);
        // Cek tarik/tukar emoji
        final existingIdx = updatedReactions.indexWhere((r) => r.pengirimId == userId);
        if (existingIdx != -1) {
          if (updatedReactions[existingIdx].reaksiEmoji.runes.first == emoji.runes.first) {
            updatedReactions.removeAt(existingIdx); // Tarik
          } else {
            updatedReactions[existingIdx] = KudosReaction(
              id: 'temp',
              pengirimId: userId,
              pengirimNama: 'Anda',
              reaksiEmoji: emoji,
            ); // Tukar
          }
        } else {
          updatedReactions.add(KudosReaction(
            id: 'temp',
            pengirimId: userId,
            pengirimNama: 'Anda',
            reaksiEmoji: emoji,
          )); // Tambah baru
        }

        return ActivityModel(
          id: a.id,
          userName: a.userName,
          userAvatar: a.userAvatar,
          actionText: a.actionText,
          linkText: a.linkText,
          time: a.time,
          type: a.type,
          taskId: a.taskId,
          projectId: a.projectId,
          projectName: a.projectName,
          userId: a.userId,
          commitSha: a.commitSha,
          reactions: updatedReactions,
        );
      }
      return a;
    }).toList();

    state = state.copyWith(activities: newActs);
  }

  @override
  void dispose() {
    _taskChannel?.unsubscribe();
    _kudosChannel?.unsubscribe();
    _commitChannel?.unsubscribe();
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

  Future<String> sendKudos({
    required String projectId,
    String? taskId,
    String? taskProgressLogId,
    required String receiverId,
    required String emoji,
    String? commitSha,
    String? githubCommitId,
  }) async {
    state = const AsyncValue.loading();
    try {
      final currentUserId = _ref.read(supabaseClientProvider).auth.currentUser?.id;
      if (currentUserId != null) {
        _ref.read(collabActivitiesProvider.notifier).addOptimisticKudos(
          taskId: taskId,
          taskProgressLogId: taskProgressLogId,
          commitSha: commitSha,
          githubCommitId: githubCommitId,
          emoji: emoji,
          userId: currentUserId,
        );
      }

      final action = await _repository.giveKudos(
        projectId: projectId,
        taskId: taskId,
        taskProgressLogId: taskProgressLogId,
        receiverId: receiverId,
        emoji: emoji,
        commitSha: commitSha,
        githubCommitId: githubCommitId,
      );
      state = const AsyncValue.data(null);
      // Refresh leaderboard
      _ref.invalidate(projectLeaderboardProvider(projectId));
      // Refresh aktivitas
      await Future.delayed(const Duration(milliseconds: 800));
      _ref.read(collabActivitiesProvider.notifier).loadPage(_ref.read(collabActivitiesProvider).currentPage, isRefresh: true);
      return action;
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
