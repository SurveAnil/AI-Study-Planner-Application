import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../roadmap/data/roadmap_local_service.dart';
import '../../../roadmap/presentation/roadmap_input_screen.dart';
import '../../../roadmap/presentation/roadmap_screen.dart';
import '../../../roadmap/presentation/ai_roadmap_main_screen.dart';
import '../../../plan_draft/presentation/day_plan_editor_screen.dart';

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
        GridView(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            mainAxisExtent: 120, // fixed height
          ),
          children: [
            _ActionTile(
              label: 'AI Roadmap',
              icon: Symbols.auto_awesome_rounded,
              color: Theme.of(context).colorScheme.primary,
              onTap: () => _handleAiRoadmapTap(context),
            ),
            _ActionTile(
              label: 'Manual Task',
              icon: Symbols.add_task_rounded,
              color: Theme.of(context).colorScheme.primary,
              onTap: () {},
            ),
            _ActionTile(
              label: 'Modify Day',
              icon: Symbols.edit_calendar_rounded,
              color: Theme.of(context).colorScheme.primary,
              onTap: () => _handleDayEditTap(context),
            ),
            _ActionTile(
              label: 'Revision',
              icon: Symbols.history_edu_rounded,
              color: Theme.of(context).colorScheme.primary,
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
  void _handleAiRoadmapTap(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const AiRoadmapMainScreen(),
      ),
    );
  }

  /// Navigate to Day 1 editor for active skill
  void _handleDayEditTap(BuildContext context) async {
    final svc = RoadmapLocalService.instance;
    final activeSkill = await svc.getActiveSkill();

    if (activeSkill != null && context.mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => DayPlanEditorScreen(
            skill: activeSkill,
            initialDay: 1,
          ),
        ),
      );
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No active skill found. Create a roadmap first!')),
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
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant.withAlpha(20)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // ICON (TOP)
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 24, fill: 1),
                ),
                // TEXT (BOTTOM)
                Text(
                  label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: cs.onSurface,
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
