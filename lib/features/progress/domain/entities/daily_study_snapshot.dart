import 'package:equatable/equatable.dart';

/// Normalized domain entity representing one day of study.
/// Aggregates data from daily_plan_cache, task_progress, and study_sessions.
class DailyStudySnapshot extends Equatable {
  final DateTime date;
  final int completedTasks;
  final int totalTasks;
  final double weightedCompletionValue; // Learn=1, Practice=1.5, Project=2.0
  final int focusMinutes;
  final Map<String, int> timeByDomain; // e.g., {'Logic': 45, 'UI': 20}
  final bool isActiveDay;

  const DailyStudySnapshot({
    required this.date,
    required this.completedTasks,
    required this.totalTasks,
    required this.weightedCompletionValue,
    required this.focusMinutes,
    required this.timeByDomain,
    required this.isActiveDay,
  });

  @override
  List<Object?> get props => [
        date,
        completedTasks,
        totalTasks,
        weightedCompletionValue,
        focusMinutes,
        timeByDomain,
        isActiveDay
      ];

  /// Normalized completion (0.0 to 1.0)
  double get completionRate => totalTasks > 0 ? completedTasks / totalTasks : 0.0;
}
