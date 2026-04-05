import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/failures.dart';
import '../data/prediction_repository.dart';

// ─── State ──────────────────────────────────────────────────────────────

class PredictionState extends Equatable {
  final Map<String, double> baseScores;       // Server truth
  final Map<String, double> adjustedScores;   // Real-time What-If
  final double confidence;
  final Map<String, double> featureImportances;
  
  final int daysBack;
  final int deltaHours;       // What-If slider input (e.g. +2 hours)

  final bool isLoading;
  final String? errorMessage;
  // Guard #8 exposes session count if insufficient
  final int? sessionCount;

  const PredictionState({
    this.baseScores = const {},
    this.adjustedScores = const {},
    this.confidence = 0.0,
    this.featureImportances = const {},
    this.daysBack = 30,
    this.deltaHours = 0,
    this.isLoading = false,
    this.errorMessage,
    this.sessionCount,
  });

  PredictionState copyWith({
    Map<String, double>? baseScores,
    Map<String, double>? adjustedScores,
    double? confidence,
    Map<String, double>? featureImportances,
    int? daysBack,
    int? deltaHours,
    bool? isLoading,
    String? errorMessage,
    int? sessionCount,
    bool clearError = false,
  }) {
    return PredictionState(
      baseScores: baseScores ?? this.baseScores,
      adjustedScores: adjustedScores ?? this.adjustedScores,
      confidence: confidence ?? this.confidence,
      featureImportances: featureImportances ?? this.featureImportances,
      daysBack: daysBack ?? this.daysBack,
      deltaHours: deltaHours ?? this.deltaHours,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      sessionCount: sessionCount ?? this.sessionCount,
    );
  }

  @override
  List<Object?> get props => [
        baseScores,
        adjustedScores,
        confidence,
        featureImportances,
        daysBack,
        deltaHours,
        isLoading,
        errorMessage,
        sessionCount,
      ];
}

// ─── Cubit ──────────────────────────────────────────────────────────────

/// PredictionCubit calls /ml/predict and drives the S12 UI.
/// Handles the What-If slider logic dynamically locally.
class PredictionCubit extends Cubit<PredictionState> {
  final PredictionRepository _repository;
  final String _userId;

  PredictionCubit({
    required PredictionRepository repository,
    required String userId,
  })  : _repository = repository,
        _userId = userId,
        super(const PredictionState());

  /// Fetch prediction from backend.
  /// Handles Guard #8 InsufficientDataFailure natively.
  Future<void> runPrediction({int daysBack = 30}) async {
    emit(state.copyWith(isLoading: true, daysBack: daysBack, clearError: true));

    final result = await _repository.getPrediction(_userId, daysBack);

    result.fold(
      (failure) {
        // If it's the data guard, extract sessionCount for the X/5 UI
        int? count;
        if (failure is InsufficientDataFailure) count = failure.sessionCount;
        
        emit(state.copyWith(
          isLoading: false,
          errorMessage: failure.message,
          sessionCount: count,
        ));
      },
      (data) {
        emit(state.copyWith(
          isLoading: false,
          baseScores: data.predictedScores,
          adjustedScores: data.predictedScores, // initial sync
          confidence: data.confidence,
          featureImportances: data.featureImportances,
          deltaHours: 0,
        ));
      },
    );
  }

  /// What-If logic: shift predicted scores based on extra hours.
  /// Uses the 'study_hours' weight from feature_importances (or 1.5 default).
  void adjustInput(int deltaHours) {
    if (state.baseScores.isEmpty) return;

    final weight = state.featureImportances['study_hours'] ?? 1.5;
    final Map<String, double> newScores = {};

    state.baseScores.forEach((subject, baseScore) {
      // Linear shift: + deltaHours * weight (clamped to 100 max)
      final adjusted = (baseScore + (deltaHours * weight)).clamp(0.0, 100.0);
      newScores[subject] = adjusted;
    });

    emit(state.copyWith(
      deltaHours: deltaHours,
      adjustedScores: newScores,
    ));
  }
}
