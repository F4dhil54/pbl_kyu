import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/theme_mode.dart';
import '../../data/models/task_model.dart';
import '../providers/task_provider.dart';

class TeamProgressScreen extends ConsumerStatefulWidget {
  final TaskModel task;
  const TeamProgressScreen({super.key, required this.task});

  @override
  ConsumerState<TeamProgressScreen> createState() => _TeamProgressScreenState();
}

class _TeamProgressScreenState extends ConsumerState<TeamProgressScreen> {
  String _activeFilter = 'Semua'; // 'Semua' | 'Hambatan' | 'Selesai'

  void _bukaTautan(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Tidak dapat membuka tautan: $url')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeControl.themeNotifier.value == ThemeMode.dark;
    final logsAsync = ref.watch(taskRepositoryProvider).getTaskProgressLogs(widget.task.id);

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
          'Progress Tim',
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
                Text(
                  widget.task.judulTugas,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : AppColors.textMain,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  widget.task.deskripsiTugas,
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

          // Filters Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                _buildFilterChip('Semua'),
                const SizedBox(width: 8),
                _buildFilterChip('Hambatan'),
                const SizedBox(width: 8),
                _buildFilterChip('Selesai'),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // Logs List
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: logsAsync,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Terjadi kesalahan saat memuat progress: ${snapshot.error}',
                      style: const TextStyle(color: Colors.red),
                    ),
                  );
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Text(
                      'Belum ada riwayat progress tim.',
                      style: TextStyle(
                        color: isDark ? AppDarkColors.textSecondary : AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  );
                }

                // Filter logs
                var logs = snapshot.data!;
                if (_activeFilter == 'Hambatan') {
                  logs = logs.where((l) => l['hambatan'] != null && (l['hambatan'] as String).isNotEmpty).toList();
                } else if (_activeFilter == 'Selesai') {
                  logs = logs.where((l) => l['status_progress'] == 'Selesai' || l['persen_selesai'] == 100).toList();
                }

                if (logs.isEmpty) {
                  return Center(
                    child: Text(
                      'Tidak ada progress untuk filter ini.',
                      style: TextStyle(
                        color: isDark ? AppDarkColors.textSecondary : AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  itemCount: logs.length,
                  itemBuilder: (context, index) {
                    final log = logs[index];
                    final profile = log['profiles'] as Map<String, dynamic>? ?? {};
                    final name = profile['nama'] ?? 'Anggota';
                    final email = profile['email'] ?? '';
                    final roleStr = profile['role'] ?? 'Tim';
                    final date = DateTime.tryParse(log['created_at'] as String? ?? '')?.toLocal();
                    final dateStr = date != null ? DateFormat('dd MMMM yyyy HH:mm').format(date) : '-';
                    final attachments = log['task_attachments'] as List<dynamic>? ?? [];
                    final hambatan = log['hambatan'] as String?;
                    final statusProgress = log['status_progress'] as String? ?? 'Sedang Dikerjakan';
                    final percent = log['persen_selesai'] ?? 0;

                    // Color code status progress
                    final Color statusColor = statusProgress == 'Selesai'
                        ? AppColors.successText
                        : (statusProgress == 'Sedang Dikerjakan' ? AppColors.warningText : AppColors.textSecondary);
                    final Color statusBg = statusProgress == 'Selesai'
                        ? AppColors.successBackground
                        : (statusProgress == 'Sedang Dikerjakan' ? AppColors.warningBackground : AppColors.offlineBackground);

                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark ? AppDarkColors.surface : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDark ? AppDarkColors.border : AppColors.border,
                          width: 0.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Top info: Member profile & Date
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              CircleAvatar(
                                radius: 18,
                                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                                child: Text(
                                  name.isNotEmpty ? name[0].toUpperCase() : 'U',
                                  style: const TextStyle(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      name,
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: isDark ? Colors.white : AppColors.textMain,
                                      ),
                                    ),
                                    Text(
                                      '$email • $roleStr',
                                      style: const TextStyle(fontSize: 10, color: Colors.grey),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: statusBg,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  statusProgress,
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    color: statusColor,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 12),
                          const Divider(height: 1),
                          const SizedBox(height: 12),

                          // Catatan update
                          Text(
                            log['catatan'] ?? '-',
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark ? Colors.white : AppColors.textMain,
                              height: 1.5,
                            ),
                          ),

                          const SizedBox(height: 8),

                          // Progress Percent
                          Row(
                            children: [
                              Expanded(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value: percent / 100,
                                    backgroundColor: isDark ? Colors.white10 : Colors.grey[200],
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      percent == 100 ? AppColors.successText : AppColors.primary,
                                    ),
                                    minHeight: 6,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                '$percent%',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : AppColors.textMain,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 12),

                          // Date text
                          Text(
                            'Disubmit pada: $dateStr',
                            style: const TextStyle(fontSize: 10, color: Colors.grey),
                          ),

                          // Obstacle / Hambatan (if present)
                          if (hambatan != null && hambatan.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF3F1B1B) : const Color(0xFFFEE2E2),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isDark ? const Color(0xFF7F1D1D) : const Color(0xFFFCA5A5),
                                  width: 0.5,
                                ),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(
                                    Icons.warning_amber_rounded,
                                    color: isDark ? const Color(0xFFF87171) : const Color(0xFFDC2626),
                                    size: 18,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Hambatan / Kendala',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: isDark ? const Color(0xFFFCE7F3) : const Color(0xFF991B1B),
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          hambatan,
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: isDark ? const Color(0xFFFECACA) : const Color(0xFFB91C1C),
                                            height: 1.4,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],

                          // Attachments (if present)
                          if (attachments.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            const Text(
                              'Lampiran:',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey),
                            ),
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: attachments.map<Widget>((att) {
                                final tipe = att['tipe_lampiran'] ?? 'file';
                                final IconData icon = tipe == 'foto'
                                    ? Icons.camera_alt_outlined
                                    : (tipe == 'file' ? Icons.file_present_outlined : Icons.link);

                                return ActionChip(
                                  avatar: Icon(icon, size: 12, color: AppColors.primary),
                                  label: Text(
                                    att['nama_file'] ?? 'Lampiran',
                                    style: const TextStyle(fontSize: 10),
                                  ),
                                  onPressed: () => _bukaTautan(att['file_path_or_url'] ?? ''),
                                );
                              }).toList(),
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String filterName) {
    final isDark = ThemeControl.themeNotifier.value == ThemeMode.dark;
    final isSelected = _activeFilter == filterName;

    return ChoiceChip(
      label: Text(
        filterName,
        style: TextStyle(
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected
              ? Colors.white
              : (isDark ? AppDarkColors.textSecondary : AppColors.textSecondary),
        ),
      ),
      selected: isSelected,
      selectedColor: AppColors.primary,
      backgroundColor: isDark ? AppDarkColors.surface : Colors.grey[200],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSelected ? Colors.transparent : (isDark ? AppDarkColors.border : Colors.grey[300]!),
          width: 0.5,
        ),
      ),
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _activeFilter = filterName;
          });
        }
      },
    );
  }
}
