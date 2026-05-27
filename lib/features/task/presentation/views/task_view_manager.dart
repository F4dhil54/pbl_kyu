import 'package:flutter/material.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/theme_mode.dart'; // Import ThemeControl untuk sinkronisasi mode malam

class TaskViewManager extends StatelessWidget {
  const TaskViewManager({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeControl.themeNotifier,
      builder: (context, currentMode, child) {
        bool isDark = currentMode == ThemeMode.dark;

        return Scaffold(
          backgroundColor: isDark ? AppDarkColors.background : AppColors.background,
          appBar: AppBar(
            backgroundColor: isDark ? AppDarkColors.background : AppColors.background,
            elevation: 0,
            title: Text(
              'KYU',
              style: TextStyle(
                color: isDark ? Colors.white : AppColors.primary,
                fontWeight: FontWeight.bold,
                fontSize: 24,
              ),
            ),
            actions: [
              IconButton(
                icon: Icon(
                  Icons.account_circle, 
                  color: isDark ? AppDarkColors.textSecondary : AppColors.textSecondary, 
                  size: 32,
                ),
                onPressed: () {},
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: () async {
              await Future.delayed(const Duration(milliseconds: 500));
            },
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'OPERATIONAL OVERVIEW',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppDarkColors.textSecondary : AppColors.textMain,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Delegation Control',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppDarkColors.textMain : AppColors.textMain,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isDark ? AppDarkColors.surface : AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: isDark ? AppDarkColors.border : AppColors.inputBackground),
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
                      Text(
                        '12 Active Sprints',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: isDark ? AppDarkColors.textMain : AppColors.textMain,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                
                // Do First Quadrant
                _buildQuadrantCard(
                  isDark,
                  'Do First',
                  'Urgent',
                  [
                    _buildTaskItem(isDark, 'Finalize Client Proposal', 'Due in 2 hours • Assigned to Siska'),
                    _buildTaskItem(isDark, 'Server Migration Audit', 'High Risk • Assigned to Alex'),
                  ],
                ),
                const SizedBox(height: 16),

                // Schedule Quadrant
                _buildQuadrantCard(
                  isDark,
                  'Schedule',
                  'IMPORTANT',
                  [
                    _buildTaskItem(isDark, 'Server Migration Audit', 'High Risk • Assigned to Alex'),
                  ],
                ),
                const SizedBox(height: 16),

                // Delegate Quadrant
                _buildQuadrantCard(
                  isDark,
                  'Delegate',
                  'TRIVIAL',
                  [
                    _buildTaskItem(isDark, 'Q4 Strategy Deck', 'Next Week • Assigned to Intern'),
                  ],
                ),
                const SizedBox(height: 16),

                // Eliminate Quadrant
                _buildQuadrantCard(
                  isDark,
                  'Eliminate',
                  'LOW PRIO',
                  [
                    Padding(
                      padding: const EdgeInsets.only(top: 16.0),
                      child: Text(
                        'Clear Quadrant. Focus Remains Sharp.',
                        style: TextStyle(
                          fontStyle: FontStyle.italic,
                          fontSize: 12,
                          color: isDark ? AppDarkColors.textSecondary : AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // Execution Velocity Section
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: isDark ? AppDarkColors.surface : AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: isDark ? AppDarkColors.border : Colors.transparent, width: 0.5),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Execution Velocity',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isDark ? AppDarkColors.textMain : AppColors.textMain,
                        ),
                      ),
                      const SizedBox(height: 20),
                      _buildVelocityItem(isDark, 'Fadhil Syahidan', 'SENIOR ARCHITECT', 80, AppColors.primary),
                      const SizedBox(height: 16),
                      _buildVelocityItem(isDark, 'Sukma Ananda', 'DEVOPS LEAD', 45, AppColors.primary),
                      const SizedBox(height: 16),
                      _buildVelocityItem(isDark, 'Dea Marselia', 'UI DESIGNER', 92, AppColors.success),
                      const SizedBox(height: 24),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: isDark ? AppDarkColors.background : AppColors.inputBackground,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: isDark ? AppDarkColors.border : AppColors.border, width: 0.5),
                        ),
                        child: Center(
                          child: Text(
                            'View Detailed Report',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: isDark ? AppDarkColors.textMain : AppColors.textMain,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 100), // Spacing for FAB
              ],
            ),
          ),
          ),
          floatingActionButton: FloatingActionButton(
            heroTag: 'task_view_manager_fab',
            onPressed: () {},
            backgroundColor: AppColors.primary,
            child: const Icon(Icons.add, color: Colors.white),
          ),
        );
      },
    );
  }

  Widget _buildQuadrantCard(bool isDark, String title, String tag, List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppDarkColors.surface : AppColors.surface,
        borderRadius: const BorderRadius.only(
          topRight: Radius.circular(16),
          bottomRight: Radius.circular(16),
          bottomLeft: Radius.circular(16),
        ),
        border: Border(
          left: BorderSide(color: isDark ? Colors.white : Colors.black, width: 4),
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
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppDarkColors.textMain : AppColors.textMain,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isDark ? AppDarkColors.background : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: isDark ? AppDarkColors.border : AppColors.inputBackground),
                ),
                child: Text(
                  tag,
                  style: TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppDarkColors.textSecondary : AppColors.textSecondary,
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

  Widget _buildTaskItem(bool isDark, String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.only(top: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: isDark ? AppDarkColors.textMain : AppColors.textMain,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 10,
              color: isDark ? AppDarkColors.textSecondary : AppColors.textMain,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVelocityItem(bool isDark, String name, String role, int percent, Color color) {
    return Row(
      children: [
        CircleAvatar(
          radius: 20,
          backgroundColor: isDark ? AppDarkColors.background : AppColors.inputBackground,
          child: Icon(Icons.person_outline, color: isDark ? AppDarkColors.textMain : AppColors.textMain),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: TextStyle(
                  fontWeight: FontWeight.bold, 
                  fontSize: 14,
                  color: isDark ? AppDarkColors.textMain : AppColors.textMain,
                ),
              ),
              Text(
                role,
                style: TextStyle(
                  fontSize: 10, 
                  color: isDark ? AppDarkColors.textSecondary : AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              Stack(
                children: [
                  Container(
                    height: 2,
                    width: double.infinity,
                    color: isDark ? AppDarkColors.background : AppColors.inputBackground,
                  ),
                  FractionallySizedBox(
                    widthFactor: percent / 100,
                    child: Container(
                      height: 2,
                      color: color,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Text(
          '$percent%',
          style: TextStyle(
            fontWeight: FontWeight.bold, 
            fontSize: 16,
            color: isDark ? AppDarkColors.textMain : AppColors.textMain,
          ),
        ),
      ],
    );
  }
}
