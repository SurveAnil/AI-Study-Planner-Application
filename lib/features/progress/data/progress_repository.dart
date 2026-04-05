import 'package:dartz/dartz.dart';

import '../../../core/error/failures.dart';

/// Performance data record — user-entered practice/test scores.
class PerformanceData {
  final String id;
  final String userId;
  final String subject;
  final int? practiceScore; // 0–100
  final int? testScore;     // 0–100
  final int sessionCount;
  final DateTime recordedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String syncStatus;
  final bool isDeleted;

  const PerformanceData({
    required this.id,
    required this.userId,
    required this.subject,
    this.practiceScore,
    this.testScore,
    this.sessionCount = 0,
    required this.recordedAt,
    required this.createdAt,
    required this.updatedAt,
    this.syncStatus = 'local',
    this.isDeleted = false,
  });
}

/// Consistency report data.
class ProgressReport {
  final double consistencyScore;
  final String gamificationLevel;
  final int currentStreak;
  final Map<String, double> dailyStudyHours;
  final int completedTasks;
  final int pendingTasks;
  final int skippedTasks;
  final Map<String, double> subjectTimeMap;

  const ProgressReport({
    required this.consistencyScore,
    required this.gamificationLevel,
    required this.currentStreak,
    required this.dailyStudyHours,
    required this.completedTasks,
    required this.pendingTasks,
    required this.skippedTasks,
    required this.subjectTimeMap,
  });
}

/// Abstract progress repository.
abstract class ProgressRepository {
  Future<Either<Failure, ProgressReport>> loadReport(String period);
  Future<Either<Failure, List<PerformanceData>>> getPerformanceForSubject(
    String userId,
    String subject,
  );
  Future<Either<Failure, Unit>> logPerformanceScore(PerformanceData data);
}
