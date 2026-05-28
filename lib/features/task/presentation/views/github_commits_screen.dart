import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/theme_mode.dart';
import '../../data/models/task_model.dart';
import '../providers/task_provider.dart';

class GithubCommitsScreen extends ConsumerStatefulWidget {
  final TaskModel task;
  const GithubCommitsScreen({super.key, required this.task});

  @override
  ConsumerState<GithubCommitsScreen> createState() => _GithubCommitsScreenState();
}

class _GithubCommitsScreenState extends ConsumerState<GithubCommitsScreen> {
  void _salinSha(String sha) {
    Clipboard.setData(ClipboardData(text: sha));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('SHA Commit berhasil disalin!'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeControl.themeNotifier.value == ThemeMode.dark;
    final commitsFuture = ref.watch(taskRepositoryProvider).getTaskCommits(widget.task.id);

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
          'Riwayat Commit GitHub',
          style: TextStyle(
            color: isDark ? Colors.white : AppColors.textMain,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Task Summary
          Container(
            width: double.infinity,
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? AppDarkColors.surface : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? AppDarkColors.border : AppColors.border,
                width: 0.5,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isDark ? AppDarkColors.border : Colors.grey[200],
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        widget.task.taskNumber != null ? '#${widget.task.taskNumber}' : '#-',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white70 : Colors.black87,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.task.judulTugas,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : AppColors.textMain,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  widget.task.deskripsiTugas.isNotEmpty ? widget.task.deskripsiTugas : 'Tidak ada deskripsi tugas.',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? AppDarkColors.textSecondary : AppColors.textSecondary,
                    height: 1.4,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // Commits List
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: commitsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Terjadi kesalahan saat memuat commit: ${snapshot.error}',
                      style: const TextStyle(color: Colors.red),
                    ),
                  );
                }
                final commits = snapshot.data;
                if (commits == null || commits.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.commit, size: 48, color: isDark ? Colors.white24 : Colors.grey[300]),
                          const SizedBox(height: 16),
                          Text(
                            'Belum ada commit GitHub yang terhubung dengan tugas ini.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: isDark ? AppDarkColors.textSecondary : AppColors.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    setState(() {});
                    await Future.delayed(const Duration(milliseconds: 500));
                  },
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    itemCount: commits.length,
                    separatorBuilder: (context, index) => Divider(
                      height: 24,
                      color: isDark ? AppDarkColors.border : AppColors.border,
                      thickness: 0.5,
                    ),
                    itemBuilder: (context, index) {
                      final commit = commits[index];
                      final profile = commit['profiles'] as Map<String, dynamic>? ?? {};
                      final name = profile['nama'] ?? 'Anggota';
                      final email = profile['email'] ?? '';
                      final avatarUrl = profile['avatar_url'] as String?;
                      
                      final sha = commit['commit_sha'] as String? ?? '';
                      final shortSha = sha.length > 7 ? sha.substring(0, 7) : sha;
                      final message = commit['message'] as String? ?? '';
                      
                      final dateVal = DateTime.tryParse(commit['created_at'] as String? ?? '')?.toLocal();
                      final dateStr = dateVal != null ? DateFormat('dd MMMM yyyy, HH:mm').format(dateVal) : '-';

                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            radius: 18,
                            backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                            backgroundImage: avatarUrl != null && avatarUrl.isNotEmpty
                                ? NetworkImage(avatarUrl)
                                : null,
                            child: avatarUrl == null || avatarUrl.isEmpty
                                ? Text(
                                    name.isNotEmpty ? name[0].toUpperCase() : 'U',
                                    style: const TextStyle(
                                      color: AppColors.primary,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  )
                                : null,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        name,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                          color: isDark ? Colors.white : Colors.black,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    GestureDetector(
                                      onTap: () => _salinSha(sha),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: isDark ? AppDarkColors.surface : Colors.grey[200],
                                          borderRadius: BorderRadius.circular(4),
                                          border: Border.all(
                                            color: isDark ? AppDarkColors.border : Colors.grey[300]!,
                                            width: 0.5,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              shortSha,
                                              style: TextStyle(
                                                fontFamily: 'monospace',
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                                color: isDark ? Colors.white70 : Colors.black87,
                                              ),
                                            ),
                                            const SizedBox(width: 4),
                                            Icon(
                                              Icons.copy_rounded,
                                              size: 10,
                                              color: isDark ? Colors.white38 : Colors.grey[600],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                if (email.isNotEmpty)
                                  Text(
                                    email,
                                    style: const TextStyle(fontSize: 10, color: Colors.grey),
                                  ),
                                const SizedBox(height: 6),
                                Text(
                                  message,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDark ? Colors.white70 : Colors.black87,
                                    height: 1.4,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  dateStr,
                                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
