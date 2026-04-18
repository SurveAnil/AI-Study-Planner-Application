import 'package:flutter/material.dart';
import 'package:flutter_heatmap_calendar/flutter_heatmap_calendar.dart';
import '../../domain/entities/daily_study_snapshot.dart';

class StudyHeatmap extends StatelessWidget {
  final List<DailyStudySnapshot> snapshots;

  const StudyHeatmap({super.key, required this.snapshots});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    // Convert snapshots to map for the heatmap
    final dataset = <DateTime, int>{};
    for (var s in snapshots) {
      if (s.focusMinutes > 0) {
        dataset[DateTime(s.date.year, s.date.month, s.date.day)] = s.focusMinutes;
      }
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: cs.outlineVariant.withAlpha(50)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.grid_on, size: 18, color: cs.primary),
              const SizedBox(width: 8),
              Text(
                "Study Intensity",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: cs.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: HeatMap(
              datasets: dataset,
              colorMode: ColorMode.opacity,
              showText: false,
              defaultColor: cs.surfaceContainerHighest.withAlpha(40),
              colorsets: {
                1: cs.primary.withAlpha(20),
                30: cs.primary.withAlpha(100),
                60: cs.primary.withAlpha(180),
                120: cs.primary,
              },
              onClick: (value) {
                ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("$value: ${dataset[value] ?? 0} mins")));
              },
            ),
          ),
        ],
      ),
    );
  }
}
