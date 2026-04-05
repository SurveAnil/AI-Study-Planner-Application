import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/network/dio_client.dart';
import 'subject_analytics_repository.dart';

/// Concrete implementation of SubjectAnalyticsRepository.
/// Calls FastAPI /ml/cluster endpoint.
/// Guards #9 & #10 (fallback logic if subjects < 3 or low variance) 
/// are handled natively by the Python backend which sets fallback_used = true.
/// We just parse the response. Always returns 200 unless network dies.
class SubjectAnalyticsRepositoryImpl implements SubjectAnalyticsRepository {
  final DioClient _dioClient;

  SubjectAnalyticsRepositoryImpl({required DioClient dioClient})
      : _dioClient = dioClient;

  @override
  Future<Either<Failure, SubjectAnalyticsResult>> getSubjectAnalytics(
      String userId) async {
    try {
      final response = await _dioClient.dio.post(
        '/ml/cluster',
        data: {'user_id': userId},
      );

      final data = response.data as Map<String, dynamic>;
      final clustersData = data['clusters'] as Map<String, dynamic>? ?? {};
      
      final strong = (clustersData['strong'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList();
      final moderate = (clustersData['moderate'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList();
      final weak = (clustersData['weak'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList();

      final fallbackUsed = data['fallback_used'] as bool? ?? false;

      final result = SubjectAnalyticsResult(
        clusters: SubjectClusters(
          strong: strong,
          moderate: moderate,
          weak: weak,
        ),
        fallbackUsed: fallbackUsed,
      );

      return Right(result);
    } on DioException catch (e) {
      return Left(NetworkFailure(
          'Failed to connect to analytics service: ${e.message}'));
    } catch (e) {
      return Left(DatabaseFailure('Analytics error: $e'));
    }
  }
}
