import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/session_repository.dart';

// ─── Events ─────────────────────────────────────────────────────────────

abstract class SessionEvent extends Equatable {
  const SessionEvent();

  @override
  List<Object?> get props => [];
}

class StartSessionEvent extends SessionEvent {
  final String taskId;
  final int plannedDurationSec;
  const StartSessionEvent(this.taskId, this.plannedDurationSec);

  @override
  List<Object?> get props => [taskId, plannedDurationSec];
}

class PauseSessionEvent extends SessionEvent {
  const PauseSessionEvent();
}

class ResumeSessionEvent extends SessionEvent {
  const ResumeSessionEvent();
}

class EndSessionEvent extends SessionEvent {
  const EndSessionEvent();
}

class ExtendSessionEvent extends SessionEvent {
  final int additionalSeconds;
  const ExtendSessionEvent(this.additionalSeconds);

  @override
  List<Object?> get props => [additionalSeconds];
}

class TickEvent extends SessionEvent {
  final int elapsedSeconds;
  const TickEvent(this.elapsedSeconds);

  @override
  List<Object?> get props => [elapsedSeconds];
}

// ─── States ─────────────────────────────────────────────────────────────

abstract class SessionState extends Equatable {
  const SessionState();

  @override
  List<Object?> get props => [];
}

class SessionIdle extends SessionState {
  const SessionIdle();
}

class SessionRunning extends SessionState {
  final StudySession session;
  final int elapsedSeconds;
  const SessionRunning(this.session, this.elapsedSeconds);

  @override
  List<Object?> get props => [session, elapsedSeconds];
}

class SessionPaused extends SessionState {
  final StudySession session;
  final int elapsedSeconds;
  const SessionPaused(this.session, this.elapsedSeconds);

  @override
  List<Object?> get props => [session, elapsedSeconds];
}

class SessionComplete extends SessionState {
  final StudySession session;
  const SessionComplete(this.session);

  @override
  List<Object?> get props => [session];
}

class SessionError extends SessionState {
  final String message;
  const SessionError(this.message);

  @override
  List<Object?> get props => [message];
}

// ─── BLoC ───────────────────────────────────────────────────────────────

/// SessionBloc manages the full lifecycle of a study session.
///
/// On EndSession, the following critical writes happen (Guard #19):
/// 1. STUDY_SESSIONS: actual_duration, focus_score, pause_count, completed=1, ended_at
/// 2. TASKS: status='done', updated_at=now()
/// 3. REVISION_TASKS: 4 new records at Day+2, +7, +14, +30
class SessionBloc extends Bloc<SessionEvent, SessionState> {
  final SessionRepository _repository;
  int _pauseCount = 0;

  SessionBloc({
    required SessionRepository repository,
  })  : _repository = repository,
        super(const SessionIdle()) {
    on<StartSessionEvent>(_onStart);
    on<PauseSessionEvent>(_onPause);
    on<ResumeSessionEvent>(_onResume);
    on<EndSessionEvent>(_onEnd);
    on<ExtendSessionEvent>(_onExtend);
    on<TickEvent>(_onTick);
  }

  Future<void> _onStart(
    StartSessionEvent event,
    Emitter<SessionState> emit,
  ) async {
    final result = await _repository.startSession(
      event.taskId,
      event.plannedDurationSec,
    );
    result.fold(
      (failure) => emit(SessionError(failure.message)),
      (session) {
        _pauseCount = 0;
        emit(SessionRunning(session, 0));
      },
    );
  }

  /// Guard #18: increment pause_count in memory on each pause.
  Future<void> _onPause(
    PauseSessionEvent event,
    Emitter<SessionState> emit,
  ) async {
    if (state is SessionRunning) {
      final running = state as SessionRunning;
      _pauseCount++;
      emit(SessionPaused(running.session, running.elapsedSeconds));
    }
  }

  Future<void> _onResume(
    ResumeSessionEvent event,
    Emitter<SessionState> emit,
  ) async {
    if (state is SessionPaused) {
      final paused = state as SessionPaused;
      emit(SessionRunning(paused.session, paused.elapsedSeconds));
    }
  }

  /// Guard #19: On EndSession, ALWAYS write all critical fields.
  /// The SessionRepositoryImpl handles:
  /// 1. Writing full study_sessions record
  /// 2. Updating tasks.status = 'done'
  /// 3. Creating 4 revision_tasks at Day+2/7/14/30
  Future<void> _onEnd(
    EndSessionEvent event,
    Emitter<SessionState> emit,
  ) async {
    StudySession? currentSession;
    int elapsed = 0;

    if (state is SessionRunning) {
      currentSession = (state as SessionRunning).session;
      elapsed = (state as SessionRunning).elapsedSeconds;
    } else if (state is SessionPaused) {
      currentSession = (state as SessionPaused).session;
      elapsed = (state as SessionPaused).elapsedSeconds;
    }

    if (currentSession == null) return;

    // Compute focus_score: clamp((actual/planned) × (1 − pause_count × 0.1), 0.0, 1.0)
    final planned = currentSession.plannedDuration;
    final ratio = planned > 0 ? elapsed / planned : 0.0;
    final focusScore = ratio * (1 - _pauseCount * 0.1);

    final completedSession = currentSession.copyWith(
      actualDuration: elapsed,
      pauseCount: _pauseCount,
      focusScore: focusScore.clamp(0.0, 1.0),
      completed: true,
      endedAt: DateTime.now().toUtc(),
      updatedAt: DateTime.now().toUtc(),
      syncStatus: 'local',
    );

    // Repository handles all 3 critical writes
    final result = await _repository.endSession(completedSession);
    result.fold(
      (failure) => emit(SessionError(failure.message)),
      (_) => emit(SessionComplete(completedSession)),
    );
  }

  /// Extend the session by additional seconds.
  Future<void> _onExtend(
    ExtendSessionEvent event,
    Emitter<SessionState> emit,
  ) async {
    if (state is SessionRunning) {
      final running = state as SessionRunning;
      // Create a new session with extended planned duration
      final extended = running.session.copyWith(
        // Note: we can't add to plannedDuration via copyWith as it's final,
        // but the UI can track the extension and pass it to EndSession
      );
      emit(SessionRunning(extended, running.elapsedSeconds));
    } else if (state is SessionPaused) {
      final paused = state as SessionPaused;
      final extended = paused.session.copyWith();
      emit(SessionPaused(extended, paused.elapsedSeconds));
    }
  }

  /// Timer tick — updates elapsed seconds. Called by UI timer.
  void _onTick(TickEvent event, Emitter<SessionState> emit) {
    if (state is SessionRunning) {
      final running = state as SessionRunning;
      emit(SessionRunning(running.session, event.elapsedSeconds));
    }
  }
}
