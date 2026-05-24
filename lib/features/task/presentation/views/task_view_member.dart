import 'package:flutter/material.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/theme_mode.dart'; // Pastikan path import ini sesuai dengan struktur projek Anda

class TaskViewMember extends StatelessWidget {
  const TaskViewMember({super.key});

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
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'CURRENT FOCUS',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.blueAccent : AppColors.primary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Aether Workstream',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppDarkColors.textMain : AppColors.textMain,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Engineering next generation of fluid\ninterfaces. Active progress tracked via\nGithub CI/CD.',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? AppDarkColors.textSecondary : AppColors.textMain,
                  ),
                ),
                const SizedBox(height: 24),
                
                // Row Completion & Task
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: isDark ? AppDarkColors.surface : AppColors.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: isDark ? AppDarkColors.border : Colors.transparent, width: 0.5),
                        ),
                        child: Column(
                          children: [
                            Text(
                              'COMPLETION', 
                              style: TextStyle(fontSize: 10, color: isDark ? AppDarkColors.textSecondary : AppColors.textSecondary),
                            ),
                            const SizedBox(height: 4),
                            const Text('82%', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.success)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: isDark ? AppDarkColors.surface : AppColors.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: isDark ? AppDarkColors.border : Colors.transparent, width: 0.5),
                        ),
                        child: Column(
                          children: [
                            Text(
                              'TASK', 
                              style: TextStyle(fontSize: 10, color: isDark ? AppDarkColors.textSecondary : AppColors.textSecondary),
                            ),
                            const SizedBox(height: 4),
                            Text('12', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? Colors.blueAccent : AppColors.primary)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // In Progress Card
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
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppColors.success, shape: BoxShape.circle)),
                              const SizedBox(width: 8),
                              const Text('IN PROGRESS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.success)),
                            ],
                          ),
                          Row(
                            children: [
                              Icon(Icons.access_time, size: 12, color: isDark ? AppDarkColors.textSecondary : AppColors.textSecondary),
                              const SizedBox(width: 4),
                              Text('Due in 2 days', style: TextStyle(fontSize: 10, color: isDark ? AppDarkColors.textSecondary : AppColors.textSecondary)),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Refactor Neural-UI Core\nModules',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isDark ? AppDarkColors.textMain : AppColors.textMain,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Implementing the asynchronous\nstate management for the Aether\narchitecture. Ensuring zero-latency\nrendering for complex bento-grid\nlayouts.',
                        style: TextStyle(fontSize: 12, color: isDark ? AppDarkColors.textSecondary : AppColors.textMain),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          ElevatedButton(
                            onPressed: () {},
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              elevation: 0,
                            ),
                            child: const Text('Update Status', style: TextStyle(color: Colors.white, fontSize: 12)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: isDark ? AppDarkColors.background : AppColors.inputBackground,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: isDark ? AppDarkColors.border : Colors.transparent, width: 0.5),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.auto_awesome, color: isDark ? Colors.blueAccent : AppColors.primary, size: 16),
                            const SizedBox(width: 8),
                            Text(
                              'Gemini AI Help', 
                              style: TextStyle(color: isDark ? Colors.blueAccent : AppColors.primary, fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: isDark ? AppDarkColors.background : AppColors.inputBackground,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: isDark ? AppDarkColors.border : Colors.transparent, width: 0.5),
                          ),
                          child: Text(
                            'git: feature/neural-ui', 
                            style: TextStyle(fontSize: 10, color: isDark ? AppDarkColors.textSecondary : AppColors.textSecondary),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Backlog Card
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
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(width: 8, height: 8, decoration: BoxDecoration(color: isDark ? AppDarkColors.textSecondary : AppColors.textSecondary, shape: BoxShape.circle)),
                              const SizedBox(width: 8),
                              Text('BACKLOG', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isDark ? AppDarkColors.textSecondary : AppColors.textSecondary)),
                            ],
                          ),
                          Text('Next Sprint', style: TextStyle(fontSize: 10, color: isDark ? AppDarkColors.textSecondary : AppColors.textSecondary)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'CI/CD Pipeline\nOptimization',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark ? AppDarkColors.textMain : AppColors.textMain,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Text(
                            'View Technical Requirements', 
                            style: TextStyle(color: isDark ? Colors.blueAccent : AppColors.primary, fontSize: 12),
                          ),
                          Icon(Icons.arrow_drop_down, color: isDark ? Colors.blueAccent : AppColors.primary),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: isDark ? AppDarkColors.background : AppColors.inputBackground,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: isDark ? AppDarkColors.border : Colors.transparent, width: 0.5),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.auto_awesome, color: isDark ? Colors.blueAccent : AppColors.primary, size: 16),
                            const SizedBox(width: 8),
                            Text(
                              'Analyze with Gemini', 
                              style: TextStyle(color: isDark ? Colors.blueAccent : AppColors.primary, fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Assign to me', 
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: isDark ? AppDarkColors.textMain : AppColors.textMain),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Recent Commits Card
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
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Recent Commits', 
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: isDark ? AppDarkColors.textMain : AppColors.textMain),
                          ),
                          Icon(Icons.history, size: 20, color: isDark ? AppDarkColors.textMain : AppColors.textMain),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.commit, size: 16, color: isDark ? AppDarkColors.textMain : AppColors.textMain),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Refactor: navigation logic', 
                                  style: TextStyle(fontSize: 12, color: isDark ? AppDarkColors.textMain : AppColors.textMain),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Text(
                                      'sha: a7f82b1', 
                                      style: TextStyle(fontSize: 10, color: isDark ? AppDarkColors.textSecondary : AppColors.textSecondary),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      width: 4, 
                                      height: 4, 
                                      decoration: BoxDecoration(color: isDark ? AppDarkColors.textSecondary : AppColors.inputBackground, shape: BoxShape.circle),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      '2h ago', 
                                      style: TextStyle(fontSize: 10, color: isDark ? AppDarkColors.textSecondary : AppColors.textSecondary),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(width: 16), // align with text above
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Build: production passed', 
                                  style: TextStyle(fontSize: 12, color: isDark ? AppDarkColors.textMain : AppColors.textMain),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Text(
                                      'workflow: main-ci', 
                                      style: TextStyle(fontSize: 10, color: isDark ? AppDarkColors.textSecondary : AppColors.textSecondary),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      width: 4, 
                                      height: 4, 
                                      decoration: BoxDecoration(color: isDark ? AppDarkColors.textSecondary : AppColors.inputBackground, shape: BoxShape.circle),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      '5h ago', 
                                      style: TextStyle(fontSize: 10, color: isDark ? AppDarkColors.textSecondary : AppColors.textSecondary),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Workstream Optimization Card (Tetap berwarna biru terang agar mencolok sebagai AI Highlight)
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Workstream Optimization', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                      const SizedBox(height: 8),
                      const Text(
                        'Gemini suggests focusing on "Neural-UI Core"\ntoday to meet the sprint deadline. 3 sub-tasks\nare ready for merge.',
                        style: TextStyle(color: Colors.white, fontSize: 10),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Center(
                          child: Text('Apply AI Strategy', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 12)),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Sync Team Card
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
                        'Sync Team', 
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: isDark ? AppDarkColors.textMain : AppColors.textMain),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 16, 
                            backgroundColor: isDark ? AppDarkColors.background : AppColors.inputBackground, 
                            child: Icon(Icons.person, size: 16, color: isDark ? AppDarkColors.textMain : AppColors.textMain),
                          ),
                          Transform.translate(
                            offset: const Offset(-10, 0), 
                            child: CircleAvatar(
                              radius: 16, 
                              backgroundColor: isDark ? AppDarkColors.surface : Colors.white, 
                              child: CircleAvatar(
                                radius: 14, 
                                backgroundColor: isDark ? AppDarkColors.background : AppColors.inputBackground, 
                                child: Icon(Icons.person, size: 16, color: isDark ? AppDarkColors.textMain : AppColors.textMain),
                              ),
                            ),
                          ),
                          Transform.translate(
                            offset: const Offset(-20, 0), 
                            child: CircleAvatar(
                              radius: 16, 
                              backgroundColor: isDark ? AppDarkColors.surface : Colors.white, 
                              child: CircleAvatar(
                                radius: 14, 
                                backgroundColor: isDark ? AppDarkColors.background : AppColors.inputBackground, 
                                child: Icon(Icons.person, size: 16, color: isDark ? AppDarkColors.textMain : AppColors.textMain),
                              ),
                            ),
                          ),
                          Transform.translate(
                            offset: const Offset(-30, 0),
                            child: CircleAvatar(
                              radius: 16,
                              backgroundColor: isDark ? AppDarkColors.surface : Colors.white,
                              child: CircleAvatar(
                                radius: 14,
                                backgroundColor: isDark ? AppDarkColors.background : AppColors.inputBackground,
                                child: Text(
                                  '+4', 
                                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isDark ? AppDarkColors.textMain : AppColors.textMain),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Active now on #frontend-dev', 
                        style: TextStyle(fontSize: 10, color: isDark ? AppDarkColors.textSecondary : AppColors.textMain),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        );
      },
    );
  }
}
