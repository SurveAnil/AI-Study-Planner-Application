import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../domain/entities/progress_report.dart';

/// Legacy model for performance scores (Optional cleanup later)
class PerformanceData {
  final String id;
  final String userId;
  final String subject;
  final int? practiceScore;
  final int? testScore;
  final DateTime recordedAt;

  const PerformanceData({
    required this.id,
    required this.userId,
    required this.subject,
    this.practiceScore,
    this.testScore,
    required this.recordedAt,
  });
}

/// Abstract progress repository for the Analytics Engine.
abstract class ProgressRepository {
  /// Fetches a normalized report for a specific skill.
  Future<Either<Failure, ProgressReport>> loadSkillReport(String skill);

  Future<Either<Failure, List<PerformanceData>>> getPerformanceForSubject(
    String userId,
    String subject,
  );
}
