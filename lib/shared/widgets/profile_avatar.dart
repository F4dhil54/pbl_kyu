import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pbl_kyu/core/theme/colors.dart';
import 'package:pbl_kyu/core/theme/theme_mode.dart';
import 'package:pbl_kyu/features/profile/presentation/views/profile_view_manager.dart';
import 'package:pbl_kyu/features/profile/presentation/views/profile_view_team.dart';

class ProfileAvatar extends StatelessWidget {
  final double radius;

  const ProfileAvatar({super.key, this.radius = 16});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeControl.themeNotifier,
      builder: (context, currentMode, child) {
        final isDark = currentMode == ThemeMode.dark;
        
        return StreamBuilder<AuthState>(
          stream: Supabase.instance.client.auth.onAuthStateChange,
          builder: (context, snapshot) {
            final user = Supabase.instance.client.auth.currentUser;
            final avatarUrl = user?.userMetadata?['avatar_url'] ??
                              user?.userMetadata?['picture'] ??
                              user?.userMetadata?['avatar'];

            return CircleAvatar(
              radius: radius,
              backgroundColor: isDark ? AppDarkColors.surface : AppColors.inputBackground,
              child: ClipOval(
                child: () {
                  if (avatarUrl != null && avatarUrl.isNotEmpty) {
                    return Image.network(
                      avatarUrl,
                      width: radius * 2,
                      height: radius * 2,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Icon(
                        Icons.person,
                        color: isDark ? AppDarkColors.textMain : AppColors.textMain,
                        size: radius * 1.5,
                      ),
                    );
                  }
                  return Image.asset(
                    'image/ic_profile.png',
                    width: radius * 1.5,
                    errorBuilder: (context, error, stackTrace) => Icon(
                      Icons.person,
                      color: isDark ? AppDarkColors.textMain : AppColors.textMain,
                      size: radius * 1.5,
                    ),
                  );
                }(),
              ),
            );
          },
        );
      },
    );
  }
}

class ProfileAvatarButton extends StatefulWidget {
  final double radius;

  const ProfileAvatarButton({
    super.key,
    this.radius = 16,
  });

  @override
  State<ProfileAvatarButton> createState() => _ProfileAvatarButtonState();
}

class _ProfileAvatarButtonState extends State<ProfileAvatarButton> {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final user = Supabase.instance.client.auth.currentUser;
        final role = user?.userMetadata?['role'] ?? 'Tim';
        final isManager = role == 'Manajer';

        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => isManager
                ? const ProfileViewManager()
                : const ProfileViewTeam(),
          ),
        );

        if (mounted) {
          setState(() {});
        }
      },
      child: ProfileAvatar(radius: widget.radius),
    );
  }
}
