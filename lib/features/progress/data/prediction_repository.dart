import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';

class PredictionResult {
  final Map<String, double> predictedScores;
  final double confidence;
  final Map<String, double> featureImportances;

  const PredictionResult({
    required this.predictedScores,
    required this.confidence,
    required this.featureImportances,
  });
}

abstract class PredictionRepository {
  Future<Either<Failure, PredictionResult>> getPrediction(
      String userId, int daysBack);
}
