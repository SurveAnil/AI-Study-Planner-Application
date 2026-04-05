import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/progress_repository.dart';

// ─── State ──────────────────────────────────────────────────────────────

class ProgressState extends Equatable {
  final ProgressReport? report;
  final String period; // 'week' | 'month'
  final bool isLoading;
  final String? errorMessage;

  const ProgressState({
    this.report,
    this.period = 'week',
    this.isLoading = false,
    this.errorMessage,
  });

  ProgressState copyWith({
    ProgressReport? report,
    String? period,
    bool? isLoading,
    String? errorMessage,
  }) {
    return ProgressState(
      report: report ?? this.report,
      period: period ?? this.period,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [report, period, isLoading, errorMessage];
}

// ─── Cubit ──────────────────────────────────────────────────────────────

class ProgressCubit extends Cubit<ProgressState> {
  final ProgressRepository _repository;

  ProgressCubit({required ProgressRepository repository})
      : _repository = repository,
        super(const ProgressState());

  Future<void> loadReport(String period) async {
    emit(state.copyWith(isLoading: true, period: period));

    final result = await _repository.loadReport(period);
    result.fold(
      (failure) => emit(state.copyWith(
        isLoading: false,
        errorMessage: failure.message,
      )),
      (report) => emit(state.copyWith(
        report: report,
        isLoading: false,
        errorMessage: null,
      )),
    );
  }
}
