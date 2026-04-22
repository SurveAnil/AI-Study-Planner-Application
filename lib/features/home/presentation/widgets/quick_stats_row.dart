import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../schedule/bloc/schedule_cubit.dart';

/// Row of 3 stats summarizing today's performance.
class QuickStatsRow extends StatelessWidget {
  const QuickStatsRow({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ScheduleCubit, ScheduleState>(
      builder: (context, state) {
        // Compute basic stats from the schedule
        final totalTasks = state.tasks.length;
        final completedTasks = state.tasks.where((t) => t['status'] == 'done').length;
        
        final completedMins = state.tasks.where((t) => t['status'] == 'done').fold<int>(0, (sum, t) => sum + ((t['duration_minutes'] as int?) ?? 0));
        
        final double consistenty = totalTasks == 0 ? 0 : (completedTasks / totalTasks) * 100;
        
        // Convert to hours/mins
        final hours = completedMins ~/ 60;
        final mins = completedMins % 60;
        final timeString = hours > 0 ? '${hours}h ${mins}m' : '${mins}m';

        return Row(
          children: [
            Expanded(
              child: _StatCard(
                icon: Symbols.schedule_rounded,
                label: 'Studied',
                value: timeString,
                accentOpacity: 0.3,
              ),
            ),
            const SizedBox(width: AppSpacing.space3),
            Expanded(
              child: _StatCard(
                icon: Symbols.check_circle_rounded,
                label: 'Tasks',
                value: '$completedTasks/$totalTasks',
                accentOpacity: 0.5,
              ),
            ),
            const SizedBox(width: AppSpacing.space3),
            Expanded(
              child: _StatCard(
                icon: Symbols.monitoring_rounded,
                label: 'Consistency',
                value: '${consistenty.toStringAsFixed(0)}%',
                accentOpacity: 0.8,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final double accentOpacity;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    this.accentOpacity = 0.5,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusCompactCard),
        border: Border.all(color: cs.outlineVariant.withAlpha(20)),
      ),
      child: Stack(
        children: [
          // Left accent strip
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            child: Container(
              width: 3,
              color: AppColors.primary.withOpacity(accentOpacity),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.space3),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, size: 18, color: cs.primary.withAlpha(160)),
                const SizedBox(height: AppSpacing.space2),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface,
                  ),
                ),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: cs.onSurfaceVariant.withAlpha(150),
                    fontSize: 10,
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
