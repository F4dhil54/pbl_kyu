import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/theme_mode.dart';
import 'profile_avatar.dart';

/// Widget AppBar premium KYU dengan logo gradient yang konsisten di seluruh halaman.
/// Gunakan widget ini sebagai pengganti AppBar biasa untuk tampilan yang seragam dan premium.
class KyuAppBar extends StatelessWidget implements PreferredSizeWidget {
  /// Apakah menampilkan tombol back arrow (kiri)
  final bool showBackButton;

  /// Apakah menampilkan tombol menu hamburger (kiri)
  final bool showMenuButton;

  /// Fungsi custom saat back button ditekan (opsional)
  final VoidCallback? onBack;

  /// Apakah menampilkan ProfileAvatarButton (kanan)
  final bool showAvatar;

  /// Widget actions tambahan di kanan (opsional)
  final List<Widget>? extraActions;

  /// Apakah menampilkan bottom border/divider
  final bool showBottomBorder;

  const KyuAppBar({
    super.key,
    this.showBackButton = false,
    this.showMenuButton = false,
    this.onBack,
    this.showAvatar = true,
    this.extraActions,
    this.showBottomBorder = false,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeControl.themeNotifier,
      builder: (context, currentMode, child) {
        final isDark = currentMode == ThemeMode.dark;

        return AppBar(
          backgroundColor: isDark ? AppDarkColors.background : Colors.white,
          elevation: 0,
          scrolledUnderElevation: 0,
          systemOverlayStyle: isDark
              ? SystemUiOverlayStyle.light
              : SystemUiOverlayStyle.dark,
          shape: showBottomBorder
              ? Border(
                  bottom: BorderSide(
                    color: isDark ? AppDarkColors.border : const Color(0xFFEEEEEE),
                    width: 0.5,
                  ),
                )
              : null,
          leading: showBackButton
              ? IconButton(
                  icon: Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                    size: 20,
                  ),
                  onPressed: onBack ?? () => Navigator.of(context).pop(),
                )
              : showMenuButton
                  ? Builder(
                      builder: (context) => IconButton(
                        icon: Icon(
                          Icons.menu_rounded,
                          color: isDark ? Colors.white70 : const Color(0xFF1A1A2E),
                          size: 24,
                        ),
                        onPressed: () => Scaffold.of(context).openDrawer(),
                      ),
                    )
                  : null,
          title: _KyuLogo(isDark: isDark),
          centerTitle: false,
          actions: [
            if (extraActions != null) ...extraActions!,
            if (showAvatar) ...[
              const ProfileAvatarButton(radius: 17),
              const SizedBox(width: 16),
            ],
          ],
        );
      },
    );
  }
}

/// Widget logo KYU dengan styling premium — gradient text + dot aksen
class _KyuLogo extends StatelessWidget {
  final bool isDark;
  const _KyuLogo({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Logo icon box
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1E50FF), Color(0xFF7C3AED)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF1E50FF).withValues(alpha: 0.35),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: const Center(
            child: Text(
              'K',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 16,
                letterSpacing: -0.5,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        // KYU text with gradient
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [Color(0xFF1E50FF), Color(0xFF7C3AED)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ).createShader(bounds),
          blendMode: BlendMode.srcIn,
          child: const Text(
            'KYU',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 22,
              letterSpacing: 2,
              color: Colors.white, // required for ShaderMask
            ),
          ),
        ),
      ],
    );
  }
}
