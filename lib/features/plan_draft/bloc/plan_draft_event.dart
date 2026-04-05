import 'package:equatable/equatable.dart';
import '../models/draft_models.dart';

abstract class PlanDraftEvent extends Equatable {
  const PlanDraftEvent();

  @override
  List<Object?> get props => [];
}

/// User taps "Generate with AI"; check isOnline first
class RequestAIPlanEvent extends PlanDraftEvent {
  final PlanRequest request;
  const RequestAIPlanEvent(this.request);

  @override
  List<Object?> get props => [request];
}

/// User taps "Build Manually"; no network check needed.
/// [date] is ISO-8601 date string (YYYY-MM-DD).
/// [subjects], [timeSlots], [priorities], [sessionLength] drive the local algorithm.
class RequestManualPlanEvent extends PlanDraftEvent {
  final String date;
  final List<String> subjects;
  /// Each element is [startHH:MM, endHH:MM]
  final List<List<String>> timeSlots;
  final Map<String, int> priorities;
  final int sessionLength; // minutes: 30 | 45 | 60

  const RequestManualPlanEvent({
    required this.date,
    required this.subjects,
    required this.timeSlots,
    required this.priorities,
    this.sessionLength = 45,
  });

  @override
  List<Object?> get props => [date, subjects, timeSlots, priorities, sessionLength];
}

/// User edits a block in the draft
class EditBlockEvent extends PlanDraftEvent {
  final int index;
  final DraftBlock updatedBlock;

  const EditBlockEvent(this.index, this.updatedBlock);

  @override
  List<Object?> get props => [index, updatedBlock];
}

/// User adds a new block
class AddBlockEvent extends PlanDraftEvent {
  final DraftBlock block;
  final int? insertAfterIndex;

  const AddBlockEvent(this.block, {this.insertAfterIndex});

  @override
  List<Object?> get props => [block, insertAfterIndex];
}

/// User deletes a block (min 1 non-break block must remain)
class DeleteBlockEvent extends PlanDraftEvent {
  final int index;
  const DeleteBlockEvent(this.index);

  @override
  List<Object?> get props => [index];
}

/// User drags blocks to reorder
class ReorderBlocksEvent extends PlanDraftEvent {
  final int oldIndex;
  final int newIndex;

  const ReorderBlocksEvent(this.oldIndex, this.newIndex);

  @override
  List<Object?> get props => [oldIndex, newIndex];
}

/// User taps "Export to Device"
class CommitPlanEvent extends PlanDraftEvent {}

/// User discards draft; show confirm dialog if hasUnsavedEdits=true
class DiscardDraftEvent extends PlanDraftEvent {}

/// Emitted by the 5-second poll on the offline wall
class RetryConnectivityEvent extends PlanDraftEvent {}
