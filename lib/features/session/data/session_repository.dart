import 'package:dartz/dartz.dart';

import '../../../core/error/failures.dart';

/// Study session record — written by the timer on EndSession.
class StudySession {
  final String id;
  final String? taskId;
  final String? skill;      // Added for AI Roadmap tracking
  final int? day;           // Added for AI Roadmap tracking
  final int actualDuration;   // seconds
  final int plannedDuration;  // seconds
  final int pauseCount;
  final double? focusScore;   // 0.0–1.0
  final bool completed;
  final DateTime startedAt;
  final DateTime? endedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String syncStatus;
  final bool isDeleted;

  const StudySession({
    required this.id,
    required this.taskId,
    this.skill,
    this.day,
    required this.actualDuration,
    required this.plannedDuration,
    this.pauseCount = 0,
    this.focusScore,
    this.completed = false,
    required this.startedAt,
    this.endedAt,
    required this.createdAt,
    required this.updatedAt,
    this.syncStatus = 'local',
    this.isDeleted = false,
  });

  StudySession copyWith({
    int? actualDuration,
    int? pauseCount,
    double? focusScore,
    bool? completed,
    DateTime? endedAt,
    DateTime? updatedAt,
    String? syncStatus,
  }) {
    return StudySession(
      id: id,
      taskId: taskId,
      skill: skill,
      day: day,
      actualDuration: actualDuration ?? this.actualDuration,
      plannedDuration: plannedDuration,
      pauseCount: pauseCount ?? this.pauseCount,
      focusScore: focusScore ?? this.focusScore,
      completed: completed ?? this.completed,
      startedAt: startedAt,
      endedAt: endedAt ?? this.endedAt,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      syncStatus: syncStatus ?? this.syncStatus,
      isDeleted: isDeleted,
    );
  }
}

/// Abstract session repository.
abstract class SessionRepository {
  Future<Either<Failure, StudySession>> startSession(
      String? taskId, int plannedDurationSec, {String? skill, int? day});

  Future<Either<Failure, Unit>> endSession(StudySession session);

  Future<Either<Failure, StudySession?>> getLatestSessionForTask(String? taskId);

  Future<Either<Failure, List<StudySession>>> getSessionsForTask(String? taskId);
  Future<Either<Failure, List<StudySession>>> getRecentSessions({int limit = 30});
  Future<Either<Failure, int>> getSessionCount();
}
