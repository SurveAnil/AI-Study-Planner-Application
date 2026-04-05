import 'package:equatable/equatable.dart';
import '../../../core/error/failures.dart';
import '../models/draft_models.dart';

abstract class PlanDraftState extends Equatable {
  const PlanDraftState();

  @override
  List<Object?> get props => [];
}

/// No draft exists. Show empty state + Generate/Manual buttons.
class PlanDraftInitial extends PlanDraftState {}

/// Network unavailable. Show offline wall with two options.
class OfflinePlanningState extends PlanDraftState {}

/// Awaiting LLM response. Show loading with message.
class PlanDraftLoading extends PlanDraftState {}

/// Draft in memory. Blocks editable. NOT in SQLite.
class PlanDraft extends PlanDraftState {
  final PlanDraftResponse draft;
  /// ISO-8601 date string (YYYY-MM-DD) for the plan.
  final String planDate;
  /// 'ai' or 'manual'
  final String planSource;

  const PlanDraft(this.draft, {required this.planDate, this.planSource = 'manual'});

  @override
  List<Object?> get props => [draft, planDate, planSource];
}

/// Extends PlanDraft. Edit bottom sheet is open.
class PlanDraftEditing extends PlanDraft {
  final int blockIndex;
  
  const PlanDraftEditing(super.draft, this.blockIndex, {required super.planDate, super.planSource = 'manual'});

  @override
  List<Object?> get props => [draft, blockIndex];
}

/// LLM error OR commit error. preservedDraft non-null on commit fail.
class PlanDraftError extends PlanDraftState {
  final Failure failure;
  final PlanDraftResponse? preservedDraft;

  const PlanDraftError(this.failure, {this.preservedDraft});

  @override
  List<Object?> get props => [failure, preservedDraft];
}

/// Writing to SQLite. Draft visible beneath progress overlay.
class PlanCommitInProgress extends PlanDraft {
  const PlanCommitInProgress(super.draft, {required super.planDate, super.planSource = 'manual'});
}

/// Written to SQLite. Terminal state. Show success + navigate.
class PlanCommitted extends PlanDraftState {}
