import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';

class SubjectClusters {
  final List<String> strong;
  final List<String> moderate;
  final List<String> weak;

  const SubjectClusters({
    this.strong = const [],
    this.moderate = const [],
    this.weak = const [],
  });
}

class SubjectAnalyticsResult {
  final SubjectClusters clusters;
  final bool fallbackUsed;

  const SubjectAnalyticsResult({
    required this.clusters,
    required this.fallbackUsed,
  });
}

abstract class SubjectAnalyticsRepository {
  Future<Either<Failure, SubjectAnalyticsResult>> getSubjectAnalytics(String userId);
}
