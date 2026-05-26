import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pbl_kyu/core/theme/colors.dart';
import 'package:pbl_kyu/core/theme/theme_mode.dart';
import 'package:pbl_kyu/features/profile/presentation/views/profile_view_manager.dart';
import 'package:pbl_kyu/features/profile/presentation/views/profile_view_team.dart';

// ── MODULE C: Anti-404 Asset Engine ───────────────────────────────────────
// Fungsi global untuk membangun ImageProvider yang aman dari error 404.
// Dipanggil di seluruh viewport app yang menampilkan avatar.
ImageProvider buildSafeAvatarImage(String? avatarUrl) {
  // Rule 1: null atau kosong → fallback ke aset lokal
  if (avatarUrl == null || avatarUrl.trim().isEmpty) {
    return const AssetImage('image/logoSemua.png');
  }

  final url = avatarUrl.trim();

  // Rule 2: URL internet (http/https) → NetworkImage
  if (url.startsWith('http://') || url.startsWith('https://')) {
    return NetworkImage(url);
  }

  // Rule 3: Path lama dengan percent-encoding → bersihkan dan gunakan AssetImage
  final cleaned = url
      .replaceAll('%2520', ' ')
      .replaceAll('%20', ' ');
  return AssetImage(cleaned);
}
// ──────────────────────────────────────────────────────────────────────────

class ProfileAvatar extends StatelessWidget {
  final double radius;

  const ProfileAvatar({super.key, this.radius = 16});

  Widget _buildAvatarChild(String? avatarUrl, bool isDark) {
    // MODULE C: Logika Anti-404 dengan kondisi yang ketat
    if (avatarUrl != null && avatarUrl.trim().startsWith('http')) {
      return Image.network(
        avatarUrl.trim(),
        width: radius * 2,
        height: radius * 2,
        fit: BoxFit.cover,
        // Error fallback: tampilkan ikon person jika network 404 / gagal load
        errorBuilder: (context, error, stackTrace) => Icon(
          Icons.person,
          color: isDark ? AppDarkColors.textMain : AppColors.textMain,
          size: radius * 1.5,
        ),
      );
    }

    // Fallback: Tampilkan icon person secara langsung tanpa load asset gambar yang tidak ada
    return Center(
      child: Icon(
        Icons.person,
        color: isDark ? AppDarkColors.textMain : AppColors.textMain,
        size: radius * 1.5,
      ),
    );
  }

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
              child: ClipOval(child: _buildAvatarChild(avatarUrl as String?, isDark)),
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
