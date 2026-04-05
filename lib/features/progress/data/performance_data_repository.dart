import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';

class PerformanceData {
  final String id;
  final String userId;
  final String subject;
  final int? practiceScore; // 0-100
  final int? testScore; // 0-100
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

abstract class PerformanceDataRepository {
  Future<Either<Failure, Unit>> logScore(PerformanceData data);
  Future<Either<Failure, List<PerformanceData>>> getRecentData({int limit = 50});
}
