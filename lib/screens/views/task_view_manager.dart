import 'package:flutter/material.dart';
import '../../theme/colors.dart';

class TaskViewManager extends StatelessWidget {
  const TaskViewManager({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text(
          'KYU',
          style: TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.account_circle, color: AppColors.textSecondary, size: 32),
            onPressed: () {},
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'OPERATIONAL OVERVIEW',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: AppColors.textMain,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Delegation Control',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.textMain,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.inputBackground),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppColors.success,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    '12 Active Sprints',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            // Do First
            _buildQuadrantCard(
              'Do First',
              'Urgent',
              [
                _buildTaskItem('Finalize Client Proposal', 'Due in 2 hours • Assigned to Siska'),
                _buildTaskItem('Server Migration Audit', 'High Risk • Assigned to Alex'),
              ],
            ),
            const SizedBox(height: 16),

            // Schedule
            _buildQuadrantCard(
              'Schedule',
              'IMPORTANT',
              [
                _buildTaskItem('Server Migration Audit', 'High Risk • Assigned to Alex'),
              ],
            ),
            const SizedBox(height: 16),

            // Delegate
            _buildQuadrantCard(
              'Delegate',
              'TRIVIAL',
              [
                _buildTaskItem('Q4 Strategy Deck', 'Next Week • Assigned to Intern'),
              ],
            ),
            const SizedBox(height: 16),

            // Eliminate
            _buildQuadrantCard(
              'Eliminate',
              'LOW PRIO',
              [
                const Padding(
                  padding: EdgeInsets.only(top: 16.0),
                  child: Text(
                    'Clear Quadrant. Focus Remains Sharp.',
                    style: TextStyle(
                      fontStyle: FontStyle.italic,
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Execution Velocity
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Execution Velocity',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildVelocityItem('Fadhil Syahidan', 'SENIOR ARCHITECT', 80, AppColors.primary),
                  const SizedBox(height: 16),
                  _buildVelocityItem('Sukma Ananda', 'DEVOPS LEAD', 45, AppColors.primary),
                  const SizedBox(height: 16),
                  _buildVelocityItem('Dea Marselia', 'UI DESIGNER', 92, AppColors.success),
                  const SizedBox(height: 24),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: AppColors.inputBackground,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(
                      child: Text(
                        'View Detailed Report',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 100), // spacing for FAB
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildQuadrantCard(String title, String tag, List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.only(
          topRight: Radius.circular(16),
          bottomRight: Radius.circular(16),
          bottomLeft: Radius.circular(16),
        ),
        border: const Border(
          left: BorderSide(color: Colors.black, width: 4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.inputBackground),
                ),
                child: Text(
                  tag,
                  style: const TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          ...children,
        ],
      ),
    );
  }

  Widget _buildTaskItem(String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.only(top: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 10,
              color: AppColors.textMain,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVelocityItem(String name, String role, int percent, Color color) {
    return Row(
      children: [
        const CircleAvatar(
          radius: 20,
          backgroundColor: AppColors.inputBackground,
          child: Icon(Icons.person_outline, color: AppColors.textMain),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              Text(
                role,
                style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 8),
              Stack(
                children: [
                  Container(
                    height: 2,
                    width: double.infinity,
                    color: AppColors.inputBackground,
                  ),
                  Container(
                    height: 2,
                    width: (percent / 100) * 200, // approximation
                    color: color,
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Text(
          '$percent%',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ],
    );
  }
}
