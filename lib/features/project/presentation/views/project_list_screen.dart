import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/colors.dart';
import '../../../../core/theme/theme_mode.dart';
import 'package:pbl_kyu/shared/widgets/profile_avatar.dart';
import 'package:pbl_kyu/shared/widgets/app_sidebar.dart';
import '../../data/models/project_model.dart';
import '../providers/project_provider.dart';
import 'create_project_screen.dart';
import 'edit_project_screen.dart';
import 'project_detail_screen.dart';

class ProjectListScreen extends ConsumerStatefulWidget {
  final String role;
  const ProjectListScreen({super.key, required this.role});

  @override
  ConsumerState<ProjectListScreen> createState() => _ProjectListScreenState();
}

class _ProjectListScreenState extends ConsumerState<ProjectListScreen> {
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  bool _showActiveOnly = true;

  String _formatIndonesianDate(DateTime? date) {
    if (date == null) return 'Diposting -';
    const months = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];
    return 'Diposting ${date.day} ${months[date.month - 1]} ${date.year}';
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final projectsState = ref.watch(projectListProvider);
    final searchQuery = ref.watch(projectSearchQueryProvider);
    
    final isManager = widget.role == 'Manajer';

    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeControl.themeNotifier,
      builder: (context, currentMode, child) {
        bool isDark = currentMode == ThemeMode.dark;

        return Scaffold(
          backgroundColor: isDark ? AppDarkColors.background : AppColors.background,
          drawer: const AppSidebar(),
          appBar: AppBar(
            backgroundColor: isDark ? AppDarkColors.background : AppColors.background,
            elevation: 0,
            leading: _isSearching
                ? null
                : Builder(
                    builder: (context) => IconButton(
                      icon: const Icon(Icons.menu),
                      onPressed: () => Scaffold.of(context).openDrawer(),
                    ),
                  ),
            title: _isSearching
                ? TextField(
                    controller: _searchController,
                    autofocus: true,
                    style: TextStyle(color: isDark ? Colors.white : Colors.black),
                    decoration: InputDecoration(
                      hintText: 'Cari proyek...',
                      hintStyle: TextStyle(
                        color: isDark ? AppDarkColors.textSecondary : AppColors.textSecondary,
                      ),
                      border: InputBorder.none,
                    ),
                    onChanged: (val) {
                      ref.read(projectSearchQueryProvider.notifier).state = val;
                    },
                  )
                : Text(
                    'KYU',
                    style: TextStyle(
                      color: isDark ? Colors.white : const Color(0xFF1E3A8A),
                      fontWeight: FontWeight.w900,
                      fontSize: 20,
                      letterSpacing: 1,
                    ),
                  ),
            actions: [
              IconButton(
                onPressed: () {
                  setState(() {
                    _isSearching = !_isSearching;
                    if (!_isSearching) {
                      _searchController.clear();
                      ref.read(projectSearchQueryProvider.notifier).state = '';
                    }
                  });
                },
                icon: Icon(
                  _isSearching ? Icons.close : Icons.search,
                  color: isDark ? AppDarkColors.textMain : AppColors.textMain,
                ),
              ),
              const ProfileAvatarButton(),
              const SizedBox(width: 20),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: () async {
              await ref.read(projectListProvider.notifier).fetchProjects();
            },
            child: projectsState.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
              error: (err, stack) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Gagal memuat proyek',
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: () {
                        ref.read(projectListProvider.notifier).fetchProjects();
                      },
                      child: const Text('Coba Lagi'),
                    ),
                  ],
                ),
              ),
              data: (projects) {
                // Role and status filtering
                List<ProjectModel> filteredProjects = projects;
                
                if (isManager) {
                  // Manager: Filter by active vs inactive tab
                  filteredProjects = projects.where((p) => p.statusAktif == _showActiveOnly).toList();
                } else {
                  // Team: Only active projects
                  filteredProjects = projects.where((p) => p.statusAktif).toList();
                }

                // Search filtering
                if (searchQuery.isNotEmpty) {
                  final searchLower = searchQuery.toLowerCase();
                  filteredProjects = filteredProjects.where((project) {
                    final nameLower = project.name.toLowerCase();
                    final descLower = project.description.toLowerCase();
                    return nameLower.contains(searchLower) || descLower.contains(searchLower);
                  }).toList();
                }

                return SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isManager ? 'Daftar Proyek' : 'Proyek Kolaborasi',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: isDark ? AppDarkColors.textMain : AppColors.textMain,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        isManager
                            ? 'Kelola proyek, atur tugas, dan pantau progres kerja tim Anda.'
                            : 'Akses proyek aktif untuk berkolaborasi dan menyelesaikan tugas.',
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark ? AppDarkColors.textSecondary : AppColors.textSecondary,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Manager Filter Tabs (Active vs Inactive)
                      if (isManager) ...[
                        Row(
                          children: [
                            _buildFilterTab(
                              context,
                              'Proyek Aktif',
                              _showActiveOnly,
                              () => setState(() => _showActiveOnly = true),
                              isDark,
                            ),
                            const SizedBox(width: 12),
                            _buildFilterTab(
                              context,
                              'Proyek Nonaktif',
                              !_showActiveOnly,
                              () => setState(() => _showActiveOnly = false),
                              isDark,
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                      ],

                      if (filteredProjects.isEmpty) ...[
                        const SizedBox(height: 60),
                        Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.folder_open_outlined,
                                size: 64,
                                color: isDark ? AppDarkColors.textSecondary : AppColors.textSecondary,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                searchQuery.isNotEmpty
                                    ? 'Proyek tidak ditemukan'
                                    : (isManager
                                        ? (_showActiveOnly ? 'Belum ada proyek aktif' : 'Tidak ada proyek nonaktif')
                                        : 'Belum ada proyek aktif yang ditugaskan kepada Anda'),
                                style: TextStyle(
                                  fontSize: 16,
                                  color: isDark ? AppDarkColors.textSecondary : AppColors.textSecondary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ] else ...[
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: filteredProjects.length,
                          separatorBuilder: (context, index) => const SizedBox(height: 16),
                          itemBuilder: (context, index) {
                            final project = filteredProjects[index];
                            return _buildProjectCard(
                              context,
                              project: project,
                              isDark: isDark,
                              isManager: isManager,
                            );
                          },
                        ),
                      ],
                      const SizedBox(height: 80),
                    ],
                  ),
                );
              },
            ),
          ),
          floatingActionButton: isManager
              ? FloatingActionButton(
                  heroTag: 'project_list_fab',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const CreateProjectScreen(),
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

  Widget _buildFilterTab(
    BuildContext context,
    String text,
    bool isSelected,
    VoidCallback onTap,
    bool isDark,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? Colors.white : AppColors.textMain)
              : (isDark ? AppDarkColors.surface : Colors.white),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? (isDark ? Colors.white : AppColors.textMain)
                : (isDark ? AppDarkColors.border : AppColors.border),
            width: 1,
          ),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isSelected
                ? (isDark ? AppDarkColors.background : Colors.white)
                : (isDark ? AppDarkColors.textSecondary : AppColors.textSecondary),
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildProjectCard(
    BuildContext context, {
    required ProjectModel project,
    required bool isDark,
    required bool isManager,
  }) {
    // Map category to styles dynamically
    Color categoryBgColor;
    Color categoryTextColor;

    switch (project.category.toUpperCase()) {
      case 'MARKETING':
      case 'PEMASARAN':
        categoryBgColor = isDark ? const Color(0xFF065F46).withValues(alpha: 0.3) : const Color(0xFFD1FAE5);
        categoryTextColor = isDark ? const Color(0xFF34D399) : const Color(0xFF065F46);
        break;
      case 'TEKNOLOGI':
      case 'IT INFRA':
      case 'IT':
        categoryBgColor = isDark ? const Color(0xFF1E3A8A).withValues(alpha: 0.4) : const Color(0xFFDBEAFE);
        categoryTextColor = isDark ? Colors.blue[200]! : const Color(0xFF1E3A8A);
        break;
      case 'KEUANGAN':
      case 'FINANCE':
        categoryBgColor = isDark ? const Color(0xFF451A03).withValues(alpha: 0.4) : const Color(0xFFFEF3C7);
        categoryTextColor = isDark ? Colors.orange[300]! : const Color(0xFF92400E);
        break;
      case 'OPERASIONAL':
      case 'OPERATIONS':
        categoryBgColor = isDark ? const Color(0xFF78350F).withValues(alpha: 0.4) : const Color(0xFFFEE2E2);
        categoryTextColor = isDark ? Colors.red[300]! : const Color(0xFF991B1B);
        break;
      case 'KREATIF/MEDIA':
      case 'CREATIVE':
        categoryBgColor = isDark ? const Color(0xFF581C87).withValues(alpha: 0.4) : const Color(0xFFF3E8FF);
        categoryTextColor = isDark ? Colors.purple[300]! : const Color(0xFF6B21A8);
        break;
      default:
        categoryBgColor = isDark ? AppDarkColors.surface : const Color(0xFFF1F5F9);
        categoryTextColor = isDark ? AppDarkColors.textSecondary : AppColors.textSecondary;
    }

    final cardWidget = Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppDarkColors.surface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? AppDarkColors.border : AppColors.border, width: 0.5),
        boxShadow: isDark ? null : [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: categoryBgColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      project.category.toUpperCase(),
                      style: TextStyle(
                        color: categoryTextColor,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                  if (project.isReadOnly) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDark ? AppDarkColors.border : AppColors.border,
                          width: 0.5,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.lock_outline,
                            size: 10,
                            color: isDark ? AppDarkColors.textSecondary : AppColors.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'READ-ONLY',
                            style: TextStyle(
                              color: isDark ? AppDarkColors.textSecondary : AppColors.textSecondary,
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
                // 3-dot Menu (Only for Manager)
                if (isManager)
                  PopupMenuButton<String>(
                    elevation: 3,
                    color: isDark ? AppDarkColors.surface : Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    onSelected: (value) async {
                      if (value == 'edit') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => EditProjectScreen(project: project),
                          ),
                        );
                      } else if (value == 'deactivate') {
                        await ref.read(projectListProvider.notifier).updateProjectStatus(project.id, false);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Proyek "${project.name}" dinonaktifkan'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      } else if (value == 'activate') {
                        await ref.read(projectListProvider.notifier).updateProjectStatus(project.id, true);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Proyek "${project.name}" diaktifkan kembali'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      } else if (value == 'delete') {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            backgroundColor: isDark ? AppDarkColors.surface : Colors.white,
                            title: Text(
                              'Hapus Proyek',
                              style: TextStyle(
                                color: isDark ? Colors.white : Colors.black,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            content: Text(
                              'Apakah Anda yakin ingin menghapus proyek "${project.name}" secara permanen?',
                              style: TextStyle(
                                color: isDark ? AppDarkColors.textSecondary : AppColors.textSecondary,
                              ),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text('Batal'),
                              ),
                              ElevatedButton(
                                onPressed: () => Navigator.pop(context, true),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.alertText,
                                  elevation: 0,
                                ),
                                child: const Text(
                                  'Hapus',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                            ],
                          ),
                        );

                        if (confirm == true) {
                          await ref.read(projectListProvider.notifier).deleteProject(project.id);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Proyek berhasil dihapus'),
                                backgroundColor: AppColors.success,
                              ),
                            );
                          }
                        }
                      }
                    },
                    icon: Icon(
                      Icons.more_vert,
                      color: isDark ? AppDarkColors.textSecondary : AppColors.textSecondary,
                      size: 20,
                    ),
                    itemBuilder: (context) => project.statusAktif
                        ? [
                            const PopupMenuItem(
                              value: 'edit',
                              child: Text('Edit Proyek'),
                            ),
                            const PopupMenuItem(
                              value: 'deactivate',
                              child: Text('Nonaktifkan Proyek'),
                            ),
                          ]
                        : [
                            const PopupMenuItem(
                              value: 'activate',
                              child: Text('Aktifkan Proyek'),
                            ),
                            const PopupMenuItem(
                              value: 'delete',
                              child: Text(
                                'Hapus Proyek',
                                style: TextStyle(color: AppColors.alertText, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              project.name,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? AppDarkColors.textMain : AppColors.textMain,
              ),
            ),
            
            // Team card: show description
            if (!isManager) ...[
              const SizedBox(height: 8),
              Text(
                project.description.isNotEmpty ? project.description : 'Tidak ada deskripsi proyek.',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? AppDarkColors.textSecondary : AppColors.textSecondary,
                  height: 1.4,
                ),
              ),
            ],

            const SizedBox(height: 20),
            Consumer(
              builder: (context, ref, child) {
                final progressAsync = ref.watch(projectRealProgressProvider(project.id));
                
                return progressAsync.when(
                  data: (realProgress) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Progress',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? AppDarkColors.textSecondary : AppColors.textSecondary,
                              ),
                            ),
                            Text(
                              '${(realProgress * 100).toInt()}%',
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? AppDarkColors.textMain : AppColors.textMain,
                                ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: realProgress,
                            backgroundColor: isDark ? AppDarkColors.border : const Color(0xFFE2E8F0),
                            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                            minHeight: 6,
                          ),
                        ),
                      ],
                    );
                  },
                  loading: () => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Progress',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? AppDarkColors.textSecondary : AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(
                            width: 12,
                            height: 12,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: 0,
                          backgroundColor: isDark ? AppDarkColors.border : const Color(0xFFE2E8F0),
                          valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                          minHeight: 6,
                        ),
                      ),
                    ],
                  ),
                  error: (e, st) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Progress',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? AppDarkColors.textSecondary : AppColors.textSecondary,
                            ),
                          ),
                          Text(
                            '${(project.progress * 100).toInt()}%',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: isDark ? AppDarkColors.textMain : AppColors.textMain,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: project.progress,
                          backgroundColor: isDark ? AppDarkColors.border : const Color(0xFFE2E8F0),
                          valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                          minHeight: 6,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Real project member avatars
                Consumer(
                  builder: (context, ref, child) {
                    final membersAsync = ref.watch(projectMembersProvider(project.id));
                    return membersAsync.when(
                      data: (membersList) {
                        if (membersList.isEmpty) return const SizedBox.shrink();
                        
                        final maxDisplay = 3;
                        final displayMembers = membersList.take(maxDisplay).toList();
                        final remainingCount = membersList.length - maxDisplay;

                        return Row(
                          children: [
                            ...displayMembers.asMap().entries.map((entry) {
                              final member = entry.value;
                              final avatarUrl = member['avatar_url'] as String? ?? '';
                              final name = member['nama'] as String? ?? '';
                              
                              return Align(
                                widthFactor: 0.6,
                                child: CircleAvatar(
                                  radius: 14,
                                  backgroundColor: isDark ? AppDarkColors.surface : Colors.white,
                                  child: CircleAvatar(
                                    radius: 12,
                                    backgroundColor: isDark ? AppDarkColors.background : AppColors.inputBackground,
                                    backgroundImage: avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null,
                                    child: avatarUrl.isEmpty
                                        ? Text(
                                            name.isNotEmpty ? name[0].toUpperCase() : 'A',
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              color: isDark ? AppDarkColors.textMain : AppColors.textMain,
                                            ),
                                          )
                                        : null,
                                  ),
                                ),
                              );
                            }),
                            if (remainingCount > 0)
                              Align(
                                widthFactor: 0.6,
                                child: CircleAvatar(
                                  radius: 14,
                                  backgroundColor: isDark ? AppDarkColors.surface : Colors.white,
                                  child: CircleAvatar(
                                    radius: 12,
                                    backgroundColor: isDark ? AppDarkColors.background : const Color(0xFFF1F5F9),
                                    child: Text(
                                      '+$remainingCount',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: isDark ? AppDarkColors.textSecondary : AppColors.textSecondary,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        );
                      },
                      loading: () => const SizedBox.shrink(),
                      error: (e, st) => const SizedBox.shrink(),
                    );
                  },
                ),
                // Date
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today_outlined,
                      size: 14,
                      color: isDark ? AppDarkColors.textSecondary : AppColors.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _formatIndonesianDate(project.createdAt ?? DateTime.now()),
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? AppDarkColors.textSecondary : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      );

      return GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProjectDetailScreen(project: project),
            ),
          );
        },
        child: project.isReadOnly
            ? Opacity(opacity: 0.8, child: cardWidget)
            : cardWidget,
      );
  }
}
