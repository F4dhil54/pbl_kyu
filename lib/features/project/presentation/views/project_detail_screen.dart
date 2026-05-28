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
        bool showTeamsTab = false;

        return StatefulBuilder(
          builder: (context, setState) {
            return Consumer(
              builder: (context, ref, child) {
                final activeColleaguesAsync = ref.watch(managerActiveColleaguesProvider);
                final currentMembersAsync = ref.watch(projectMembersProvider(project.id));
                
                final managerTeamsAsync = ref.watch(managerTeamsProvider);
                final projectTeamsAsync = ref.watch(projectTeamsProvider(project.id));

                final isDark = ThemeControl.themeNotifier.value == ThemeMode.dark;

                return AlertDialog(
                  backgroundColor: isDark ? AppDarkColors.surface : Colors.white,
                  title: Text(
                    'Undang ke Proyek',
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  content: SizedBox(
                    width: double.maxFinite,
                    height: 380,
                    child: Column(
                      children: [
                        // Tab Selector
                        Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () => setState(() => showTeamsTab = false),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  decoration: BoxDecoration(
                                    border: Border(
                                      bottom: BorderSide(
                                        color: !showTeamsTab ? AppColors.primary : Colors.transparent,
                                        width: 2,
                                      ),
                                    ),
                                  ),
                                  child: Text(
                                    'Anggota',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontWeight: !showTeamsTab ? FontWeight.bold : FontWeight.normal,
                                      color: !showTeamsTab ? AppColors.primary : Colors.grey,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              child: GestureDetector(
                                onTap: () => setState(() => showTeamsTab = true),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  decoration: BoxDecoration(
                                    border: Border(
                                      bottom: BorderSide(
                                        color: showTeamsTab ? AppColors.primary : Colors.transparent,
                                        width: 2,
                                      ),
                                    ),
                                  ),
                                  child: Text(
                                    'Tim',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontWeight: showTeamsTab ? FontWeight.bold : FontWeight.normal,
                                      color: showTeamsTab ? AppColors.primary : Colors.grey,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // List View content
                        Expanded(
                          child: !showTeamsTab
                              ? activeColleaguesAsync.when(
                                  loading: () => const Center(child: CircularProgressIndicator()),
                                  error: (err, stack) => Center(child: Text('Gagal memuat relasi: $err')),
                                  data: (colleagues) {
                                    return currentMembersAsync.when(
                                      loading: () => const Center(child: CircularProgressIndicator()),
                                      error: (err, stack) => Center(child: Text('Error: $err')),
                                      data: (members) {
                                        final memberUserIds = members.map((m) => m['user_id'] as String).toList();
                                        final nonMembers = colleagues.where((c) => !memberUserIds.contains(c['id'])).toList();

                                        if (nonMembers.isEmpty) {
                                          return const Center(
                                            child: Text(
                                              'Semua relasi aktif Anda sudah bergabung dalam proyek.',
                                              textAlign: TextAlign.center,
                                              style: TextStyle(fontSize: 13, color: Colors.grey),
                                            ),
                                          );
                                        }

                                        return ListView.builder(
                                          itemCount: nonMembers.length,
                                          itemBuilder: (context, index) {
                                            final colleague = nonMembers[index];
                                            final nama = colleague['nama'] ?? 'User';
                                            final email = colleague['email'] ?? '';
                                            final role = colleague['role'] ?? 'Tim';

                                            return ListTile(
                                              contentPadding: EdgeInsets.zero,
                                              leading: CircleAvatar(
                                                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                                                child: Text(nama.isNotEmpty ? nama[0].toUpperCase() : 'U', style: const TextStyle(color: AppColors.primary)),
                                              ),
                                              title: Text(nama, style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 14)),
                                              subtitle: Text('$email • $role', style: const TextStyle(fontSize: 11)),
                                              trailing: IconButton(
                                                icon: const Icon(Icons.person_add_alt_1, color: AppColors.primary),
                                                onPressed: () async {
                                                  try {
                                                    final supabase = ref.read(supabaseClientProvider);
                                                    final user = supabase.auth.currentUser;
                                                    await supabase.from('project_members').insert({
                                                      'project_id': project.id,
                                                      'user_id': colleague['id'],
                                                      'invited_by': user?.id,
                                                      'status_akses': 'aktif',
                                                    });

                                                    // Notifications
                                                    try {
                                                      // Notify the new member
                                                      await supabase.from('notifications').insert({
                                                        'user_id': colleague['id'],
                                                        'sender_id': user?.id,
                                                        'project_id': project.id,
                                                        'tipe_notifikasi': 'proyek',
                                                        'judul': 'Ditambahkan ke Proyek',
                                                        'pesan': 'Anda telah ditambahkan ke dalam proyek.',
                                                        'is_read': false,
                                                      });
                                                      
                                                      // Notify existing members
                                                      final membersRes = await supabase.from('project_members')
                                                          .select('user_id')
                                                          .eq('project_id', project.id)
                                                          .eq('status_akses', 'aktif');
                                                      final members = membersRes as List<dynamic>;
                                                      
                                                      final notifications = members
                                                          .map((m) => m['user_id'] as String)
                                                          .where((uid) => uid != user?.id && uid != colleague['id'])
                                                          .map((uid) => {
                                                                'user_id': uid,
                                                                'sender_id': user?.id,
                                                                'project_id': project.id,
                                                                'tipe_notifikasi': 'proyek',
                                                                'judul': 'Anggota Baru',
                                                                'pesan': 'Manajer telah menambahkan $nama sebagai anggota baru dalam proyek.',
                                                                'is_read': false,
                                                              })
                                                          .toList();
                                                          
                                                      if (notifications.isNotEmpty) {
                                                        await supabase.from('notifications').insert(notifications);
                                                      }
                                                    } catch (_) {}

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
                                )
                              : managerTeamsAsync.when(
                                  loading: () => const Center(child: CircularProgressIndicator()),
                                  error: (err, stack) => Center(child: Text('Gagal memuat tim: $err')),
                                  data: (teams) {
                                    return projectTeamsAsync.when(
                                      loading: () => const Center(child: CircularProgressIndicator()),
                                      error: (err, stack) => Center(child: Text('Error: $err')),
                                      data: (pTeams) {
                                        final projectTeamIds = pTeams.map((pt) => pt['team_id'] as String).toList();
                                        final nonProjectTeams = teams.where((t) => !projectTeamIds.contains(t['id'])).toList();

                                        if (nonProjectTeams.isEmpty) {
                                          return const Center(
                                            child: Text(
                                              'Semua tim Anda sudah diundang ke proyek.',
                                              textAlign: TextAlign.center,
                                              style: TextStyle(fontSize: 13, color: Colors.grey),
                                            ),
                                          );
                                        }

                                        return ListView.builder(
                                          itemCount: nonProjectTeams.length,
                                          itemBuilder: (context, index) {
                                            final team = nonProjectTeams[index];
                                            final namaTim = team['nama_tim'] ?? 'Grup Tim';
                                            final deskripsi = team['deskripsi'] ?? '';

                                            return ListTile(
                                              contentPadding: EdgeInsets.zero,
                                              leading: CircleAvatar(
                                                backgroundColor: Colors.amber.withValues(alpha: 0.1),
                                                child: const Icon(Icons.group, color: Colors.amber),
                                              ),
                                              title: Text(namaTim, style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 14)),
                                              subtitle: Text(deskripsi, style: const TextStyle(fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis),
                                              trailing: IconButton(
                                                icon: const Icon(Icons.group_add, color: AppColors.primary),
                                                onPressed: () async {
                                                  try {
                                                    final supabase = ref.read(supabaseClientProvider);
                                                    final user = supabase.auth.currentUser;
                                                    if (user == null) return;

                                                    // 1. Fetch team members
                                                    final teamMembersRes = await supabase
                                                        .from('team_members')
                                                        .select('user_id')
                                                        .eq('team_id', team['id']);
                                                    
                                                    final teamMembersList = teamMembersRes as List<dynamic>;

                                                    // 2. Insert each team member to project_members
                                                    for (final tm in teamMembersList) {
                                                      await supabase.from('project_members').upsert({
                                                        'project_id': project.id,
                                                        'user_id': tm['user_id'],
                                                        'invited_by': user.id,
                                                        'status_akses': 'aktif',
                                                      }, onConflict: 'project_id, user_id');
                                                    }

                                                    // 3. Insert relationship into project_teams
                                                    await supabase.from('project_teams').insert({
                                                      'project_id': project.id,
                                                      'team_id': team['id'],
                                                    });

                                                    // Notifications for team members
                                                    try {
                                                      final membersRes = await supabase.from('project_members')
                                                          .select('user_id')
                                                          .eq('project_id', project.id)
                                                          .eq('status_akses', 'aktif');
                                                      final allProjectMembers = membersRes as List<dynamic>;
                                                      
                                                      final newTeamMemberIds = teamMembersList.map((m) => m['user_id'] as String).toSet();
                                                      final notifications = <Map<String, dynamic>>[];
                                                      
                                                      for (final m in allProjectMembers) {
                                                        final uid = m['user_id'] as String;
                                                        if (uid == user.id) continue;
                                                        
                                                        if (newTeamMemberIds.contains(uid)) {
                                                          // Notification for newly added team members
                                                          notifications.add({
                                                            'user_id': uid,
                                                            'sender_id': user.id,
                                                            'project_id': project.id,
                                                            'tipe_notifikasi': 'proyek',
                                                            'judul': 'Tim Ditambahkan ke Proyek',
                                                            'pesan': 'Tim Anda *$namaTim*, telah ditambahkan ke dalam proyek.',
                                                            'is_read': false,
                                                          });
                                                        } else {
                                                          // Notification for existing project members
                                                          notifications.add({
                                                            'user_id': uid,
                                                            'sender_id': user.id,
                                                            'project_id': project.id,
                                                            'tipe_notifikasi': 'proyek',
                                                            'judul': 'Tim Baru Ditambahkan',
                                                            'pesan': 'Manajer telah menambahkan tim *$namaTim* ke dalam proyek.',
                                                            'is_read': false,
                                                          });
                                                        }
                                                      }
                                                      
                                                      if (notifications.isNotEmpty) {
                                                        await supabase.from('notifications').insert(notifications);
                                                      }
                                                    } catch (_) {}

                                                    if (context.mounted) {
                                                      ScaffoldMessenger.of(context).showSnackBar(
                                                        SnackBar(
                                                          content: Text('Tim $namaTim berhasil diundang ke proyek!'),
                                                          backgroundColor: AppColors.successText,
                                                        ),
                                                      );
                                                    }
                                                    ref.invalidate(projectMembersProvider(project.id));
                                                    ref.invalidate(projectTeamsProvider(project.id));
                                                    if (dialogContext.mounted) {
                                                      Navigator.pop(dialogContext);
                                                    }
                                                  } catch (e) {
                                                    if (context.mounted) {
                                                      ScaffoldMessenger.of(context).showSnackBar(
                                                        SnackBar(
                                                          content: Text('Gagal mengundang tim: $e'),
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
                      ],
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
                      .approveOrRejectTask(task.id, 'Tidak Setujui', 'Ditinjau');
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
    // Gunakan role dari auth metadata (ditetapkan saat registrasi, bersifat static)
    // BUKAN creatorId == userId karena manajer lain akan tampil sebagai Tim
    final userRole = user?.userMetadata?['role'] as String? ?? 'Tim';
    final isManager = userRole == 'Manajer';
    final role = userRole;

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
                child: RefreshIndicator(
                  onRefresh: () async {
                    final projId = project.id;
                    ref.invalidate(projectTaskListProvider(projId));
                    ref.invalidate(projectMembersProvider(projId));
                    ref.invalidate(projectTeamsProvider(projId));
                    ref.invalidate(projectListProvider);
                    await Future.delayed(const Duration(milliseconds: 500));
                  },
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    physics: const AlwaysScrollableScrollPhysics(),
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
                                    color: AppColors.primary.withValues(alpha: 0.1),
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
                                  'Diposting: ${project.date}',
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
          floatingActionButton: (_activeTabIndex == 0 && !project.isReadOnly)
              ? FloatingActionButton(
                  heroTag: 'project_detail_fab',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CreateTaskScreen(
                          projectId: project.id,
                          isManager: isManager,
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
                activeFilter == 'Draft Tugas Saya' ? 'Draft Tugas Saya' : 'Tugas Aktif Proyek',
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
                        Icon(Icons.play_arrow_outlined, color: (activeFilter == 'Tugas Aktif' || activeFilter == 'Tugas Aktif Proyek' || activeFilter == 'Draft Tugas Saya') ? AppColors.primary : Colors.grey),
                        const SizedBox(width: 8),
                        Text('Tugas Aktif', style: TextStyle(color: (activeFilter == 'Tugas Aktif' || activeFilter == 'Tugas Aktif Proyek' || activeFilter == 'Draft Tugas Saya') ? AppColors.primary : null)),
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
            ] else ...[
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
                    value: 'Tugas Aktif Proyek',
                    child: Row(
                      children: [
                        Icon(Icons.play_arrow_outlined, color: (activeFilter != 'Draft Tugas Saya') ? AppColors.primary : Colors.grey),
                        const SizedBox(width: 8),
                        Text('Tugas Aktif Proyek', style: TextStyle(color: (activeFilter != 'Draft Tugas Saya') ? AppColors.primary : null)),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'Draft Tugas Saya',
                    child: Row(
                      children: [
                        Icon(Icons.edit_document, color: activeFilter == 'Draft Tugas Saya' ? AppColors.primary : Colors.grey),
                        const SizedBox(width: 8),
                        Text('Draft Tugas Saya', style: TextStyle(color: activeFilter == 'Draft Tugas Saya' ? AppColors.primary : null)),
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
            // Apply strict Gembok Hak Akses for Tim members on the raw list
            final currentUserId = Supabase.instance.client.auth.currentUser?.id;
            List<TaskModel> visibleTasks = allTasks;
            if (!isManager) {
              final now = DateTime.now();
              visibleTasks = allTasks.where((t) {
                // 1. Tugas aktif yang sudah di-acc manajer
                if (t.statusTugas == 'Akan Dikerjakan') return true;
                // 2. Tugas yang sudah selesai
                if (t.statusTugas == 'Selesai') return true;
                // 3. Tugas terjadwal yang sudah tiba waktunya
                if (t.statusTugas == 'Dijadwalkan' && t.scheduledFor != null && t.scheduledFor!.isBefore(now)) {
                  return true;
                }
                // 4. Tugas review (usulan Tim) yang dibuat oleh anggota ini sendiri
                if (t.statusTugas == 'Ditinjau' && t.createdBy == currentUserId) {
                  return true;
                }
                return false;
              }).toList();
            }

            // Apply Manager vs Team filters
            List<TaskModel> filteredList = [];
            if (isManager) {
              if (activeFilter == 'Tugas Aktif' || activeFilter == 'Tugas Aktif Proyek') {
                // Manajer: tampilkan tugas aktif (accept) dan selesai
                filteredList = visibleTasks.where((t) => t.statusTugas == 'Akan Dikerjakan' || t.statusTugas == 'Selesai').toList();
              } else if (activeFilter == 'Draft Manajer') {
                // Manajer: draft privat yang dibuat manajer
                filteredList = visibleTasks.where((t) =>
                  t.dibuatOlehRole == 'Manajer' &&
                  t.statusTugas == 'Draft' &&
                  t.scheduledFor == null
                ).toList();
              } else if (activeFilter == 'Draft Tim') {
                // Manajer: usulan dari anggota Tim yang menunggu persetujuan
                filteredList = visibleTasks.where((t) =>
                  t.dibuatOlehRole == 'Tim' &&
                  t.statusTugas == 'Ditinjau' &&
                  t.keputusanManajer == 'Menunggu'
                ).toList();
              } else if (activeFilter == 'Dijadwalkan') {
                filteredList = visibleTasks.where((t) => t.statusTugas == 'Dijadwalkan').toList();
              } else {
                // Default fallback
                filteredList = visibleTasks.where((t) => t.statusTugas == 'Akan Dikerjakan' || t.statusTugas == 'Selesai').toList();
              }
            } else {
              if (activeFilter == 'Draft Tugas Saya') {
                // Anggota Tim: usulan tugas yang dibuat oleh diri sendiri (menunggu / ditolak)
                filteredList = visibleTasks.where((t) =>
                  t.dibuatOlehRole == 'Tim' &&
                  t.statusTugas == 'Ditinjau' &&
                  t.createdBy == currentUserId
                ).toList();
              } else {
                // Default: hanya tugas aktif (sudah disetujui manajer)
                final now = DateTime.now();
                filteredList = visibleTasks.where((t) =>
                  t.statusTugas == 'Akan Dikerjakan' ||
                  t.statusTugas == 'Selesai' ||
                  (t.statusTugas == 'Dijadwalkan' && t.scheduledFor != null && t.scheduledFor!.isBefore(now))
                ).toList();
              }
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
                final members = ref.watch(projectMembersProvider(project.id)).value;
                final teams = ref.watch(projectTeamsProvider(project.id)).value;
                return _buildTaskCardWidget(context, task, isDark, isManager, project, members, teams);
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
              ? AppColors.primary.withValues(alpha: 0.2)
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

  Widget _buildTaskCardWidget(BuildContext context, TaskModel task, bool isDark, bool isManager, ProjectModel project, List<Map<String, dynamic>>? members, List<Map<String, dynamic>>? teams) {
    final bool isDone = task.statusTugas == 'Selesai';
    final Color categoryColor = isDone
        ? const Color(0xFF10B981)
        : (task.prioritas == 'Do'
            ? const Color(0xFFEF4444)
            : (task.prioritas == 'Schedule' ? const Color(0xFFF59E0B) : const Color(0xFF3B82F6)));

    final String visualCategory = isDone ? 'Done' : task.prioritas;
    final String? currentUserId = Supabase.instance.client.auth.currentUser?.id;
    final bool isAssignedToMe = currentUserId != null && task.assignees.contains(currentUserId);
    final bool isReadOnlyMode = !isManager && !isAssignedToMe;

    String assigneesText = 'Belum Ditugaskan';
    List<String> assignedNames = [];
    
    if (task.projectTeamId != null && teams != null) {
      final teamIter = teams.where((t) => t['id'] == task.projectTeamId);
      if (teamIter.isNotEmpty) {
        assignedNames.add(teamIter.first['nama_tim'] as String);
      }
    }
    
    if (task.assignees.isNotEmpty && members != null) {
      final memberNames = members.where((m) => task.assignees.contains(m['user_id'])).map((m) => m['nama'] as String).toList();
      assignedNames.addAll(memberNames);
    }
    
    if (assignedNames.isNotEmpty) {
      assigneesText = assignedNames.join(', ');
    } else if (task.assignees.isNotEmpty) {
      assigneesText = '${task.assignees.length} Anggota';
    }

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TaskDetailTeamScreen(task: task, isReadOnly: isReadOnlyMode),
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
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: categoryColor.withValues(alpha: 0.1),
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
                    if (task.dibuatOlehRole == 'Tim') ...[
                      const SizedBox(width: 8),
                      if (task.statusTugas == 'Ditinjau' && task.keputusanManajer == 'Menunggu')
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.amber.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'DITINJAU',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: Colors.amber,
                            ),
                          ),
                        )
                      else if (task.keputusanManajer == 'Tidak Setujui')
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'TIDAK DISETUJUI',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: Colors.red,
                            ),
                          ),
                        ),
                    ],
                  ],
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
                                builder: (context) => CreateTaskScreen(projectId: task.projectId, taskToEdit: task, isManager: isManager),
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
                else if (isManager || (!isManager && !project.isReadOnly && task.dibuatOlehRole == 'Tim' && task.statusTugas == 'Ditinjau' && task.createdBy == currentUserId))
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, size: 18),
                    onSelected: (val) {
                      if (val == 'edit') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CreateTaskScreen(projectId: task.projectId, taskToEdit: task, isManager: isManager),
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
              children: [
                const Icon(Icons.person, size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    'Ditugaskan ke: $assigneesText',
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
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
    final memberTeamsAsync = ref.watch(projectMembersTeamsProvider(project.id));
    final profiles = ref.watch(allProfilesProvider).value;
    
    String managerName = 'Manager Workspace';
    String managerEmail = 'Owner/Creator';
    String managerAvatarUrl = '';
    
    if (profiles != null) {
      final managerProfile = profiles.firstWhere((p) => p['id'] == project.creatorId, orElse: () => {});
      if (managerProfile.isNotEmpty) {
        managerName = managerProfile['nama'] ?? managerName;
        managerEmail = managerProfile['email'] ?? managerEmail;
        managerAvatarUrl = managerProfile['avatar_url'] ?? '';
      }
    }

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
              CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                child: managerAvatarUrl.isNotEmpty && managerAvatarUrl.trim().startsWith('http')
                    ? ClipOval(
                        child: Image.network(
                          managerAvatarUrl.trim(),
                          width: 36,
                          height: 36,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Text(
                            managerName.isNotEmpty ? managerName[0].toUpperCase() : 'M',
                            style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                          ),
                        ),
                      )
                    : Text(
                        managerName.isNotEmpty ? managerName[0].toUpperCase() : 'M',
                        style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      managerName,
                      style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text('$managerEmail • Manajer/Owner', style: const TextStyle(fontSize: 11, color: Colors.grey), maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Anggota Tim Tergabung',
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
                final userId = member['user_id'] as String;
                final teamNames = memberTeamsAsync.value?[userId] ?? <String>[];

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
                        backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                        child: Text(nama[0].toUpperCase(), style: const TextStyle(color: AppColors.primary)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(nama, style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)),
                            Text('$email • $role', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                            if (teamNames.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Wrap(
                                spacing: 4,
                                runSpacing: 4,
                                children: teamNames.map((tName) => Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.amber.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
                                  ),
                                  child: Text(tName, style: const TextStyle(fontSize: 9, color: Colors.amber, fontWeight: FontWeight.bold)),
                                )).toList(),
                              ),
                            ],
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
