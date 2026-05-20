import 'package:flutter/material.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/theme_mode.dart';
import '../../../profile/presentation/views/profile_view_manager.dart';
import 'create_post_screen.dart';

class CollabView extends StatelessWidget {
  const CollabView({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeControl.themeNotifier,
      builder: (context, currentMode, child) {
        bool isDark = currentMode == ThemeMode.dark;

        return Scaffold(
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
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Papan Peringkat Mingguan',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark ? AppDarkColors.textMain : AppColors.textMain,
                      ),
                    ),
                    Text(
                      '24 - 30 Juli',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? AppDarkColors.textSecondary : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                
                // Podium Section
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Rank 2
                    Expanded(
                      child: _buildPodiumCard(
                        rank: 2,
                        name: 'Dea',
                        score: '840',
                        isFirst: false,
                        avatarColor: const Color(0xFFD6E4FF), 
                        height: 140,
                        isDark: isDark,
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Rank 1
                    Expanded(
                      child: _buildPodiumCard(
                        rank: 1,
                        name: 'Sukma',
                        score: '1,205',
                        isFirst: true,
                        avatarColor: const Color(0xFF84C6CE), 
                        height: 160,
                        isDark: isDark,
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Rank 3
                    Expanded(
                      child: _buildPodiumCard(
                        rank: 3,
                        name: 'Dian',
                        score: '790',
                        isFirst: false,
                        avatarColor: const Color(0xFFFFCCB3), 
                        height: 130,
                        isDark: isDark,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

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
                          'Lihat Semua',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.amberAccent : AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward, 
                          size: 14, 
                          color: isDark ? Colors.amberAccent : AppColors.primary
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                _buildActivityCard(
                  name: 'Dea',
                  avatarAsset: 'image/ic_avatar_dea.png',
                  actionText: 'menyelesaikan',
                  linkText: 'Task Design System',
                  time: '2j lalu',
                  kudosIcon: '👏',
                  kudosText: 'Beri Kudos',
                  isDark: isDark,
                  extraWidget: Row(
                    children: [
                      _buildMiniAvatar('S', isDark: isDark),
                      _buildMiniAvatar('AK', isDark: isDark),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                _buildActivityCard(
                  name: 'Dian',
                  avatarAsset: 'image/ic_avatar_dian.png',
                  actionText: 'mengunggah',
                  linkText: 'Dokumentasi Sprint 12',
                  time: '4j lalu',
                  kudosIcon: '👍',
                  kudosText: 'Beri Kudos',
                  isDark: isDark,
                  extraWidget: null,
                ),
                const SizedBox(height: 16),

                _buildActivityCard(
                  name: 'Sukma',
                  avatarAsset: 'image/ic_avatar_sukma.png',
                  actionText: 'mencapai\nmilestone',
                  linkText: '1,000 Kudos Club!',
                  time: 'Kemarin',
                  kudosIcon: '🔥',
                  kudosText: 'Beri Kudos',
                  isDark: isDark,
                  extraWidget: Text(
                    '12 orang memberi\nkudos',
                    style: TextStyle(
                      fontSize: 12, 
                      color: isDark ? AppDarkColors.textSecondary : AppColors.textSecondary, 
                      height: 1.4
                    ),
                  ),
                ),
                const SizedBox(height: 40),
              ],
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
    required String avatarAsset,
    required String actionText,
    required String linkText,
    required String time,
    required String kudosIcon,
    required String kudosText,
    required Widget? extraWidget,
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
            child: Image.asset(
              avatarAsset,
              errorBuilder: (context, error, stackTrace) => Icon(
                Icons.account_circle, 
                color: isDark ? AppDarkColors.textSecondary : AppColors.textSecondary, 
                size: 40
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
                            TextSpan(text: '$actionText\n'),
                            TextSpan(
                              text: linkText,
                              style: TextStyle(
                                color: isDark ? Colors.amberAccent : AppColors.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Text(
                      time,
                      style: TextStyle(
                        fontSize: 12, 
                        color: isDark ? AppDarkColors.textSecondary : AppColors.textSecondary
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Container(
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
                    if (extraWidget != null) ...[
                      const SizedBox(width: 12),
                      extraWidget,
                    ]
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniAvatar(String initials, {required bool isDark}) {
    return Container(
      width: 24,
      height: 24,
      margin: const EdgeInsets.only(right: 4),
      decoration: BoxDecoration(
        color: isDark ? AppDarkColors.border : const Color(0xFFE0E0E0),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          initials,
          style: TextStyle(
            fontSize: 8, 
            fontWeight: FontWeight.bold, 
            color: isDark ? AppDarkColors.textMain : AppColors.textMain
          ),
        ),
      ),
    );
  }
}