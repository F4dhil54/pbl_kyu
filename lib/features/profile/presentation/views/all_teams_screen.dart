import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/theme_mode.dart';
import 'edit_team_screen.dart';
import '../providers/profile_provider.dart';
import '../../../project/presentation/providers/project_provider.dart';

class AllTeamsScreen extends ConsumerWidget {
  const AllTeamsScreen({super.key});

  void _showDeleteConfirmation(
    BuildContext context,
    WidgetRef ref, {
    required String title,
    required String message,
    required bool isDark,
    required String teamId,
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
                  await ref.read(profileRepositoryProvider).deleteTeam(teamId);
                  ref.invalidate(managerTeamsProvider);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Tim berhasil dihapus!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Gagal menghapus tim: $e'),
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
              'Semua Tim',
              style: TextStyle(
                color: isDark ? AppDarkColors.textMain : AppColors.textMain,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
          body: Consumer(
            builder: (context, ref, child) {
              final teamsAsync = ref.watch(managerTeamsProvider);
              return teamsAsync.when(
                data: (teams) {
                  if (teams.isEmpty) {
                    return Center(
                      child: Text(
                        'Belum ada tim yang dibuat.',
                        style: TextStyle(
                          color: isDark ? AppDarkColors.textSecondary : AppColors.textSecondary,
                        ),
                      ),
                    );
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.all(20),
                    itemCount: teams.length,
                    separatorBuilder: (context, index) => Divider(height: 32, color: isDark ? AppDarkColors.border : AppColors.border),
                    itemBuilder: (context, index) {
                      final team = teams[index];
                      final id = team['id'] as String;
                      final name = team['nama_tim'] as String;
                      
                      return Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.blue,
                            ),
                            child: const Center(
                              child: Icon(Icons.group, color: Colors.white, size: 18),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              name,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: isDark ? AppDarkColors.textMain : AppColors.textMain,
                              ),
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
                                  MaterialPageRoute(
                                    builder: (context) => EditTeamScreen(teamId: id, teamName: name),
                                  ),
                                ).then((_) {
                                  ref.invalidate(managerTeamsProvider);
                                });
                              } else if (value == 'delete') {
                                _showDeleteConfirmation(
                                  context,
                                  ref,
                                  isDark: isDark,
                                  title: 'Konfirmasi Hapus',
                                  message: 'Apakah anda yakin ingin menghapus tim "$name"?',
                                  teamId: id,
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
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) => Center(
                  child: Text(
                    'Gagal memuat data tim',
                    style: TextStyle(color: AppColors.alertText),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
