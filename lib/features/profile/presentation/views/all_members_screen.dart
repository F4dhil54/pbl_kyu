import 'package:flutter/material.dart';
import '../../../../core/theme/colors.dart';
import 'edit_member_screen.dart';

class AllMembersScreen extends StatelessWidget {
  const AllMembersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textMain),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Semua Anggota Tim',
          style: TextStyle(
            color: AppColors.textMain,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: AppColors.textMain),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Fitur pencarian akan segera hadir!'), duration: Duration(seconds: 2)),
              );
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildMemberItem(context, 'Fadhil Syahidan', 'Lead Designer', 'Aktif', AppColors.successText, AppColors.successBackground),
          const Divider(height: 32, color: AppColors.border),
          _buildMemberItem(context, 'Dea Marselia', 'Frontend Dev', 'Sedang Rapat', AppColors.warningText, AppColors.warningBackground),
          const Divider(height: 32, color: AppColors.border),
          _buildMemberItem(context, 'Sukma Ananda', 'DevOps Engineer', 'Offline', AppColors.offlineText, AppColors.offlineBackground),
          const Divider(height: 32, color: AppColors.border),
          _buildMemberItem(context, 'Budi Santoso', 'Backend Developer', 'Aktif', AppColors.successText, AppColors.successBackground),
          const Divider(height: 32, color: AppColors.border),
          _buildMemberItem(context, 'Siti Aminah', 'QA Tester', 'Cuti', AppColors.alertText, const Color(0xFFFEE2E2)),
        ],
      ),
    );
  }

  Widget _buildMemberItem(BuildContext context, String name, String role, String status, Color statusColor, Color statusBg) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const EditMemberScreen()),
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
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textMain),
                ),
                const SizedBox(height: 4),
                Text(
                  role,
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
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
