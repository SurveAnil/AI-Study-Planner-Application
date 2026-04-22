import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:flutter_heatmap_calendar/flutter_heatmap_calendar.dart';
import '../../domain/entities/daily_study_snapshot.dart';

class StudyHeatmap extends StatelessWidget {
  final List<DailyStudySnapshot> snapshots;

  const StudyHeatmap({super.key, required this.snapshots});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final dataset = <DateTime, int>{};
    for (var s in snapshots) {
      if (s.focusMinutes > 0) {
        dataset[DateTime(s.date.year, s.date.month, s.date.day)] =
            s.focusMinutes;
      }
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.08), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Symbols.calendar_month_rounded,
                  size: 18, color: cs.primary, fill: 1),
              const SizedBox(width: 8),
              Text(
                "Study Intensity",
                style: TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
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
                  SnackBar(
                    content: Text("$value: ${dataset[value] ?? 0} mins"),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
