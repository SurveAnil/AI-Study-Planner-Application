import 'dart:async';
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
  final String? skill;
  final int? day;
  const StartSessionEvent(this.taskId, this.plannedDurationSec, {this.skill, this.day});

  @override
  List<Object?> get props => [taskId, plannedDurationSec, skill, day];
}

class ResumeSessionEvent extends SessionEvent {
  final String taskId;
  final int plannedDurationSec;
  final String? skill;
  final int? day;
  const ResumeSessionEvent(this.taskId, this.plannedDurationSec, {this.skill, this.day});

  @override
  List<Object?> get props => [taskId, plannedDurationSec, skill, day];
}

class PauseSessionEvent extends SessionEvent {
  const PauseSessionEvent();
}

class ResumeStartedSessionEvent extends SessionEvent { // Renamed from ResumeSessionEvent in previous turn to avoid confusion with ResumeSessionEvent (start logic)
  const ResumeStartedSessionEvent();
}

class EndSessionEvent extends SessionEvent {
  final bool isManual;
  const EndSessionEvent({this.isManual = false});

  @override
  List<Object?> get props => [isManual];
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
  final int pauseCount;
  const SessionRunning(this.session, this.elapsedSeconds, this.pauseCount);

  @override
  List<Object?> get props => [session, elapsedSeconds, pauseCount];
}

class SessionPaused extends SessionState {
  final StudySession session;
  final int elapsedSeconds;
  final int pauseCount;
  const SessionPaused(this.session, this.elapsedSeconds, this.pauseCount);

  @override
  List<Object?> get props => [session, elapsedSeconds, pauseCount];
}

class SessionOvertime extends SessionState {
  final StudySession session;
  final int overtimeSeconds;
  final int pauseCount;
  const SessionOvertime(this.session, this.overtimeSeconds, this.pauseCount);

  @override
  List<Object?> get props => [session, overtimeSeconds, pauseCount];
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

class SessionBloc extends Bloc<SessionEvent, SessionState> {
  final SessionRepository _repository;
  int _pauseCount = 0;

  SessionBloc({
    required SessionRepository repository,
  })  : _repository = repository,
        super(const SessionIdle()) {
    on<StartSessionEvent>(_onStart);
    on<ResumeSessionEvent>(_onResumeFromHistory);
    on<PauseSessionEvent>(_onPause);
    on<ResumeStartedSessionEvent>(_onResumeStarted);
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
      skill: event.skill,
      day: event.day,
    );
    result.fold(
      (failure) => emit(SessionError(failure.message)),
      (session) {
        _pauseCount = 0;
        emit(SessionRunning(session, 0, _pauseCount));
      },
    );
  }

  Future<void> _onResumeFromHistory(
    ResumeSessionEvent event,
    Emitter<SessionState> emit,
  ) async {
    final result = await _repository.getLatestSessionForTask(event.taskId);
    
    await result.fold(
      (failure) async => emit(SessionError(failure.message)),
      (latest) async {
        if (latest != null) {
          final nextResult = await _repository.startSession(
            event.taskId,
            event.plannedDurationSec,
            skill: event.skill,
            day: event.day,
          );
          
          nextResult.fold(
            (failure) => emit(SessionError(failure.message)),
            (session) {
              _pauseCount = latest.pauseCount;
              emit(SessionRunning(session, latest.actualDuration, _pauseCount));
            },
          );
        } else {
          add(StartSessionEvent(event.taskId, event.plannedDurationSec, skill: event.skill, day: event.day));
        }
      },
    );
  }

  Future<void> _onPause(
    PauseSessionEvent event,
    Emitter<SessionState> emit,
  ) async {
    if (state is SessionRunning) {
      final running = state as SessionRunning;
      _pauseCount++;
      emit(SessionPaused(running.session, running.elapsedSeconds, _pauseCount));
    }
  }

  Future<void> _onResumeStarted(
    ResumeStartedSessionEvent event,
    Emitter<SessionState> emit,
  ) async {
    if (state is SessionPaused) {
      final paused = state as SessionPaused;
      emit(SessionRunning(paused.session, paused.elapsedSeconds, _pauseCount));
    }
  }

  Future<void> _onEnd(
    EndSessionEvent event,
    Emitter<SessionState> emit,
  ) async {
    StudySession? currentSession;
    int totalElapsed = 0;
    bool isCompleted = !event.isManual;

    if (state is SessionRunning) {
      currentSession = (state as SessionRunning).session;
      totalElapsed = (state as SessionRunning).elapsedSeconds;
    } else if (state is SessionPaused) {
      currentSession = (state as SessionPaused).session;
      totalElapsed = (state as SessionPaused).elapsedSeconds;
    } else if (state is SessionOvertime) {
      currentSession = (state as SessionOvertime).session;
      totalElapsed = currentSession.plannedDuration + (state as SessionOvertime).overtimeSeconds;
      isCompleted = true; 
    }

    if (currentSession == null) return;

    final planned = currentSession.plannedDuration;
    final ratio = planned > 0 ? (totalElapsed / planned) : 0.0;
    final focusScore = ratio.clamp(0.0, 1.25) * (1 - _pauseCount * 0.1);

    final completedSession = currentSession.copyWith(
      actualDuration: totalElapsed,
      pauseCount: _pauseCount,
      focusScore: focusScore.clamp(0.0, 1.0),
      completed: isCompleted,
      endedAt: DateTime.now().toUtc(),
      updatedAt: DateTime.now().toUtc(),
    );

    final result = await _repository.endSession(completedSession);
    result.fold(
      (failure) => emit(SessionError(failure.message)),
      (_) => emit(SessionComplete(completedSession)),
    );
  }

  Future<void> _onExtend(
    ExtendSessionEvent event,
    Emitter<SessionState> emit,
  ) async {
    // Legacy
  }

  void _onTick(TickEvent event, Emitter<SessionState> emit) {
    if (state is SessionRunning) {
      final running = state as SessionRunning;
      final planned = running.session.plannedDuration;
      
      if (event.elapsedSeconds >= planned) {
        emit(SessionOvertime(running.session, 0, _pauseCount));
      } else {
        emit(SessionRunning(running.session, event.elapsedSeconds, _pauseCount));
      }
    } else if (state is SessionOvertime) {
      final overtime = state as SessionOvertime;
      final planned = overtime.session.plannedDuration;
      final otSec = event.elapsedSeconds - planned;
      emit(SessionOvertime(overtime.session, otSec.clamp(0, 3600), _pauseCount));
    }
  }
}
