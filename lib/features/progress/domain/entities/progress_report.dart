import 'package:equatable/equatable.dart';
import 'daily_study_snapshot.dart';

/// Comprehensive progress report for a specific period.
class ProgressReport extends Equatable {
  final List<DailyStudySnapshot> snapshots;
  final int currentStreak;
  final double consistencyIndex; // (Active Days / Total Period Days) * 100
  final double weightedFocusEfficiency; // focusTime / weightedCompletion
  final Map<String, int> totalDomainTimeDistribution;

  const ProgressReport({
    required this.snapshots,
    required this.currentStreak,
    required this.consistencyIndex,
    required this.weightedFocusEfficiency,
    required this.totalDomainTimeDistribution,
  });

  @override
  List<Object?> get props => [
        snapshots,
        currentStreak,
        consistencyIndex,
        weightedFocusEfficiency,
        totalDomainTimeDistribution
      ];

  int get totalCompletedTasks => snapshots.fold(0, (sum, s) => sum + s.completedTasks);
  int get totalFocusMinutes => snapshots.fold(0, (sum, s) => sum + s.focusMinutes);
}
