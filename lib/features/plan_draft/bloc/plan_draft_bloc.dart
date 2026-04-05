import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/error/failures.dart';
import '../../../core/network/network_info.dart';
import '../models/draft_models.dart';
import '../data/plan_draft_repository.dart';
import '../data/manual_plan_algorithm.dart';
import '../data/commit_service.dart';
import 'plan_draft_event.dart';
import 'plan_draft_state.dart';

class PlanDraftBloc extends Bloc<PlanDraftEvent, PlanDraftState> {
  final NetworkInfo _networkInfo;
  final PlanDraftRepository _repository;
  final CommitService _commitService;

  /// Shared dev user ID — see [AppConstants.kDevUserId].
  static const String _userId = AppConstants.kDevUserId;

  PlanDraftBloc({
    required NetworkInfo networkInfo,
    required PlanDraftRepository repository,
    required CommitService commitService,
  })  : _networkInfo = networkInfo,
        _repository = repository,
        _commitService = commitService,
        super(PlanDraftInitial()) {
    on<RequestAIPlanEvent>(_onRequestAIPlan);
    on<RequestManualPlanEvent>(_onRequestManualPlan);
    on<EditBlockEvent>(_onEditBlock);
    on<AddBlockEvent>(_onAddBlock);
    on<DeleteBlockEvent>(_onDeleteBlock);
    on<ReorderBlocksEvent>(_onReorderBlocks);
    on<CommitPlanEvent>(_onCommitPlan);
    on<DiscardDraftEvent>(_onDiscardDraft);
    on<RetryConnectivityEvent>(_onRetryConnectivity);
  }

  // ── AI Plan ──────────────────────────────────────────────────────────────

  Future<void> _onRequestAIPlan(
      RequestAIPlanEvent event, Emitter<PlanDraftState> emit) async {
    if (!await _networkInfo.isConnected) {
      emit(OfflinePlanningState());
      return;
    }

    emit(PlanDraftLoading());

    final today = DateTime.now();
    final planDate =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

    final result = await _repository.generateDraft(_userId, event.request);

    result.fold(
      (failure) => emit(PlanDraftError(failure)),
      (draft) => emit(PlanDraft(draft, planDate: planDate, planSource: 'ai')),
    );
  }

  // ── Manual Plan — pure local algorithm ──────────────────────────────────

  void _onRequestManualPlan(
      RequestManualPlanEvent event, Emitter<PlanDraftState> emit) {
    try {
      final algo = ManualPlanAlgorithm(
        subjects: event.subjects,
        timeSlots: event.timeSlots,
        priorities: event.priorities,
        sessionLength: event.sessionLength,
        date: event.date,
      );

      final blocks = algo.generate();
      final summary =
          'Manual plan for ${event.date} · ${event.subjects.join(', ')}';

      emit(PlanDraft(
        PlanDraftResponse(planSummary: summary, blocks: blocks),
        planDate: event.date,
        planSource: 'manual',
      ));
    } on InsufficientTimeFailure catch (e) {
      emit(PlanDraftError(e));
    } on NoSubjectsFailure catch (e) {
      emit(PlanDraftError(e));
    } catch (e) {
      emit(PlanDraftError(DatabaseFailure('Unexpected error: $e')));
    }
  }

  // ── Block Editing (Milestone 3) ──────────────────────────────────────────

  void _onEditBlock(EditBlockEvent event, Emitter<PlanDraftState> emit) {
    if (state is! PlanDraft) return;
    final draftState = state as PlanDraft;
    if (draftState is PlanCommitInProgress) return; // locked

    final blocks = List<DraftBlock>.from(draftState.draft.blocks);
    blocks[event.index] = event.updatedBlock;

    emit(PlanDraft(
      PlanDraftResponse(
          planSummary: draftState.draft.planSummary,
          warnings: draftState.draft.warnings,
          blocks: blocks),
      planDate: draftState.planDate,
      planSource: draftState.planSource,
    ));
  }

  void _onAddBlock(AddBlockEvent event, Emitter<PlanDraftState> emit) {
    if (state is! PlanDraft) return;
    final draftState = state as PlanDraft;

    final blocks = List<DraftBlock>.from(draftState.draft.blocks);
    if (event.insertAfterIndex != null) {
      blocks.insert(event.insertAfterIndex! + 1, event.block);
    } else {
      blocks.add(event.block);
    }

    emit(PlanDraft(
      PlanDraftResponse(
          planSummary: draftState.draft.planSummary,
          warnings: draftState.draft.warnings,
          blocks: blocks),
      planDate: draftState.planDate,
      planSource: draftState.planSource,
    ));
  }

  void _onDeleteBlock(DeleteBlockEvent event, Emitter<PlanDraftState> emit) {
    if (state is! PlanDraft) return;
    final draftState = state as PlanDraft;

    final blocks = List<DraftBlock>.from(draftState.draft.blocks);
    blocks.removeAt(event.index);

    // Guard: at least 1 non-break block must remain
    if (!blocks.any((b) => b.type != 'break')) return;

    emit(PlanDraft(
      PlanDraftResponse(
          planSummary: draftState.draft.planSummary,
          warnings: draftState.draft.warnings,
          blocks: blocks),
      planDate: draftState.planDate,
      planSource: draftState.planSource,
    ));
  }

  void _onReorderBlocks(ReorderBlocksEvent event, Emitter<PlanDraftState> emit) {
    if (state is! PlanDraft) return;
    final draftState = state as PlanDraft;

    final blocks = List<DraftBlock>.from(draftState.draft.blocks);
    var newIndex = event.newIndex;
    if (event.oldIndex < event.newIndex) newIndex -= 1;
    final block = blocks.removeAt(event.oldIndex);
    blocks.insert(newIndex, block);

    emit(PlanDraft(
      PlanDraftResponse(
          planSummary: draftState.draft.planSummary,
          warnings: draftState.draft.warnings,
          blocks: blocks),
      planDate: draftState.planDate,
      planSource: draftState.planSource,
    ));
  }

  // ── Commit to SQLite (Milestone 4) ───────────────────────────────────────

  Future<void> _onCommitPlan(
      CommitPlanEvent event, Emitter<PlanDraftState> emit) async {
    if (state is! PlanDraft) return;
    final currentDraft = state as PlanDraft;

    if (!currentDraft.draft.blocks.any((b) => b.type != 'break')) {
      emit(PlanDraftError(
        const InvalidBlockFailure('No study blocks in plan.'),
        preservedDraft: currentDraft.draft,
      ));
      return;
    }

    emit(PlanCommitInProgress(
      currentDraft.draft,
      planDate: currentDraft.planDate,
      planSource: currentDraft.planSource,
    ));

    try {
      await _commitService.commitPlan(
        _userId,
        currentDraft.draft,
        currentDraft.planDate,
        planSource: currentDraft.planSource,
      );
      emit(PlanCommitted());
    } on DatabaseFailure catch (e) {
      emit(PlanDraftError(e, preservedDraft: currentDraft.draft));
    } catch (e) {
      emit(PlanDraftError(
        DatabaseFailure('Failed to save plan: $e'),
        preservedDraft: currentDraft.draft,
      ));
    }
  }

  // ── Misc ─────────────────────────────────────────────────────────────────

  void _onDiscardDraft(DiscardDraftEvent event, Emitter<PlanDraftState> emit) {
    emit(PlanDraftInitial());
  }

  Future<void> _onRetryConnectivity(
      RetryConnectivityEvent event, Emitter<PlanDraftState> emit) async {
    if (state is OfflinePlanningState) {
      if (await _networkInfo.isConnected) {
        emit(PlanDraftInitial());
      }
    }
  }
}
