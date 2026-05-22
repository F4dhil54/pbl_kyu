import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/theme_mode.dart';
import '../../../profile/presentation/views/profile_view_manager.dart';
import '../../../task/presentation/views/create_task_screen.dart';
import '../../data/models/project_model.dart';
import '../providers/project_provider.dart';
import 'edit_project_screen.dart';

class ProjectDetailScreen extends ConsumerStatefulWidget {
  final ProjectModel project;

  const ProjectDetailScreen({super.key, required this.project});

  @override
  ConsumerState<ProjectDetailScreen> createState() => _ProjectDetailScreenState();
}

class _ProjectDetailScreenState extends ConsumerState<ProjectDetailScreen> {
  String _selectedTab = 'Semua';

  void _showDeleteConfirmation(BuildContext context, ProjectModel project) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 28),
              const SizedBox(width: 12),
              const Text('Hapus Proyek'),
            ],
          ),
          content: Text(
            'Apakah Anda yakin ingin menghapus proyek "${project.name}"?\n\nTindakan ini tidak dapat dibatalkan.',
            style: const TextStyle(fontSize: 14, height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Batal', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(dialogContext); // Tutup dialog
                
                try {
                  await ref.read(projectListProvider.notifier).deleteProject(project.id);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Proyek berhasil dihapus!'),
                        backgroundColor: AppColors.successText,
                      ),
                    );
                    Navigator.pop(context); // Kembali ke list proyek
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Gagal menghapus proyek: $e'),
                        backgroundColor: AppColors.alertText,
                      ),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFB91C1C),
                elevation: 0,
              ),
              child: const Text('Hapus', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Watch list provider and find current project to dynamically update detail screen upon edit
    final projectsAsync = ref.watch(projectListProvider);
    final project = projectsAsync.whenOrNull(
          data: (list) => list.firstWhere(
            (element) => element.id == widget.project.id,
            orElse: () => widget.project,
          ),
        ) ??
        widget.project;

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
          body: SingleChildScrollView(
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
                      'Daftar Tugas',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: isDark ? AppDarkColors.textMain : AppColors.textMain,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Top Info Cards
                Row(
                  children: [
                    Expanded(
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
                            Text(
                              'MANAJER',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: isDark ? AppDarkColors.textSecondary : AppColors.textSecondary,
                                letterSpacing: 1,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                const CircleAvatar(
                                  radius: 12,
                                  backgroundColor: Colors.transparent,
                                  child: Icon(
                                    Icons.account_circle,
                                    color: Colors.deepOrange,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Fadhil Syahidan',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: isDark ? AppDarkColors.textMain : AppColors.textMain,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
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
                            Text(
                              'LABEL',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: isDark ? AppDarkColors.textSecondary : AppColors.textSecondary,
                                letterSpacing: 1,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              project.labels.isNotEmpty ? project.labels.join(', ') : 'Tanpa Label',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.blue[300] : const Color(0xFF1E3A8A), 
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Description Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? AppDarkColors.surface : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: isDark ? AppDarkColors.border : AppColors.border, width: 0.5),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'DESKRIPSI PROYEK',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: isDark ? AppDarkColors.textSecondary : AppColors.textSecondary,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        project.description.isNotEmpty ? project.description : 'Tidak ada deskripsi.',
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? AppDarkColors.textMain : AppColors.textMain,
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

                // Tabs
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildTab('Semua', isDark: isDark),
                      const SizedBox(width: 8),
                      _buildTab('Do', isDark: isDark),
                      const SizedBox(width: 8),
                      _buildTab('Schedule', isDark: isDark),
                      const SizedBox(width: 8),
                      _buildTab('Delegate', isDark: isDark),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Dynamic Task List Mock/Real
                _buildTaskCard(
                  context,
                  type: 'Do',
                  title: 'Implementasi authentication layer',
                  description:
                      'Mohon fokus pada optimasi authentication layer di dalam middleware. Implementasi saat ini menyebabkan penundaan 200ms pada setiap request.',
                  date: project.date,
                  isDark: isDark,
                ),
                const SizedBox(height: 16),
                _buildTaskCard(
                  context,
                  type: 'Delegate',
                  typeColor: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF94A3B8),
                  title: 'Migrasi Schema Database',
                  description:
                      'Sesuaikan model tabel supabase dengan local state repository di Flutter.',
                  date: project.date,
                  isDark: isDark,
                ),
                const SizedBox(height: 32),

                // Edit & Hapus Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => EditProjectScreen(project: project),
                            ),
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: isDark ? AppDarkColors.border : AppColors.border),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: Text(
                          'Edit',
                          style: TextStyle(
                            color: isDark ? AppDarkColors.textMain : AppColors.textMain,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _showDeleteConfirmation(context, project),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFB91C1C),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Hapus',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 80),
              ],
            ),
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const CreateTaskScreen()),
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

  Widget _buildTab(String label, {required bool isDark}) {
    final bool isSelected = _selectedTab == label;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTab = label;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? AppColors.primary : const Color(0xFF020617))
              : (isDark ? AppDarkColors.background : Colors.white),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected ? Colors.transparent : (isDark ? AppDarkColors.border : AppColors.border),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: isSelected ? Colors.white : (isDark ? AppDarkColors.textSecondary : AppColors.textSecondary),
          ),
        ),
      ),
    );
  }

  Widget _buildTaskCard(
    BuildContext context, {
    required String type,
    Color typeColor = const Color(0xFF64748B),
    required String title,
    required String description,
    required String date,
    required bool isDark,
  }) {
    // Only display if tab is "Semua" or matches type
    if (_selectedTab != 'Semua' && _selectedTab.toLowerCase() != type.toLowerCase()) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(24),
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
              Row(
                children: [
                  Icon(
                    Icons.description_outlined,
                    size: 20,
                    color: isDark ? AppDarkColors.textMain : AppColors.textMain,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Tugas',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDark ? AppDarkColors.textMain : AppColors.textMain,
                    ),
                  ),
                ],
              ),
              Text(
                type,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: typeColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            title,
            style: TextStyle(fontSize: 14, color: isDark ? AppDarkColors.textMain : AppColors.textMain, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Text(
            description,
            style: TextStyle(
              fontSize: 14,
              color: isDark ? AppDarkColors.textSecondary : AppColors.textMain,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Tenggat waktu: $date',
            style: TextStyle(
              fontSize: 14,
              color: isDark ? AppDarkColors.textSecondary : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}