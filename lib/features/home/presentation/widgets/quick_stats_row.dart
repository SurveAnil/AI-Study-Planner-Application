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
              ),
            ),
            const SizedBox(width: AppSpacing.space3),
            Expanded(
              child: _StatCard(
                icon: Symbols.check_circle_rounded,
                label: 'Tasks',
                value: '$completedTasks/$totalTasks',
              ),
            ),
            const SizedBox(width: AppSpacing.space3),
            Expanded(
              child: _StatCard(
                icon: Symbols.monitoring_rounded,
                label: 'Consistency',
                value: '${consistenty.toStringAsFixed(0)}%',
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

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000), // AppColors shadow token fallback
            offset: Offset(0, 2),
            blurRadius: 8,
          ),
        ],
      ),
      padding: const EdgeInsets.all(AppSpacing.space3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: AppColors.primary),
          const SizedBox(height: AppSpacing.space2),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }
}
