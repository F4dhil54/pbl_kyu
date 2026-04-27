import 'package:flutter/material.dart';
import '../../theme/colors.dart';

class CollabView extends StatelessWidget {
  const CollabView({super.key});

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
              'Feed',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.textMain,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Tracking team momentum in real-time.',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textMain,
              ),
            ),
            const SizedBox(height: 24),

            // Feed Item 1
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const CircleAvatar(
                    radius: 16,
                    backgroundColor: AppColors.inputBackground,
                    child: Icon(Icons.person, color: AppColors.textMain, size: 16),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text('Dea Marselia ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                            const Text('pushed to', style: TextStyle(fontSize: 12)),
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('atelier-main', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.primary)),
                            const Text('24M AGO', style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Optimized\nglassmorphism\ntransitions and updates\nTailwind config for the\nnew design system\nrollout.',
                          style: TextStyle(fontSize: 12),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            _buildTag('DESIGN-102'),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE2D4F0),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text('UI REVAMP', style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: AppColors.primary)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: AppColors.inputBackground),
                              ),
                              child: const Text('Give\nKudos', textAlign: TextAlign.center, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.inputBackground,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Row(
                                children: [
                                  Text('🚀 🔥', style: TextStyle(fontSize: 12)),
                                  SizedBox(width: 4),
                                  Text('8\nothers', style: TextStyle(fontSize: 8, color: AppColors.textSecondary)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Feed Item 2
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const CircleAvatar(
                    radius: 16,
                    backgroundColor: AppColors.inputBackground,
                    child: Icon(Icons.person, color: AppColors.textMain, size: 16),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Dian Paramitha', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('User Onboarding Flow\ncompleted', style: TextStyle(fontSize: 12)),
                            const Text('2H AGO', style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: const Border(left: BorderSide(color: Colors.black, width: 4)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Finalize\nauthentication\nflow', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: AppColors.success,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Text('DONE', style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.white)),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              const Text('Review pending\nfrom Lead', style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: AppColors.inputBackground,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Center(
                            child: Text('🙌 🎉 💯 😅', style: TextStyle(fontSize: 14)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Milestone Reached
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text('Milestone Reached!', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.star_border, color: AppColors.primary, size: 32),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'The team has surpassed 500\nmerged PRs this month.\nIncredible velocity!',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: AppColors.inputBackground),
                          ),
                          child: const Center(child: Text('Celebrate', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 12))),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: AppColors.inputBackground),
                          ),
                          child: const Center(child: Text('View\nReport', textAlign: TextAlign.center, style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 12))),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Top Contributors
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Top Contributors', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE2D4F0),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text('WEEKLY', style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: AppColors.primary)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildContributorRanking('1', 'Fadhil Syahidan', '248 Points', Icons.trending_up),
                  const SizedBox(height: 12),
                  _buildContributorRanking('2', 'Sukma Ananda', '212 Points', Icons.remove),
                  const SizedBox(height: 12),
                  _buildContributorRanking('3', 'Dian Paramitha', '195 Points', Icons.trending_up),
                  const SizedBox(height: 20),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.inputBackground),
                    ),
                    child: const Center(child: Text('VIEW FULL RANKING', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10))),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('94%', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
                        Text('EFFICIENCY', style: TextStyle(fontSize: 10, color: AppColors.textMain)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('1.2k', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                        Text('INTERACTION', style: TextStyle(fontSize: 10, color: AppColors.textMain)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('TEAM PULSE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                  SizedBox(height: 12),
                  Text('Vibe is high today', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  SizedBox(height: 4),
                  Text('Based on 14 emoji reactions', style: TextStyle(fontSize: 10, color: AppColors.textMain)),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildTag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.inputBackground),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 8,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildContributorRanking(String rank, String name, String points, IconData icon) {
    return Row(
      children: [
        Stack(
          children: [
            const CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.inputBackground,
              child: Icon(Icons.person, color: AppColors.textMain, size: 16),
            ),
            Positioned(
              top: 0,
              left: 0,
              child: Container(
                width: 12,
                height: 12,
                decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                child: Center(child: Text(rank, style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold))),
              ),
            ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              Text(points, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
            ],
          ),
        ),
        Icon(icon, size: 16, color: AppColors.textMain),
      ],
    );
  }
}
