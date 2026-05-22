import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/theme_mode.dart';
import '../../../profile/presentation/views/profile_view_manager.dart';
import '../../data/models/project_model.dart';
import '../providers/project_provider.dart';
import 'create_project_screen.dart';
import 'project_detail_screen.dart';

class ProjectListScreen extends ConsumerStatefulWidget {
  const ProjectListScreen({super.key});

  @override
  ConsumerState<ProjectListScreen> createState() => _ProjectListScreenState();
}

class _ProjectListScreenState extends ConsumerState<ProjectListScreen> {
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final projectsState = ref.watch(projectListProvider);
    final searchQuery = ref.watch(projectSearchQueryProvider);

    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeControl.themeNotifier,
      builder: (context, currentMode, child) {
        bool isDark = currentMode == ThemeMode.dark;

        return Scaffold(
          backgroundColor: isDark ? AppDarkColors.background : AppColors.background,
          appBar: AppBar(
            backgroundColor: isDark ? AppDarkColors.background : AppColors.background,
            elevation: 0,
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
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ProfileViewManager(),
                    ),
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
                      size: 24,
                    ),
                  ),
                ),
              ),
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
                // Filter projects by search query
                final filteredProjects = projects.where((project) {
                  final nameLower = project.name.toLowerCase();
                  final descLower = project.description.toLowerCase();
                  final searchLower = searchQuery.toLowerCase();
                  return nameLower.contains(searchLower) || descLower.contains(searchLower);
                }).toList();

                if (filteredProjects.isEmpty) {
                  return Center(
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
                              : 'Belum ada proyek aktif',
                          style: TextStyle(
                            fontSize: 16,
                            color: isDark ? AppDarkColors.textSecondary : AppColors.textSecondary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Proyek Aktif',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: isDark ? AppDarkColors.textMain : AppColors.textMain,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Pantau progres dan kolaborasi tim pada ${filteredProjects.length} proyek aktif Anda.',
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark ? AppDarkColors.textSecondary : AppColors.textSecondary,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 24),
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
                          );
                        },
                      ),
                      const SizedBox(height: 80),
                    ],
                  ),
                );
              },
            ),
          ),
          floatingActionButton: FloatingActionButton(
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
          ),
        );
      },
    );
  }

  Widget _buildProjectCard(
    BuildContext context, {
    required ProjectModel project,
    required bool isDark,
  }) {
    // Map category to styles dynamically
    Color categoryBgColor;
    Color categoryTextColor;

    switch (project.category.toUpperCase()) {
      case 'MARKETING':
        categoryBgColor = isDark ? const Color(0xFF065F46).withOpacity(0.3) : const Color(0xFFD1FAE5);
        categoryTextColor = isDark ? const Color(0xFF34D399) : const Color(0xFF065F46);
        break;
      case 'IT INFRA':
      case 'IT':
        categoryBgColor = isDark ? const Color(0xFF1E3A8A).withOpacity(0.4) : const Color(0xFFDBEAFE);
        categoryTextColor = isDark ? Colors.blue[200]! : const Color(0xFF1E3A8A);
        break;
      case 'FINANCE':
        categoryBgColor = isDark ? const Color(0xFF451A03).withOpacity(0.4) : const Color(0xFFFEF3C7);
        categoryTextColor = isDark ? Colors.orange[300]! : const Color(0xFF92400E);
        break;
      case 'OPERATIONS':
        categoryBgColor = isDark ? const Color(0xFF78350F).withOpacity(0.4) : const Color(0xFFFEE2E2);
        categoryTextColor = isDark ? Colors.red[300]! : const Color(0xFF991B1B);
        break;
      default:
        categoryBgColor = isDark ? AppDarkColors.surface : const Color(0xFFF1F5F9);
        categoryTextColor = isDark ? AppDarkColors.textSecondary : AppColors.textSecondary;
    }

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProjectDetailScreen(project: project),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? AppDarkColors.surface : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isDark ? AppDarkColors.border : AppColors.border, width: 0.5),
          boxShadow: isDark ? null : [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
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
                    project.category,
                    style: TextStyle(
                      color: categoryTextColor,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                ),
                Icon(
                  Icons.more_vert,
                  color: isDark ? AppDarkColors.textSecondary : AppColors.textSecondary,
                  size: 20,
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
            const SizedBox(height: 20),
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
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Fallback project member avatars based on project name length
                Row(
                  children: [
                    for (int i = 0; i < (project.name.length % 3 + 1); i++)
                      Align(
                        widthFactor: 0.6,
                        child: CircleAvatar(
                          radius: 14,
                          backgroundColor: isDark ? AppDarkColors.surface : Colors.white,
                          child: CircleAvatar(
                            radius: 12,
                            backgroundColor: isDark ? AppDarkColors.background : AppColors.inputBackground,
                            child: Icon(
                              Icons.account_circle,
                              size: 24,
                              color: _getFallbackColor(i),
                            ),
                          ),
                        ),
                      ),
                    if (project.name.length > 15)
                      Align(
                        widthFactor: 0.6,
                        child: CircleAvatar(
                          radius: 14,
                          backgroundColor: isDark ? AppDarkColors.surface : Colors.white,
                          child: CircleAvatar(
                            radius: 12,
                            backgroundColor: isDark ? AppDarkColors.background : const Color(0xFFF1F5F9),
                            child: Text(
                              '+${project.name.length % 5 + 1}',
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
                      project.date,
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
      ),
    );
  }

  Color _getFallbackColor(int index) {
    List<Color> colors = [
      Colors.orange,
      Colors.pink,
      Colors.blueGrey,
      Colors.amber,
      Colors.blue,
      Colors.red,
      Colors.green,
    ];
    return colors[index % colors.length];
  }
}