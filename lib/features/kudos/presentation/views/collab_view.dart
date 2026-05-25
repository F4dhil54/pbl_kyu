import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/theme_mode.dart';
import '../../../profile/presentation/views/profile_view_manager.dart';
import '../../../project/presentation/providers/project_provider.dart';
import '../../data/models/activity_model.dart';
import '../providers/kudos_provider.dart';
import 'create_post_screen.dart';
import '../../../../shared/widgets/app_sidebar.dart';

class CollabView extends ConsumerStatefulWidget {
  const CollabView({super.key});

  @override
  ConsumerState<CollabView> createState() => _CollabViewState();
}

class _CollabViewState extends ConsumerState<CollabView> {
  String? _selectedProjectId;

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
      
      // "jika kemarin lusa hingga terhitung 1 minggu setelah hari ini penulisannya "tanggal, jam". 
      // jika lebih 1 minggu penulisannya "tanggal, jam"."
      // Keduanya menggunakan format tanggal lengkap.
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
                color: Colors.black.withOpacity(0.15),
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
                  _buildEmojiOption(context, ref, activity, '👍🏻', '15 Poin'),
                  _buildEmojiOption(context, ref, activity, '🔥', '15 Poin'),
                  _buildEmojiOption(context, ref, activity, '👏🏻', '15 Poin'),
                  _buildEmojiOption(context, ref, activity, '🥰', '10 Poin'),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmojiOption(BuildContext context, WidgetRef ref, ActivityModel activity, String emoji, String points) {
    final isDark = ThemeControl.themeNotifier.value == ThemeMode.dark;
    return GestureDetector(
      onTap: () async {
        Navigator.pop(context);
        try {
          await ref.read(kudosActionNotifierProvider.notifier).sendKudos(
            projectId: activity.projectId,
            taskId: activity.taskId,
            receiverId: activity.userId,
            emoji: emoji,
            commitSha: activity.commitSha,
          );
          // Force refresh providers from widget side to ensure UI updates
          ref.invalidate(collabActivitiesProvider);
          if (_selectedProjectId != null) {
            ref.invalidate(projectLeaderboardProvider(_selectedProjectId!));
          }
          if (mounted) {
            ScaffoldMessenger.of(this.context).showSnackBar(
              SnackBar(
                content: Text('Kudos $emoji berhasil dikirim! ($points)'),
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
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isDark ? AppDarkColors.background : AppColors.inputBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isDark ? AppDarkColors.border : AppColors.border, width: 0.5),
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 32)),
            const SizedBox(height: 8),
            Text(
              points,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isDark ? AppDarkColors.textMain : AppColors.textMain,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
              Image.asset(
                'image/ic_search.png',
                width: 24,
                errorBuilder: (context, error, stackTrace) => Icon(
                  Icons.search, 
                  color: isDark ? AppDarkColors.textSecondary : AppColors.textSecondary
                ),
              ),
              const SizedBox(width: 16),
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
              ref.invalidate(collabActivitiesProvider);
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
                      if (_selectedProjectId == null && projectsList.isNotEmpty) {
                        // Set selected project to first active project
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          setState(() {
                            _selectedProjectId = projectsList.first.id;
                          });
                        });
                      }

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
                                child: DropdownButton<String>(
                                  dropdownColor: isDark ? AppDarkColors.surface : Colors.white,
                                  value: _selectedProjectId ?? (projectsList.isNotEmpty ? projectsList.first.id : null),
                                  icon: Icon(Icons.arrow_drop_down, color: isDark ? Colors.white : Colors.black),
                                  items: projectsList.map((p) {
                                    return DropdownMenuItem<String>(
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
                                  }).toList(),
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Aktivitas Terbaru',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark ? AppDarkColors.textMain : AppColors.textMain,
                        ),
                      ),
                      Row(
                        children: [
                          Text(
                            'Segarkan',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? Colors.amberAccent : AppColors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.refresh, 
                            size: 14, 
                            color: isDark ? Colors.amberAccent : AppColors.primary
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Dynamic Activities Feed
                  activitiesAsync.when(
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (err, stack) => Center(child: Text('Gagal memuat aktivitas: $err')),
                    data: (activitiesList) {
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

                      return ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: activitiesList.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 16),
                        itemBuilder: (context, index) {
                          final act = activitiesList[index];
                          
                          // Struktur teks kustom untuk progres tugas vs commit GitHub
                          final String formattedTime = _formatActivityTime(act.time);
                          final String actionDesc;
                          final String titleText;
                          final String detailText;

                          if (act.type == 'commit') {
                            actionDesc = 'melakukan commit';
                            titleText = act.linkText;
                            detailText = 'dari proyek ${act.projectName}';
                          } else {
                            actionDesc = act.actionText; // 'sedang mengerjakan' atau 'sudah menyelesaikan'
                            titleText = 'tugas ${act.linkText}';
                            detailText = 'dari proyek ${act.projectName}';
                          }

                          return _buildActivityCard(
                            name: act.userName,
                            avatarUrl: act.userAvatar,
                            actionText: actionDesc,
                            linkText: titleText,
                            projectText: detailText,
                            time: formattedTime,
                            kudosIcon: '👏🏻',
                            kudosText: 'Beri Kudos',
                            isDark: isDark,
                            onKudosPressed: () => _showReactionSheet(context, ref, act),
                            reactions: act.reactions,
                            type: act.type,
                          );
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const CreatePostScreen()),
              );
            },
            backgroundColor: isDark ? Colors.white : AppColors.textMain,
            elevation: 4,
            shape: const CircleBorder(),
            child: Icon(Icons.edit, color: isDark ? AppDarkColors.background : Colors.white, size: 24),
          ),
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
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
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
                  color: isFirst ? Colors.white.withOpacity(0.1) : (isDark ? AppDarkColors.background : AppColors.inputBackground),
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
                Icons.emoji_events,
                size: 12,
                color: isFirst ? avatarColor : (isDark ? AppDarkColors.textSecondary : AppColors.textSecondary),
              ),
              const SizedBox(width: 4),
              Text(
                score,
                style: TextStyle(
                  fontSize: 12,
                  color: isFirst ? avatarColor : (isDark ? AppDarkColors.textSecondary : AppColors.textSecondary),
                  fontWeight: isFirst ? FontWeight.bold : FontWeight.normal,
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
            color: Colors.black.withOpacity(isDark ? 0.1 : 0.02),
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
            child: avatarUrl != null && avatarUrl.startsWith('image/')
                ? Image.asset(avatarUrl)
                : Image.asset(
                    'image/ic_avatar_${name.toLowerCase()}.png',
                    errorBuilder: (context, error, stackTrace) => Icon(
                      type == 'commit' ? Icons.commit : Icons.person,
                      color: isDark ? AppDarkColors.textSecondary : AppColors.textSecondary,
                      size: 24,
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
                            TextSpan(text: '$name ', style: const TextStyle(fontWeight: FontWeight.bold)),
                            TextSpan(text: '$actionText '),
                            TextSpan(
                              text: linkText,
                              style: TextStyle(
                                color: isDark ? Colors.amberAccent : AppColors.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            TextSpan(text: ' $projectText', style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600], fontSize: 13)),
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
                      const SizedBox(width: 12),
                      Expanded(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: reactions.map((r) {
                              return Container(
                                margin: const EdgeInsets.only(right: 6),
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: isDark ? AppDarkColors.background.withOpacity(0.5) : AppColors.inputBackground.withOpacity(0.5),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isDark ? AppDarkColors.border.withOpacity(0.3) : AppColors.border.withOpacity(0.3),
                                    width: 0.5,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(r.reaksiEmoji, style: const TextStyle(fontSize: 12)),
                                    const SizedBox(width: 4),
                                    Text(
                                      r.pengirimNama,
                                      style: TextStyle(
                                        fontSize: 9,
                                        color: isDark ? Colors.white70 : Colors.black87,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
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
