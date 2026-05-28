import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/theme_mode.dart';
import 'edit_member_screen.dart';
import '../providers/profile_provider.dart';

class AllMembersScreen extends ConsumerWidget {
  const AllMembersScreen({super.key});

  void _showDeleteConfirmation(
    BuildContext context,
    WidgetRef ref, {
    required String title,
    required String message,
    required bool isDark,
    required String invitationId,
  }) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: isDark ? AppDarkColors.surface : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            title,
            style: TextStyle(
              color: isDark ? AppDarkColors.textMain : AppColors.textMain,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          content: Text(
            message,
            style: TextStyle(
              color: isDark ? AppDarkColors.textSecondary : AppColors.textSecondary,
              fontSize: 14,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Tidak',
                style: TextStyle(color: isDark ? AppDarkColors.textSecondary : AppColors.textSecondary),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                try {
                  await ref.read(profileRepositoryProvider).deleteInvitation(invitationId);
                  ref.invalidate(managerInvitationsProvider);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Anggota berhasil dihapus!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Gagal menghapus anggota: $e'),
                        backgroundColor: AppColors.alertText,
                      ),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.alertText,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Ya, Hapus', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

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
              onPressed: () => Navigator.pop(context, true),
            ),
            title: Text(
              'Semua Anggota Tim',
              style: TextStyle(
                color: isDark ? AppDarkColors.textMain : AppColors.textMain,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
          body: Consumer(
            builder: (context, ref, child) {
              final membersAsync = ref.watch(managerInvitationsProvider);
              return membersAsync.when(
                data: (members) {
                  if (members.isEmpty) {
                    return Center(child: Text('Belum ada anggota.', style: TextStyle(color: isDark ? AppDarkColors.textSecondary : AppColors.textSecondary)));
                  }
                  return RefreshIndicator(
                    onRefresh: () async {
                      ref.invalidate(managerInvitationsProvider);
                      await Future.delayed(const Duration(milliseconds: 500));
                    },
                    child: ListView.separated(
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
                          ref,
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
                    ),
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

  Widget _buildMemberItem(
    BuildContext context, 
    WidgetRef ref,
    String name, 
    String role, 
    String status, 
    Color statusColor, 
    Color statusBg, {
    required bool isDark, 
    required String invitationId, 
    required String email,
  }) {
    return Row(
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
              Row(
                children: [
                  Text(
                    role,
                    style: TextStyle(
                      fontSize: 12, 
                      color: isDark ? AppDarkColors.textSecondary : AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusBg,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      status,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        PopupMenuButton<String>(
          icon: Icon(
            Icons.more_vert,
            color: isDark ? AppDarkColors.textSecondary : AppColors.textSecondary,
            size: 20,
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          color: isDark ? AppDarkColors.surface : Colors.white,
          onSelected: (value) {
            if (value == 'edit') {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => EditMemberScreen(
                  invitationId: invitationId,
                  name: name,
                  email: email,
                  status: status.toLowerCase() == 'aktif' 
                      ? 'aktif' 
                      : (status.toLowerCase() == 'pending' || status.toLowerCase() == 'menunggu' 
                          ? 'pending' 
                          : 'nonaktif'),
                )),
              ).then((_) {
                ref.invalidate(managerInvitationsProvider);
              });
            } else if (value == 'delete') {
              _showDeleteConfirmation(
                context,
                ref,
                isDark: isDark,
                title: 'Konfirmasi Hapus',
                message: 'Apakah anda yakin ingin menghapus anggota "$name"?',
                invitationId: invitationId,
              );
            }
          },
          itemBuilder: (BuildContext context) => [
            PopupMenuItem<String>(
              value: 'edit',
              child: Text(
                'Edit',
                style: TextStyle(color: isDark ? AppDarkColors.textMain : AppColors.textMain),
              ),
            ),
            PopupMenuItem<String>(
              value: 'delete',
              child: Text(
                'Hapus',
                style: const TextStyle(color: AppColors.alertText),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
