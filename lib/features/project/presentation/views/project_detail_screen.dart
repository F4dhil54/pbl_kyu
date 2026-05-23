import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/theme_mode.dart';
import '../../../../core/network/supabase_provider.dart';
import 'package:pbl_kyu/shared/widgets/profile_avatar.dart';
import '../../../task/data/models/task_model.dart';
import '../../../task/presentation/providers/task_provider.dart';
import '../../../task/presentation/views/create_task_screen.dart';
import '../../../task/presentation/views/task_detail_team_screen.dart';
import '../../data/models/project_model.dart';
import '../providers/project_provider.dart';

class ProjectDetailScreen extends ConsumerStatefulWidget {
  final ProjectModel project;

  const ProjectDetailScreen({super.key, required this.project});

  @override
  ConsumerState<ProjectDetailScreen> createState() => _ProjectDetailScreenState();
}

class _ProjectDetailScreenState extends ConsumerState<ProjectDetailScreen> {
  int _activeTabIndex = 0; // 0: Tugas, 1: Orang
  String _selectedEisenhowerFilter = 'Semua'; // Semua, Do, Schedule, Delegate, Done



  void _showInviteMemberDialog(BuildContext context, ProjectModel project) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return Consumer(
          builder: (context, ref, child) {
            final allProfilesAsync = ref.watch(allProfilesProvider);
            final currentMembersAsync = ref.watch(projectMembersProvider(project.id));
            final isDark = ThemeControl.themeNotifier.value == ThemeMode.dark;

            return AlertDialog(
              backgroundColor: isDark ? AppDarkColors.surface : Colors.white,
              title: Text(
                'Undang Anggota Baru',
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: SizedBox(
                width: double.maxFinite,
                height: 300,
                child: allProfilesAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (err, stack) => Center(child: Text('Gagal memuat profil: $err')),
                  data: (allProfiles) {
                    return currentMembersAsync.when(
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (err, stack) => Center(child: Text('Error: $err')),
                      data: (members) {
                        final memberUserIds = members.map((m) => m['user_id'] as String).toList();
                        // Filter out users who are already in the project
                        final nonMembers = allProfiles.where((p) => !memberUserIds.contains(p['id'])).toList();

                        if (nonMembers.isEmpty) {
                          return const Center(
                            child: Text(
                              'Semua pengguna sudah bergabung dalam proyek.',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 14, color: Colors.grey),
                            ),
                          );
                        }

                        return ListView.builder(
                          itemCount: nonMembers.length,
                          itemBuilder: (context, index) {
                            final profile = nonMembers[index];
                            final nama = profile['nama'] ?? 'User';
                            final email = profile['email'] ?? '';
                            final role = profile['role'] ?? 'Tim';

                            return ListTile(
                              leading: CircleAvatar(
                                backgroundColor: AppColors.primary.withOpacity(0.1),
                                child: Text(nama.isNotEmpty ? nama[0].toUpperCase() : 'U', style: const TextStyle(color: AppColors.primary)),
                              ),
                              title: Text(nama, style: TextStyle(color: isDark ? Colors.white : Colors.black)),
                              subtitle: Text('$email • $role', style: const TextStyle(fontSize: 12)),
                              trailing: IconButton(
                                icon: const Icon(Icons.person_add_alt_1, color: AppColors.primary),
                                onPressed: () async {
                                  try {
                                    if (project.id.startsWith('local-')) {
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text('$nama berhasil ditambahkan ke proyek (Lokal)!'),
                                            backgroundColor: AppColors.successText,
                                          ),
                                        );
                                      }
                                      if (dialogContext.mounted) {
                                       Navigator.pop(dialogContext);
                                     }
                                      return;
                                    }
                                    final supabase = ref.read(supabaseClientProvider);
                                    await supabase.from('project_members').insert({
                                      'project_id': project.id,
                                      'user_id': profile['id'],
                                      'status_akses': 'aktif',
                                    });

                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('$nama berhasil ditambahkan ke proyek!'),
                                          backgroundColor: AppColors.successText,
                                        ),
                                      );
                                    }
                                     ref.invalidate(projectMembersProvider(project.id));
                                     if (dialogContext.mounted) {
                                       Navigator.pop(dialogContext);
                                     }
                                  } catch (e) {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('Gagal menambahkan anggota: $e'),
                                          backgroundColor: AppColors.alertText,
                                        ),
                                      );
                                    }
                                  }
                                },
                              ),
                            );
                          },
                        );
                      },
                    );
                  },
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Batal', style: TextStyle(color: Colors.grey)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showDecisionDialog(BuildContext context, TaskModel task) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Keputusan Draft Tugas'),
          content: Text('Apakah Anda ingin menyetujui tugas "${task.judulTugas}" yang diusulkan oleh tim?'),
          actions: [
            TextButton(
              onPressed: () async {
                Navigator.pop(dialogContext);
                try {
                  await ref.read(projectTaskListProvider(task.projectId).notifier)
                      .approveOrRejectTask(task.id, 'Tidak Setujui', 'draft');
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Tugas ditolak.'),
                        backgroundColor: AppColors.alertText,
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Gagal: $e')),
                    );
                  }
                }
              },
              child: const Text('Tolak Usulan', style: TextStyle(color: Colors.red)),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(dialogContext);
                try {
                  await ref.read(projectTaskListProvider(task.projectId).notifier)
                      .approveOrRejectTask(task.id, 'Setujui', 'Akan Dikerjakan');
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Tugas disetujui dan sekarang aktif!'),
                        backgroundColor: AppColors.successText,
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Gagal menyetujui: $e')),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.successText),
              child: const Text('Setujui & Aktifkan', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final projectsAsync = ref.watch(projectListProvider);
    final project = projectsAsync.whenOrNull(
          data: (list) => list.firstWhere(
            (element) => element.id == widget.project.id,
            orElse: () => widget.project,
          ),
        ) ??
        widget.project;

    final user = Supabase.instance.client.auth.currentUser;
    final role = user?.userMetadata?['role'] ?? 'Tim';
    final isManager = role == 'Manajer';

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
              'KYU',
              style: TextStyle(
                color: isDark ? Colors.white : const Color(0xFF1E3A8A),
                fontWeight: FontWeight.w900,
                fontSize: 20,
                letterSpacing: 1,
              ),
            ),
            actions: [
              const ProfileAvatarButton(),
              const SizedBox(width: 20),
            ],
          ),
          body: Column(
            children: [
              // Scrollable Header Info
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Breadcrumb
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Proyek: ${project.name}',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: isDark ? AppDarkColors.textSecondary : AppColors.textSecondary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            Icons.chevron_right,
                            size: 14,
                            color: isDark ? AppDarkColors.textMain : AppColors.textMain,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _activeTabIndex == 0 ? 'Tugas' : 'Anggota',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: isDark ? AppDarkColors.textMain : AppColors.textMain,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Project header details
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDark ? AppDarkColors.surface : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: isDark ? AppDarkColors.border : AppColors.border, width: 0.5),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    project.category.toUpperCase(),
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ),
                                Text(
                                  'Tenggat: ${project.date}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: isDark ? AppDarkColors.textSecondary : AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              project.name,
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: isDark ? AppDarkColors.textMain : AppColors.textMain,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              project.description.isNotEmpty ? project.description : 'Tidak ada deskripsi proyek.',
                              style: TextStyle(
                                fontSize: 13,
                                color: isDark ? AppDarkColors.textSecondary : AppColors.textMain,
                                height: 1.4,
                              ),
                            ),
                            if (project.githubRepo.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              const Divider(height: 1),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Icon(Icons.link, size: 16, color: isDark ? AppDarkColors.textSecondary : AppColors.textSecondary),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      project.githubRepo,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: AppColors.primary,
                                        decoration: TextDecoration.underline,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Toggle View
                      if (_activeTabIndex == 0)
                        _buildTugasTab(isDark, isManager, role, project)
                      else
                        _buildOrangTab(isDark, isManager, project),

                      const SizedBox(height: 40),

                      const SizedBox.shrink(),
                    ],
                  ),
                ),
              ),
            ],
          ),
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _activeTabIndex,
            selectedItemColor: AppColors.primary,
            unselectedItemColor: isDark ? AppDarkColors.textSecondary : AppColors.textSecondary,
            backgroundColor: isDark ? AppDarkColors.surface : Colors.white,
            onTap: (index) {
              setState(() {
                _activeTabIndex = index;
              });
            },
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.assignment_rounded),
                label: 'Tugas',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.people_alt_rounded),
                label: 'Orang',
              ),
            ],
          ),
          floatingActionButton: _activeTabIndex == 0
              ? FloatingActionButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CreateTaskScreen(
                          projectId: project.id,
                        ),
                      ),
                    );
                  },
                  backgroundColor: isDark ? AppColors.primary : Colors.black,
                  elevation: 4,
                  shape: const CircleBorder(),
                  child: const Icon(Icons.add, color: Colors.white, size: 28),
                )
              : null,
        );
      },
    );
  }

  Widget _buildTugasTab(bool isDark, bool isManager, String role, ProjectModel project) {
    final tasksAsync = ref.watch(projectTaskListProvider(project.id));
    final activeFilter = ref.watch(taskFilterProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!isManager) ...[
          // Git sync and suggestion instructions for members
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Tugas Aktif Proyek',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppDarkColors.textMain : AppColors.textMain,
                ),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Sinkronisasi commit GitHub berhasil diselaraskan!'),
                      backgroundColor: AppColors.successText,
                    ),
                  );
                },
                icon: const Icon(Icons.sync, size: 16, color: Colors.white),
                label: const Text('Sync GitHub', style: TextStyle(color: Colors.white, fontSize: 12)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF24292F),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  minimumSize: Size.zero,
                  elevation: 0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],

        // Eisenhower visual categories tabs with Funnel Filter
        Row(
          children: [
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildEisenhowerTab('Semua', isDark),
                    const SizedBox(width: 6),
                    _buildEisenhowerTab('Do', isDark),
                    const SizedBox(width: 6),
                    _buildEisenhowerTab('Schedule', isDark),
                    const SizedBox(width: 6),
                    _buildEisenhowerTab('Delegate', isDark),
                    const SizedBox(width: 6),
                    _buildEisenhowerTab('Done', isDark),
                  ],
                ),
              ),
            ),
            if (isManager) ...[
              const SizedBox(width: 8),
              PopupMenuButton<String>(
                icon: Icon(
                  Icons.filter_alt_outlined,
                  color: isDark ? AppDarkColors.textMain : AppColors.textMain,
                ),
                tooltip: 'Filter Status Tugas',
                onSelected: (value) {
                  ref.read(taskFilterProvider.notifier).state = value;
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'Tugas Aktif',
                    child: Row(
                      children: [
                        Icon(Icons.play_arrow_outlined, color: activeFilter == 'Tugas Aktif' ? AppColors.primary : Colors.grey),
                        const SizedBox(width: 8),
                        Text('Tugas Aktif', style: TextStyle(color: activeFilter == 'Tugas Aktif' ? AppColors.primary : null)),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'Draft Manajer',
                    child: Row(
                      children: [
                        Icon(Icons.edit_document, color: activeFilter == 'Draft Manajer' ? AppColors.primary : Colors.grey),
                        const SizedBox(width: 8),
                        Text('Draft Manajer', style: TextStyle(color: activeFilter == 'Draft Manajer' ? AppColors.primary : null)),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'Draft Tim',
                    child: Row(
                      children: [
                        Icon(Icons.group_outlined, color: activeFilter == 'Draft Tim' ? AppColors.primary : Colors.grey),
                        const SizedBox(width: 8),
                        Text('Draft Tim', style: TextStyle(color: activeFilter == 'Draft Tim' ? AppColors.primary : null)),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'Dijadwalkan',
                    child: Row(
                      children: [
                        Icon(Icons.schedule_outlined, color: activeFilter == 'Dijadwalkan' ? AppColors.primary : Colors.grey),
                        const SizedBox(width: 8),
                        Text('Dijadwalkan', style: TextStyle(color: activeFilter == 'Dijadwalkan' ? AppColors.primary : null)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
        const SizedBox(height: 20),

        // List tasks
        tasksAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Center(child: Text('Gagal memuat tugas: $err')),
          data: (allTasks) {
            // Apply Manager role filters
            List<TaskModel> filteredList = [];
            if (isManager) {
              if (activeFilter == 'Tugas Aktif') {
                filteredList = allTasks.where((t) => t.statusTugas == 'Akan Dikerjakan' || t.statusTugas == 'Sedang Dikerjakan').toList();
              } else if (activeFilter == 'Draft Manajer') {
                filteredList = allTasks.where((t) => t.dibuatOlehRole == 'Manajer' && t.statusTugas == 'draft').toList();
              } else if (activeFilter == 'Draft Tim') {
                filteredList = allTasks.where((t) => t.dibuatOlehRole == 'Tim' && t.statusTugas == 'draft').toList();
              } else if (activeFilter == 'Dijadwalkan') {
                filteredList = allTasks.where((t) => t.statusTugas == 'scheduled').toList();
              }
            } else {
              // Team members only see active tasks
              filteredList = allTasks.where((t) => t.statusTugas == 'Akan Dikerjakan' || t.statusTugas == 'Sedang Dikerjakan' || t.statusTugas == 'Selesai').toList();
            }

            // Apply Eisenhower priority visual classifications
            if (_selectedEisenhowerFilter != 'Semua') {
              if (_selectedEisenhowerFilter == 'Done') {
                filteredList = filteredList.where((t) => t.statusTugas == 'Selesai').toList();
              } else {
                filteredList = filteredList.where((t) => t.statusTugas != 'Selesai' && t.prioritas.toLowerCase() == _selectedEisenhowerFilter.toLowerCase()).toList();
              }
            }

            if (filteredList.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 40.0),
                child: Center(
                  child: Text(
                    'Tidak ada tugas.',
                    style: TextStyle(color: isDark ? AppDarkColors.textSecondary : AppColors.textSecondary),
                  ),
                ),
              );
            }

            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filteredList.length,
              separatorBuilder: (context, index) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final task = filteredList[index];
                return _buildTaskCardWidget(context, task, isDark, isManager);
              },
            );
          },
        ),
      ],
    );
  }



  Widget _buildEisenhowerTab(String label, bool isDark) {
    final isSelected = _selectedEisenhowerFilter == label;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedEisenhowerFilter = label;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withOpacity(0.2)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : (isDark ? AppDarkColors.border : AppColors.border),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? AppColors.primary : (isDark ? Colors.grey[400] : Colors.grey[700]),
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  void _showDeleteTaskConfirmation(BuildContext context, TaskModel task) {
    final isDark = ThemeControl.themeNotifier.value == ThemeMode.dark;
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: isDark ? AppDarkColors.surface : Colors.white,
          title: Text('Hapus Tugas', style: TextStyle(color: isDark ? Colors.white : Colors.black)),
          content: Text('Apakah Anda yakin ingin menghapus tugas "${task.judulTugas}"?', style: TextStyle(color: isDark ? Colors.white70 : Colors.black87)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () async {
                Navigator.pop(context);
                try {
                  await ref.read(projectTaskListProvider(task.projectId).notifier).removeTask(task.id);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Tugas berhasil dihapus'),
                        backgroundColor: AppColors.successText,
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Gagal menghapus tugas: $e'),
                        backgroundColor: AppColors.alertText,
                      ),
                    );
                  }
                }
              },
              child: const Text('Hapus', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTaskCardWidget(BuildContext context, TaskModel task, bool isDark, bool isManager) {
    final bool isDone = task.statusTugas == 'Selesai';
    final Color categoryColor = isDone
        ? const Color(0xFF10B981)
        : (task.prioritas == 'Do'
            ? const Color(0xFFEF4444)
            : (task.prioritas == 'Schedule' ? const Color(0xFFF59E0B) : const Color(0xFF3B82F6)));

    final String visualCategory = isDone ? 'Done' : task.prioritas;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TaskDetailTeamScreen(task: task),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppDarkColors.surface : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isDark ? AppDarkColors.border : AppColors.border, width: 0.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: categoryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    visualCategory.toUpperCase(),
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: categoryColor,
                    ),
                  ),
                ),
                // Option edit/delete or draft actions
                if (isManager && task.dibuatOlehRole == 'Tim' && task.keputusanManajer == 'Menunggu')
                  Row(
                    children: [
                      ElevatedButton(
                        onPressed: () => _showDecisionDialog(context, task),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.amber,
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          minimumSize: Size.zero,
                        ),
                        child: const Text('Tinjau', style: TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(width: 4),
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert, size: 18),
                        onSelected: (val) {
                          if (val == 'edit') {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => CreateTaskScreen(projectId: task.projectId, taskToEdit: task),
                              ),
                            );
                          } else if (val == 'hapus') {
                            _showDeleteTaskConfirmation(context, task);
                          }
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'edit',
                            child: Text('Edit Tugas'),
                          ),
                          const PopupMenuItem(
                            value: 'hapus',
                            child: Text('Hapus Tugas', style: TextStyle(color: Colors.red)),
                          ),
                        ],
                      ),
                    ],
                  )
                else if (isManager)
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, size: 18),
                    onSelected: (val) {
                      if (val == 'edit') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CreateTaskScreen(projectId: task.projectId, taskToEdit: task),
                          ),
                        );
                      } else if (val == 'hapus') {
                        _showDeleteTaskConfirmation(context, task);
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Text('Edit Tugas'),
                      ),
                      const PopupMenuItem(
                        value: 'hapus',
                        child: Text('Hapus Tugas', style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              task.judulTugas,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isDark ? AppDarkColors.textMain : AppColors.textMain,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              task.deskripsiTugas,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                color: isDark ? AppDarkColors.textSecondary : AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  task.deadlineDate != null
                      ? 'Tenggat: ${task.deadlineDate!.day}/${task.deadlineDate!.month}/${task.deadlineDate!.year}'
                      : 'Tanpa Tenggat',
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrangTab(bool isDark, bool isManager, ProjectModel project) {
    final membersAsync = ref.watch(projectMembersProvider(project.id));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Manajer Proyek',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isDark ? AppDarkColors.textMain : AppColors.textMain,
              ),
            ),
            if (isManager)
              IconButton(
                onPressed: () => _showInviteMemberDialog(context, project),
                icon: const Icon(Icons.person_add_rounded, color: AppColors.primary),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDark ? AppDarkColors.surface : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isDark ? AppDarkColors.border : AppColors.border, width: 0.5),
          ),
          child: Row(
            children: [
              const ProfileAvatar(radius: 18),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Manager Workspace',
                    style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black),
                  ),
                  const Text('Owner/Creator', style: TextStyle(fontSize: 11, color: Colors.grey)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Anggota Tim Tergabung',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: isDark ? AppDarkColors.textMain : AppColors.textMain,
          ),
        ),
        const SizedBox(height: 12),
        membersAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Center(child: Text('Gagal memuat anggota: $err')),
          data: (membersList) {
            if (membersList.isEmpty) {
              return const Center(child: Text('Belum ada anggota tim yang bergabung.', style: TextStyle(color: Colors.grey)));
            }

            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: membersList.length,
              separatorBuilder: (context, index) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final member = membersList[index];
                final nama = member['nama'] ?? 'Anggota';
                final email = member['email'] ?? '';
                final role = member['role'] ?? 'Tim';

                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? AppDarkColors.surface : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: isDark ? AppDarkColors.border : AppColors.border, width: 0.5),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: AppColors.primary.withOpacity(0.1),
                        child: Text(nama[0].toUpperCase(), style: const TextStyle(color: AppColors.primary)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(nama, style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)),
                            Text('$email • $role', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                          ],
                        ),
                      ),
                      if (isManager)
                        PopupMenuButton<String>(
                          icon: Icon(
                            Icons.more_vert,
                            color: isDark ? AppDarkColors.textSecondary : AppColors.textSecondary,
                          ),
                          onSelected: (value) async {
                            if (value == 'delete') {
                              try {
                                if (project.id.startsWith('local-')) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Anggota berhasil dikeluarkan dari proyek (Lokal)'),
                                        backgroundColor: AppColors.successText,
                                      ),
                                    );
                                  }
                                  return;
                                }
                                final supabase = ref.read(supabaseClientProvider);
                                await supabase.from('project_members')
                                    .delete()
                                    .eq('id', member['member_id']);
                                
                                ref.invalidate(projectMembersProvider(project.id));
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Anggota berhasil dikeluarkan dari proyek'),
                                      backgroundColor: AppColors.successText,
                                    ),
                                  );
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Gagal mengeluarkan anggota: $e'),
                                      backgroundColor: AppColors.alertText,
                                    ),
                                  );
                                }
                              }
                            }
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(Icons.person_remove_outlined, color: Colors.red, size: 18),
                                  SizedBox(width: 8),
                                  Text('Hapus Anggota', style: TextStyle(color: Colors.red)),
                                ],
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }
}