import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:uuid/uuid.dart';

import '../../progress/data/performance_data_repository.dart';
import '../data/revision_repository.dart';

const _uuid = Uuid();

// ─── State ──────────────────────────────────────────────────────────────

class CalendarState extends Equatable {
  final Map<String, List<RevisionTask>> events; // date key → tasks
  final DateTime? selectedDay;
  final List<RevisionTask> upcoming;
  final bool isLoading;
  final String? errorMessage;

  const CalendarState({
    this.events = const {},
    this.selectedDay,
    this.upcoming = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  CalendarState copyWith({
    Map<String, List<RevisionTask>>? events,
    DateTime? selectedDay,
    List<RevisionTask>? upcoming,
    bool? isLoading,
    String? errorMessage,
  }) {
    return CalendarState(
      events: events ?? this.events,
      selectedDay: selectedDay ?? this.selectedDay,
      upcoming: upcoming ?? this.upcoming,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [events, selectedDay, upcoming, isLoading, errorMessage];
}

// ─── Cubit ──────────────────────────────────────────────────────────────

class RevisionCalendarCubit extends Cubit<CalendarState> {
  final RevisionRepository _repository;
  final PerformanceDataRepository _perfRepository;
  final String _userId;

  RevisionCalendarCubit({
    required RevisionRepository repository,
    required PerformanceDataRepository perfRepository,
    required String userId,
  })  : _repository = repository,
        _perfRepository = perfRepository,
        _userId = userId,
        super(const CalendarState());

  Future<void> loadMonth(DateTime month) async {
    emit(state.copyWith(isLoading: true));

    final result = await _repository.getRevisionTasksForMonth(month);
    result.fold(
      (failure) => emit(state.copyWith(
        isLoading: false,
        errorMessage: failure.message,
      )),
      (tasks) {
        // Group tasks by date
        final grouped = <String, List<RevisionTask>>{};
        for (final task in tasks) {
          grouped.putIfAbsent(task.scheduledDate, () => []).add(task);
        }
        emit(state.copyWith(events: grouped, isLoading: false));
      },
    );

    // Also load upcoming 7 days
    final upcomingResult = await _repository.getUpcomingRevisions(days: 7);
    upcomingResult.fold(
      (_) {},
      (upcoming) => emit(state.copyWith(upcoming: upcoming)),
    );
  }

  void selectDay(DateTime day) {
    emit(state.copyWith(selectedDay: day));
  }

  Future<void> markDone(String revisionId) async {
    final result = await _repository.markRevisionDone(revisionId);
    result.fold(
      (failure) => emit(state.copyWith(errorMessage: failure.message)),
      (_) {
        // Reload current month if selectedDay is set
        if (state.selectedDay != null) {
          loadMonth(state.selectedDay!);
        }
      },
    );
  }

  /// Part 9.2: "Log Score" flow
  /// Logs the score to PERFORMANCE_DATA then marks the revision task as done.
  Future<void> logScore(String revisionId, String subject, int score) async {
    final now = DateTime.now().toUtc();
    final data = PerformanceData(
      id: _uuid.v4(),
      userId: _userId,
      subject: subject,
      practiceScore: score,
      recordedAt: now,
      createdAt: now,
      updatedAt: now,
    );

    final result = await _perfRepository.logScore(data);
    result.fold(
      (failure) => emit(state.copyWith(errorMessage: failure.message)),
      (_) => markDone(revisionId), // proceed to mark done on success
    );
  }
}
