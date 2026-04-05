import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../session/presentation/active_session_screen.dart';
import '../../../roadmap/data/roadmap_local_service.dart';
import '../../../roadmap/presentation/roadmap_input_screen.dart';
import '../../../roadmap/presentation/roadmap_screen.dart';

/// 2x2 Grid of primary actions
class QuickActionGrid extends StatelessWidget {
  const QuickActionGrid({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: AppSpacing.space4),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: AppSpacing.space3,
          crossAxisSpacing: AppSpacing.space3,
          childAspectRatio: 1.5,
          children: [
            _ActionTile(
              label: 'AI Roadmap',
              icon: Symbols.auto_awesome_rounded,
              color: AppColors.primary,
              onTap: () => _handleAiRoadmapTap(context),
            ),
            _ActionTile(
              label: 'Manual Task',
              icon: Symbols.add_task_rounded,
              color: const Color(0xFF10B981), // Emerald
              onTap: () {},
            ),
            _ActionTile(
              label: 'Start Timer',
              icon: Symbols.timer_rounded,
              color: const Color(0xFFF59E0B), // Amber
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ActiveSessionScreen(
                      taskId: 'quick-focus',
                      taskTitle: 'Quick Focus',
                      plannedDurationMinutes: 25,
                    ),
                  ),
                );
              },
            ),
            _ActionTile(
              label: 'Revision',
              icon: Symbols.history_edu_rounded,
              color: const Color(0xFF8B5CF6), // Violet
              onTap: () {},
            ),
          ],
        ),
      ],
    );
  }

  /// Intelligent AI Roadmap entry:
  /// - If active skill has a roadmap → open it directly
  /// - Else if any roadmap exists → open latest
  /// - Else → navigate to input screen
  void _handleAiRoadmapTap(BuildContext context) async {
    final svc = RoadmapLocalService.instance;

    // Try active skill first
    final activeSkill = await svc.getActiveSkill();
    Map<String, dynamic>? roadmap;
    if (activeSkill != null) {
      roadmap = await svc.getRoadmapForSkill(activeSkill);
    }
    // Fallback to latest
    roadmap ??= await svc.getLatestRoadmap();

    if (roadmap != null && context.mounted) {
      final skill = roadmap['skill'] as String? ?? 'Unknown';
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => RoadmapScreen(skill: skill, roadmap: roadmap!),
        ),
      );
    } else if (context.mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const RoadmapInputScreen(),
        ),
      );
    }
  }
}

class _ActionTile extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionTile({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(16),
      elevation: 2,
      shadowColor: const Color(0x14000000), // ElevatedCard token
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.space3),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.space2),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 24, fill: 1),
              ),
              const Spacer(),
              Text(
                label,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
