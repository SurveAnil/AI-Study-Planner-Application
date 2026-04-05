import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import 'local_performance_data_source.dart';
import 'performance_data_repository.dart';

/// Concrete implementation of PerformanceDataRepository.
/// Wraps SQLite operations in Either\<Failure, T\>.
class PerformanceDataRepositoryImpl implements PerformanceDataRepository {
  final LocalPerformanceDataSource _localSource;

  PerformanceDataRepositoryImpl({required LocalPerformanceDataSource localSource})
      : _localSource = localSource;

  @override
  Future<Either<Failure, Unit>> logScore(PerformanceData data) async {
    try {
      await _localSource.logScore(data);
      return const Right(unit);
    } catch (e) {
      return Left(DatabaseFailure('Failed to log performance score: $e'));
    }
  }

  @override
  Future<Either<Failure, List<PerformanceData>>> getRecentData({int limit = 50}) async {
    try {
      final records = await _localSource.getRecentData(limit: limit);
      return Right(records);
    } catch (e) {
      return Left(DatabaseFailure('Failed to load performance data: $e'));
    }
  }
}
