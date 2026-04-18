import 'package:flutter/material.dart';
import '../../../../core/constants/app_spacing.dart';

/// Top-level metric card for consistency and streaks.
class ProgressStatisticsCard extends StatelessWidget {
  final double consistencyIndex;
  final int streak;
  final double efficiency;

  const ProgressStatisticsCard({
    super.key,
    required this.consistencyIndex,
    required this.streak,
    required this.efficiency,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.space4),
      decoration: BoxDecoration(
        color: cs.primaryContainer,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _Stat(
            label: "Consistency",
            value: "${consistencyIndex.toInt()}%",
            icon: Icons.speed,
            color: cs.primary,
          ),
          _Stat(
            label: "Streak",
            value: "$streak d",
            icon: Icons.local_fire_department,
            color: Colors.orange,
          ),
          _Stat(
            label: "Efficiency",
            value: efficiency.toStringAsFixed(1),
            icon: Icons.bolt,
            color: Colors.amber,
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _Stat({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: cs.onPrimaryContainer,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: cs.onPrimaryContainer.withAlpha(180),
          ),
        ),
      ],
    );
  }
}
