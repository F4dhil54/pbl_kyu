import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/theme_mode.dart';
import '../../../profile/presentation/views/profile_view_manager.dart';
import '../../../project/presentation/providers/project_provider.dart';
import '../../../../core/network/supabase_provider.dart';
import '../../data/models/activity_model.dart';
import '../providers/kudos_provider.dart';
import '../../../../shared/widgets/app_sidebar.dart';

class CollabView extends ConsumerStatefulWidget {
  final String? role;
  const CollabView({super.key, this.role});

  @override
  ConsumerState<CollabView> createState() => _CollabViewState();
}

class _CollabViewState extends ConsumerState<CollabView> {
  String? _selectedProjectId;
  String _userRole = 'Tim';
  bool _isLoadingRole = true;

  @override
  void initState() {
    super.initState();
    _fetchUserRole();
  }

  Future<void> _fetchUserRole() async {
    if (widget.role != null) {
      if (mounted) {
        setState(() {
          _userRole = widget.role!;
          _isLoadingRole = false;
        });
      }
      return;
    }

    try {
      final supabase = ref.read(supabaseClientProvider);
      final user = supabase.auth.currentUser;
      if (user != null) {
        final userId = user.id;
        final profileResponse = await supabase
            .from('profiles')
            .select('role')
            .eq('id', userId)
            .single();
        final dbRole = profileResponse['role'] as String? ?? 'Tim';
        final metaRole = user.userMetadata?['role'] as String?;
        String role = 'Tim';
        if (metaRole != null && (dbRole == metaRole || dbRole.split(',').map((e) => e.trim()).contains(metaRole))) {
          role = metaRole;
        } else {
          role = dbRole.split(',').first.trim();
        }
        if (mounted) {
          setState(() {
            _userRole = role;
            _isLoadingRole = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _isLoadingRole = false;
          });
        }
      }
    } catch (e) {
      debugPrint("Error fetching user role in CollabView: $e");
      if (mounted) {
        setState(() {
          _isLoadingRole = false;
        });
      }
    }
  }

  String _formatActivityTime(DateTime time) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final activityDate = DateTime(time.year, time.month, time.day);

    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    final timeStr = "$hour:$minute";

    if (activityDate == today) {
      return "hari ini, $timeStr";
    } else if (activityDate == yesterday) {
      return "kemarin, $timeStr";
    } else {
      const months = [
        'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
        'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
      ];
      final monthStr = months[time.month - 1];
      
      return "${time.day} $monthStr ${time.year}, $timeStr";
    }
  }

  void _showReactionSheet(BuildContext context, WidgetRef ref, ActivityModel activity) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) {
        final isDark = ThemeControl.themeNotifier.value == ThemeMode.dark;
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark ? AppDarkColors.surface : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 10,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[700] : Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Beri Kudos untuk ${activity.userName}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppDarkColors.textMain : AppColors.textMain,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildEmojiOption(context, ref, activity, '👍🏻'),
                  _buildEmojiOption(context, ref, activity, '🔥'),
                  _buildEmojiOption(context, ref, activity, '👏🏻'),
                  _buildEmojiOption(context, ref, activity, '🥰'),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmojiOption(BuildContext context, WidgetRef ref, ActivityModel activity, String emoji) {
    final isDark = ThemeControl.themeNotifier.value == ThemeMode.dark;
    final currentUserId = ref.read(supabaseClientProvider).auth.currentUser?.id;
    
    // Cek apakah user sudah mengirim kudos dengan emoji ini
    bool hasVoted = activity.reactions.any((r) => 
        r.reaksiEmoji.runes.first == emoji.runes.first && 
        (r.pengirimId == currentUserId || currentUserId == null));

    // Disable jika dirinya sendiri
    bool isSelf = activity.userId == currentUserId;

    return GestureDetector(
      onTap: hasVoted ? null : () async {
        if (isSelf) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Anda tidak bisa memberi Kudos untuk diri sendiri! 😅'),
              backgroundColor: Colors.orange,
              behavior: SnackBarBehavior.floating,
            ),
          );
          return;
        }

        Navigator.pop(context);
        try {
          await ref.read(kudosActionNotifierProvider.notifier).sendKudos(
            projectId: activity.projectId,
            taskId: activity.taskId,
            taskProgressLogId: activity.type == 'progress' ? activity.id : null,
            receiverId: activity.userId,
            emoji: emoji,
            commitSha: activity.commitSha,
          );
          if (mounted) {
            ScaffoldMessenger.of(this.context).showSnackBar(
              SnackBar(
                content: Text('Kudos $emoji berhasil dikirim!'),
                backgroundColor: AppColors.successText,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(this.context).showSnackBar(
              SnackBar(
                content: Text('Gagal mengirim Kudos: $e'),
                backgroundColor: AppColors.alertText,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: hasVoted 
              ? (isDark ? Colors.blue.withValues(alpha: 0.3) : Colors.blue.withValues(alpha: 0.1))
              : (isDark ? AppDarkColors.background : AppColors.inputBackground),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: hasVoted 
                ? Colors.blue 
                : (isDark ? AppDarkColors.border : AppColors.border), 
            width: hasVoted ? 1.5 : 0.5
          ),
          boxShadow: hasVoted ? [
            BoxShadow(
              color: Colors.blue.withValues(alpha: 0.2),
              blurRadius: 8,
              offset: const Offset(0, 4),
            )
          ] : null,
        ),
        child: Text(emoji, style: TextStyle(fontSize: 32, color: (hasVoted || isSelf) ? Colors.grey : null)),
      ),
    );
  }

  void _showAggregatedKudosSummarySheet(BuildContext context, List<KudosReaction> reactions) {
    int thumbsCount = 0;
    int fireCount = 0;
    int clapCount = 0;
    int loveCount = 0;

    for (var r in reactions) {
      if (r.reaksiEmoji.runes.isEmpty) continue;
      final baseEmoji = r.reaksiEmoji.runes.first;
      if (baseEmoji == '👍'.runes.first) {
        thumbsCount++;
      } else if (baseEmoji == '🔥'.runes.first) {
        fireCount++;
      } else if (baseEmoji == '👏'.runes.first) {
        clapCount++;
      } else if (baseEmoji == '🥰'.runes.first || baseEmoji == '😍'.runes.first) {
        loveCount++;
      }
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) {
        final isDark = ThemeControl.themeNotifier.value == ThemeMode.dark;
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDark ? AppDarkColors.surface : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 10,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[700] : Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Ringkasan Kudos',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppDarkColors.textMain : AppColors.textMain,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildSummaryItem('👍', thumbsCount, isDark),
                  _buildSummaryItem('🔥', fireCount, isDark),
                  _buildSummaryItem('👏', clapCount, isDark),
                  _buildSummaryItem('😍', loveCount, isDark),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSummaryItem(String emoji, int count, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: isDark ? AppDarkColors.background : AppColors.inputBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppDarkColors.border : AppColors.border,
          width: 0.5,
        ),
      ),
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 32)),
          const SizedBox(height: 8),
          Text(
            '$count',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDark ? AppDarkColors.textMain : AppColors.textMain,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingRole) {
      final isDark = ThemeControl.themeNotifier.value == ThemeMode.dark;
      return Scaffold(
        backgroundColor: isDark ? AppDarkColors.background : AppColors.background,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final projectsAsync = ref.watch(projectListProvider);
    final activitiesAsync = ref.watch(collabActivitiesProvider);

    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeControl.themeNotifier,
      builder: (context, currentMode, child) {
        bool isDark = currentMode == ThemeMode.dark;

        return Scaffold(
          drawer: const AppSidebar(),
          backgroundColor: isDark ? AppDarkColors.background : AppColors.background,
          appBar: AppBar(
            backgroundColor: isDark ? AppDarkColors.background : AppColors.background,
            elevation: 0,
            title: Text(
              'KYU',
              style: TextStyle(
                color: isDark ? Colors.white : const Color(0xFF1E3A8A),
                fontWeight: FontWeight.w900,
                fontSize: 20,
                letterSpacing: 1,
              ),
            ),
            actions: [
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ProfileViewManager()),
                  );
                },
                child: CircleAvatar(
                  radius: 16,
                  backgroundColor: isDark ? AppDarkColors.surface : AppColors.inputBackground,
                  child: Image.asset(
                    'image/ic_profile.png',
                    width: 24,
                    errorBuilder: (context, error, stackTrace) => Icon(
                      Icons.person, 
                      color: isDark ? AppDarkColors.textMain : AppColors.textMain, 
                      size: 24
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 20),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(projectListProvider);
              ref.read(collabActivitiesProvider.notifier).loadPage(1, isRefresh: true);
              if (_selectedProjectId != null) {
                ref.invalidate(projectLeaderboardProvider(_selectedProjectId!));
              }
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Leaderboard Section Header with Project Selector Dropdown
                  projectsAsync.when(
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (err, stack) => Text('Error: $err'),
                    data: (projectsList) {
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Papan Peringkat',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isDark ? AppDarkColors.textMain : AppColors.textMain,
                            ),
                          ),
                          if (projectsList.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                              decoration: BoxDecoration(
                                color: isDark ? AppDarkColors.surface : Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isDark ? AppDarkColors.border : AppColors.border,
                                  width: 0.5,
                                ),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String?>(
                                  dropdownColor: isDark ? AppDarkColors.surface : Colors.white,
                                  value: _selectedProjectId,
                                  icon: Icon(Icons.arrow_drop_down, color: isDark ? Colors.white : Colors.black),
                                  items: [
                                    DropdownMenuItem<String?>(
                                      value: null,
                                      child: Container(
                                        constraints: const BoxConstraints(maxWidth: 150),
                                        child: Text(
                                          'Semua Proyek',
                                          style: TextStyle(
                                            color: isDark ? Colors.white : Colors.black,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ),
                                    ...projectsList.map((p) {
                                      return DropdownMenuItem<String?>(
                                        value: p.id,
                                        child: Container(
                                          constraints: const BoxConstraints(maxWidth: 150),
                                          child: Text(
                                            p.name,
                                            style: TextStyle(
                                              color: isDark ? Colors.white : Colors.black,
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      );
                                    }),
                                  ],
                                  onChanged: (val) {
                                    setState(() {
                                      _selectedProjectId = val;
                                    });
                                  },
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  // Dynamic Podium Section
                  if (_selectedProjectId != null)
                    ref.watch(projectLeaderboardProvider(_selectedProjectId!)).when(
                      loading: () => Container(
                        height: 160,
                        alignment: Alignment.center,
                        child: const CircularProgressIndicator(),
                      ),
                      error: (err, stack) => Center(child: Text('Gagal memuat papan peringkat: $err')),
                      data: (leaderboard) {
                        final item1 = leaderboard.isNotEmpty ? leaderboard[0] : null;
                        final item2 = leaderboard.length > 1 ? leaderboard[1] : null;
                        final item3 = leaderboard.length > 2 ? leaderboard[2] : null;

                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            // Rank 2
                            Expanded(
                              child: item2 != null
                                  ? _buildPodiumCard(
                                      rank: 2,
                                      name: item2['nama'],
                                      score: item2['score'].toString(),
                                      isFirst: false,
                                      avatarColor: const Color(0xFFD6E4FF), 
                                      height: 140,
                                      isDark: isDark,
                                    )
                                  : _buildEmptyPodiumCard(2, isDark),
                            ),
                            const SizedBox(width: 12),
                            // Rank 1
                            Expanded(
                              child: item1 != null
                                  ? _buildPodiumCard(
                                      rank: 1,
                                      name: item1['nama'],
                                      score: item1['score'].toString(),
                                      isFirst: true,
                                      avatarColor: const Color(0xFF84C6CE), 
                                      height: 160,
                                      isDark: isDark,
                                    )
                                  : _buildEmptyPodiumCard(1, isDark),
                            ),
                            const SizedBox(width: 12),
                            // Rank 3
                            Expanded(
                              child: item3 != null
                                  ? _buildPodiumCard(
                                      rank: 3,
                                      name: item3['nama'],
                                      score: item3['score'].toString(),
                                      isFirst: false,
                                      avatarColor: const Color(0xFFFFCCB3), 
                                      height: 130,
                                      isDark: isDark,
                                    )
                                  : _buildEmptyPodiumCard(3, isDark),
                            ),
                          ],
                        );
                      },
                    )
                  else
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 40.0),
                      child: Center(
                        child: Text(
                          'Pilih proyek terlebih dahulu untuk melihat papan peringkat.',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? AppDarkColors.textSecondary : AppColors.textSecondary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  const SizedBox(height: 32),

                  // Recent Activities Header
                  Text(
                    'Aktivitas Terbaru',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? AppDarkColors.textMain : AppColors.textMain,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Dynamic Activities Feed
                  Builder(
                    builder: (context) {
                      if (activitiesAsync.isLoading && activitiesAsync.activities.isEmpty) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (activitiesAsync.error != null && activitiesAsync.activities.isEmpty) {
                        return Center(child: Text('Gagal memuat aktivitas: ${activitiesAsync.error}'));
                      }

                      final activitiesList = activitiesAsync.activities
                          .where((a) => _selectedProjectId == null || a.projectId == _selectedProjectId)
                          .toList();

                      if (activitiesList.isEmpty) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 40.0),
                          child: Center(
                            child: Text(
                              'Belum ada aktivitas terbaru terkait proyek Anda.',
                              style: TextStyle(
                                fontSize: 13,
                                color: isDark ? AppDarkColors.textSecondary : AppColors.textSecondary,
                              ),
                            ),
                          ),
                        );
                      }

                      return Column(
                        children: [
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: activitiesList.length,
                            separatorBuilder: (context, index) => const SizedBox(height: 16),
                            itemBuilder: (context, index) {
                              final act = activitiesList[index];
                              final String formattedTime = _formatActivityTime(act.time);

                              return _buildActivityCard(
                                name: act.userName,
                                avatarUrl: act.userAvatar,
                                actionText: act.type == 'commit' || act.type == 'github'
                                    ? 'melakukan commit'
                                    : act.actionText,
                                linkText: act.linkText,
                                projectText: act.projectName,
                                time: formattedTime,
                                kudosIcon: '👏🏻',
                                kudosText: 'Beri Kudos',
                                onKudosPressed: () => _showReactionSheet(context, ref, act),
                                reactions: act.reactions,
                                type: act.type,
                                isDark: isDark,
                              );
                            },
                          ),
                          if (activitiesList.isNotEmpty && (activitiesAsync.currentPage > 1 || activitiesAsync.hasMore)) ...[
                            const SizedBox(height: 24),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                ElevatedButton(
                                  onPressed: activitiesAsync.currentPage > 1 && !activitiesAsync.isLoading
                                      ? () => ref.read(collabActivitiesProvider.notifier).loadPage(activitiesAsync.currentPage - 1)
                                      : null,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: isDark ? AppDarkColors.surface : Colors.white,
                                    foregroundColor: isDark ? Colors.white : Colors.black,
                                    side: BorderSide(color: isDark ? AppDarkColors.border : AppColors.border),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  ),
                                  child: const Text('Sebelumnya'),
                                ),
                                Text(
                                  'Halaman ${activitiesAsync.currentPage}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? AppDarkColors.textMain : AppColors.textMain,
                                  ),
                                ),
                                ElevatedButton(
                                  onPressed: activitiesAsync.hasMore && !activitiesAsync.isLoading
                                      ? () => ref.read(collabActivitiesProvider.notifier).loadPage(activitiesAsync.currentPage + 1)
                                      : null,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: isDark ? AppDarkColors.surface : Colors.white,
                                    foregroundColor: isDark ? Colors.white : Colors.black,
                                    side: BorderSide(color: isDark ? AppDarkColors.border : AppColors.border),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  ),
                                  child: const Text('Selanjutnya'),
                                ),
                              ],
                            ),
                          ]
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
          // FAB removed
        );
      },
    );
  }

  Widget _buildEmptyPodiumCard(int rank, bool isDark) {
    return Container(
      height: rank == 1 ? 160 : (rank == 2 ? 140 : 130),
      decoration: BoxDecoration(
        color: isDark ? AppDarkColors.surface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? AppDarkColors.border : AppColors.border, width: 0.5),
      ),
      child: Center(
        child: Text(
          'Rank $rank\n-',
          style: TextStyle(
            color: isDark ? AppDarkColors.textSecondary : AppColors.textSecondary,
            fontSize: 12,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildPodiumCard({
    required int rank,
    required String name,
    required String score,
    required bool isFirst,
    required Color avatarColor,
    required double height,
    required bool isDark,
  }) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: isFirst 
            ? AppColors.rank1Background 
            : (isDark ? AppDarkColors.surface : Colors.white),
        borderRadius: BorderRadius.circular(16),
        border: isFirst ? null : Border.all(color: isDark ? AppDarkColors.border : AppColors.border, width: 0.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isFirst ? Colors.white.withValues(alpha: 0.1) : (isDark ? AppDarkColors.background : AppColors.inputBackground),
                  border: Border.all(color: avatarColor, width: 2),
                ),
                child: Center(
                  child: Image.asset(
                    'image/ic_avatar_${name.toLowerCase()}.png',
                    width: 40,
                    errorBuilder: (context, error, stackTrace) => Icon(
                      Icons.person,
                      color: isFirst ? Colors.white : (isDark ? AppDarkColors.textSecondary : AppColors.textSecondary),
                      size: 32,
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: -6,
                right: -6,
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: isFirst ? Colors.white : (isDark ? Colors.white : AppColors.textMain),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '$rank',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: isFirst ? AppColors.rank1Background : (isDark ? AppDarkColors.surface : Colors.white),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            name,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: isFirst ? Colors.white : (isDark ? AppDarkColors.textMain : AppColors.textMain),
            ),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.stars, 
                color: isFirst ? Colors.yellow : Colors.orange, 
                size: 14
              ),
              const SizedBox(width: 4),
              Text(
                '$score pt',
                style: TextStyle(
                  fontSize: 12,
                  color: isFirst ? Colors.white70 : (isDark ? AppDarkColors.textSecondary : AppColors.textSecondary),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActivityCard({
    required String name,
    required String? avatarUrl,
    required String actionText,
    required String linkText,
    required String projectText,
    required String time,
    required String kudosIcon,
    required String kudosText,
    required VoidCallback onKudosPressed,
    required List<KudosReaction> reactions,
    required String type,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppDarkColors.surface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? AppDarkColors.border : AppColors.border, width: 0.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.1 : 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: isDark ? AppDarkColors.background : AppColors.inputBackground,
            child: type == 'commit' || type == 'github'
                ? Icon(
                    Icons.commit,
                    color: isDark ? Colors.amberAccent : AppColors.primary,
                    size: 24,
                  )
                : CircleAvatar(
                    radius: 20,
                    backgroundColor: isDark ? AppDarkColors.surface : const Color(0xFFE2E8F0),
                    child: Text(
                      name.isNotEmpty ? name[0].toUpperCase() : 'U',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDark ? AppDarkColors.textMain : AppColors.textMain,
                      ),
                    ),
                  ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: RichText(
                        text: TextSpan(
                          style: TextStyle(
                            fontSize: 14, 
                            color: isDark ? AppDarkColors.textMain : AppColors.textMain, 
                            height: 1.4,
                            fontFamily: 'Inter',
                          ),
                          children: [
                            TextSpan(text: name, style: const TextStyle(fontWeight: FontWeight.bold)),
                            TextSpan(text: ' $actionText '),
                            if (type == 'progress') ...[
                              const TextSpan(text: 'tugas '),
                              TextSpan(
                                  text: linkText,
                                  style: TextStyle(
                                    color: isDark ? Colors.amberAccent : AppColors.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                              ),
                            ] else ...[
                              TextSpan(
                                  text: linkText,
                                  style: TextStyle(
                                    color: isDark ? Colors.amberAccent : AppColors.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                              ),
                            ],
                            TextSpan(
                              text: ' dari proyek $projectText',
                              style: TextStyle(
                                color: isDark ? Colors.grey[400] : Colors.grey[600],
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      time,
                      style: TextStyle(
                        fontSize: 11, 
                        color: isDark ? AppDarkColors.textSecondary : AppColors.textSecondary
                      ),
                    ),
                  ],
                ),
                // Reaction chips removed from card
                const SizedBox(height: 16),
                Row(
                  children: [
                    GestureDetector(
                      onTap: onKudosPressed,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: isDark ? AppDarkColors.background : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: isDark ? AppDarkColors.border : AppColors.border),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(kudosIcon, style: const TextStyle(fontSize: 14)),
                            const SizedBox(width: 8),
                            Text(
                              kudosText,
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? AppDarkColors.textMain : AppColors.textMain,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (reactions.isNotEmpty) ...[
                      const Spacer(),
                      GestureDetector(
                        onTap: () => _showAggregatedKudosSummarySheet(context, reactions),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: isDark ? AppDarkColors.background : AppColors.inputBackground,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isDark ? AppDarkColors.border : AppColors.border,
                              width: 0.5,
                            ),
                          ),
                          child: Builder(
                            builder: (context) {
                              final Map<String, int> reactionCounts = {};
                              for (var r in reactions) {
                                final emoji = r.reaksiEmoji;
                                reactionCounts[emoji] = (reactionCounts[emoji] ?? 0) + 1;
                              }
                              final displayEmojis = reactionCounts.keys.take(3).join(' ');
                              final totalReactions = reactions.length;
                              return Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(displayEmojis, style: const TextStyle(fontSize: 12)),
                                  const SizedBox(width: 6),
                                  Text(
                                    '$totalReactions',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: isDark ? AppDarkColors.textMain : AppColors.textMain,
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
