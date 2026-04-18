import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/progress_repository.dart';
import '../domain/entities/progress_report.dart';

// ─── State ──────────────────────────────────────────────────────────────

class ProgressState extends Equatable {
  final ProgressReport? report;
  final String? skill;
  final bool isLoading;
  final String? errorMessage;

  const ProgressState({
    this.report,
    this.skill,
    this.isLoading = false,
    this.errorMessage,
  });

  ProgressState copyWith({
    ProgressReport? report,
    String? skill,
    bool? isLoading,
    String? errorMessage,
  }) {
    return ProgressState(
      report: report ?? this.report,
      skill: skill ?? this.skill,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [report, skill, isLoading, errorMessage];
}

// ─── Cubit ──────────────────────────────────────────────────────────────

class ProgressCubit extends Cubit<ProgressState> {
  final ProgressRepository _repository;

  ProgressCubit({required ProgressRepository repository})
      : _repository = repository,
        super(const ProgressState());

  /// Loads the intelligence report for a specific skill.
  Future<void> loadSkillReport(String skill) async {
    emit(state.copyWith(isLoading: true, skill: skill, errorMessage: null));

    final result = await _repository.loadSkillReport(skill);
    result.fold(
      (failure) => emit(state.copyWith(
        isLoading: false,
        errorMessage: failure.message,
      )),
      (report) => emit(state.copyWith(
        report: report,
        isLoading: false,
      )),
    );
  }
}
