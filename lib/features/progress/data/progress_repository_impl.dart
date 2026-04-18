import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../domain/entities/progress_report.dart';
import 'analytics_aggregator.dart';
import 'progress_repository.dart';

class ProgressRepositoryImpl implements ProgressRepository {
  final AnalyticsAggregator aggregator;

  ProgressRepositoryImpl({required this.aggregator});

  @override
  Future<Either<Failure, ProgressReport>> loadSkillReport(String skill) async {
    try {
      final report = await aggregator.computeReport(skill);
      return Right(report);
    } catch (e) {
      return Left(DatabaseFailure('Failed to aggregate progress data: $e'));
    }
  }

  @override
  Future<Either<Failure, List<PerformanceData>>> getPerformanceForSubject(
    String userId,
    String subject,
  ) async {
    // This connects to the user-entered scores if needed (Legacy Support)
    return const Right([]);
  }
}
