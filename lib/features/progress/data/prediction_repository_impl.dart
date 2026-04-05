import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/network/dio_client.dart';
import '../../session/data/session_repository.dart';
import 'prediction_repository.dart';

/// Concrete implementation of PredictionRepository.
/// Calls FastAPI /ml/predict endpoint.
/// Enforces Guard #8: requires >= 5 sessions.
class PredictionRepositoryImpl implements PredictionRepository {
  final DioClient _dioClient;
  final SessionRepository _sessionRepository;

  PredictionRepositoryImpl({
    required DioClient dioClient,
    required SessionRepository sessionRepository,
  })  : _dioClient = dioClient,
        _sessionRepository = sessionRepository;

  @override
  Future<Either<Failure, PredictionResult>> getPrediction(
      String userId, int daysBack) async {
    try {
      // ─── Guard #8: Check if session_count < 5 ──────────────────────
      final countEither = await _sessionRepository.getSessionCount();
      if (countEither.isLeft()) {
        return Left(countEither.fold((l) => l, (_) => const DatabaseFailure('')));
      }
      
      final sessionCount = countEither.getOrElse(() => 0);
      if (sessionCount < 5) {
        return Left(InsufficientDataFailure(
          'Complete 5 sessions to unlock predictions.',
          sessionCount: sessionCount,
        ));
      }

      // Call FastAPI endpoint
      final response = await _dioClient.dio.post(
        '/ml/predict',
        data: {
          'user_id': userId,
          'days_back': daysBack,
        },
      );

      final data = response.data as Map<String, dynamic>;
      
      final scoresDynamic = data['predicted_scores'] as Map<String, dynamic>? ?? {};
      final scores = scoresDynamic.map((k, v) => MapEntry(k, (v as num).toDouble()));
      
      final confidence = (data['confidence'] as num?)?.toDouble() ?? 0.0;
      
      final featuresDynamic = data['feature_importances'] as Map<String, dynamic>? ?? {};
      final features = featuresDynamic.map((k, v) => MapEntry(k, (v as num).toDouble()));

      final result = PredictionResult(
        predictedScores: scores,
        confidence: confidence,
        featureImportances: features,
      );

      return Right(result);

    } on DioException catch (e) {
      if (e.response?.statusCode == 422) {
         // Backend might also enforce the 5 session rule and return 422
         return const Left(InsufficientDataFailure('Insufficient data for prediction', sessionCount: 0));
      }
      return Left(NetworkFailure('Failed to connect to prediction service: ${e.message}'));
    } catch (e) {
      return Left(DatabaseFailure('Prediction error: $e'));
    }
  }
}
