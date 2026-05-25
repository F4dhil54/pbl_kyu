import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/theme_mode.dart';
import 'edit_member_screen.dart';
import '../providers/profile_provider.dart';

class AllMembersScreen extends ConsumerWidget {
  const AllMembersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeControl.themeNotifier,
      builder: (context, currentMode, child) {
        bool isDark = currentMode == ThemeMode.dark;

        return Scaffold(
          backgroundColor: isDark ? AppDarkColors.background : AppColors.background,
          appBar: AppBar(
            backgroundColor: isDark ? AppDarkColors.background : AppColors.background,
            elevation: 0,
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: isDark ? AppDarkColors.textMain : AppColors.textMain),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              'Semua Anggota Tim',
              style: TextStyle(
                color: isDark ? AppDarkColors.textMain : AppColors.textMain,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            actions: [
              IconButton(
                icon: Icon(Icons.search, color: isDark ? AppDarkColors.textMain : AppColors.textMain),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Fitur pencarian akan segera hadir!'), duration: Duration(seconds: 2)),
                  );
                },
              ),
            ],
          ),
          body: Consumer(
            builder: (context, ref, child) {
              final membersAsync = ref.watch(managerInvitationsProvider);
              return membersAsync.when(
                data: (members) {
                  if (members.isEmpty) {
                    return Center(child: Text('Belum ada anggota.', style: TextStyle(color: isDark ? AppDarkColors.textSecondary : AppColors.textSecondary)));
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.all(20),
                    itemCount: members.length,
                    separatorBuilder: (context, index) => Divider(height: 32, color: isDark ? AppDarkColors.border : AppColors.border),
                    itemBuilder: (context, index) {
                      final m = members[index];
                      String statusUI = 'Offline';
                      Color colorText = AppColors.offlineText;
                      Color colorBg = isDark ? AppColors.offlineText.withValues(alpha: 0.15) : AppColors.offlineBackground;
                      
                      if (m['status'] == 'aktif') {
                        statusUI = 'Aktif';
                        colorText = AppColors.successText;
                        colorBg = isDark ? AppColors.successText.withValues(alpha: 0.15) : AppColors.successBackground;
                      } else if (m['status'] == 'pending') {
                        statusUI = 'Menunggu';
                        colorText = AppColors.warningText;
                        colorBg = isDark ? AppColors.warningText.withValues(alpha: 0.15) : AppColors.warningBackground;
                      } else if (m['status'] == 'nonaktif') {
                        statusUI = 'Nonaktif';
                        colorText = AppColors.alertText;
                        colorBg = isDark ? AppColors.alertText.withValues(alpha: 0.15) : const Color(0xFFFFEBEB);
                      }

                      return _buildMemberItem(
                        context, 
                        m['name']?.toString() ?? 'Anggota', 
                        m['role']?.toString() ?? 'Anggota', 
                        statusUI, 
                        colorText, 
                        colorBg, 
                        isDark: isDark,
                        invitationId: m['invitation_id']?.toString() ?? '',
                        email: m['email']?.toString() ?? '',
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) => Center(child: Text('Gagal memuat data', style: TextStyle(color: AppColors.alertText))),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildMemberItem(BuildContext context, String name, String role, String status, Color statusColor, Color statusBg, {required bool isDark, required String invitationId, required String email}) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => EditMemberScreen(
            invitationId: invitationId,
            name: name,
            email: email,
            status: status.toLowerCase() == 'aktif' ? 'aktif' : (status.toLowerCase() == 'pending' || status.toLowerCase() == 'menunggu' ? 'pending' : 'nonaktif'),
          )),
        );
      },
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: Colors.transparent,
            child: Image.asset(
              'image/ic_avatar_${name.split(' ')[0].toLowerCase()}.png',
              errorBuilder: (context, error, stackTrace) => Icon(Icons.account_circle, size: 48, color: statusColor),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    fontWeight: FontWeight.bold, 
                    fontSize: 16, 
                    color: isDark ? AppDarkColors.textMain : AppColors.textMain,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  role,
                  style: TextStyle(
                    fontSize: 12, 
                    color: isDark ? AppDarkColors.textSecondary : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: statusBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: statusColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  status,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
