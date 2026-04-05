import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/subject_analytics_repository.dart';

// ─── State ──────────────────────────────────────────────────────────────

class AnalyticsState extends Equatable {
  final SubjectClusters clusters;
  final bool fallbackUsed; // Guard 9/10 indicator
  
  final bool isLoading;
  final String? errorMessage;

  const AnalyticsState({
    this.clusters = const SubjectClusters(),
    this.fallbackUsed = false,
    this.isLoading = false,
    this.errorMessage,
  });

  AnalyticsState copyWith({
    SubjectClusters? clusters,
    bool? fallbackUsed,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return AnalyticsState(
      clusters: clusters ?? this.clusters,
      fallbackUsed: fallbackUsed ?? this.fallbackUsed,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [clusters, fallbackUsed, isLoading, errorMessage];
}

// ─── Cubit ──────────────────────────────────────────────────────────────

/// SubjectAnalyticsCubit calls /ml/cluster and drives S09 UI.
class SubjectAnalyticsCubit extends Cubit<AnalyticsState> {
  final SubjectAnalyticsRepository _repository;
  final String _userId;

  SubjectAnalyticsCubit({
    required SubjectAnalyticsRepository repository,
    required String userId,
  })  : _repository = repository,
        _userId = userId,
        super(const AnalyticsState());

  /// Fetch clustering from backend.
  Future<void> loadAnalytics() async {
    emit(state.copyWith(isLoading: true, clearError: true));

    final result = await _repository.getSubjectAnalytics(_userId);

    result.fold(
      (failure) => emit(state.copyWith(
        isLoading: false,
        errorMessage: failure.message,
      )),
      (data) => emit(state.copyWith(
        isLoading: false,
        clusters: data.clusters,
        fallbackUsed: data.fallbackUsed,
      )),
    );
  }
}
