import 'package:dartz/dartz.dart';

import '../../../core/error/failures.dart';
import '../../schedule/data/local_study_plan_source.dart';
import '../../revision/data/local_revision_source.dart';
import 'local_session_source.dart';
import 'session_repository.dart';

/// Concrete implementation of SessionRepository.
/// Handles session lifecycle (start → end) with critical data writes.
/// On EndSession: writes study_sessions, updates task status, creates revision tasks.
class SessionRepositoryImpl implements SessionRepository {
  final LocalSessionSource _sessionSource;
  final LocalStudyPlanSource _planSource;
  final LocalRevisionSource _revisionSource;
  final String _userId; // injected from auth state

  SessionRepositoryImpl({
    required LocalSessionSource sessionSource,
    required LocalStudyPlanSource planSource,
    required LocalRevisionSource revisionSource,
    required String userId,
  })  : _sessionSource = sessionSource,
        _planSource = planSource,
        _revisionSource = revisionSource,
        _userId = userId;

  @override
  Future<Either<Failure, StudySession>> startSession(
    String taskId,
    int plannedDurationSec,
  ) async {
    try {
      final session =
          await _sessionSource.createSession(taskId, plannedDurationSec);
      return Right(session);
    } catch (e) {
      return Left(DatabaseFailure('Failed to start session: $e'));
    }
  }

  @override
  Future<Either<Failure, Unit>> endSession(StudySession session) async {
    try {
      // 1. Write the complete study_sessions record
      //    (actual_duration, focus_score, pause_count, completed=1, ended_at)
      await _sessionSource.endSession(session);

      // 2. Update task status to 'done'
      await _planSource.updateTaskStatus(session.taskId, 'done');

      // 3. Create 4 revision tasks (Day+2, +7, +14, +30)
      //    Need the task details for topic/subject
      final task = await _planSource.getTaskById(session.taskId);
      if (task != null) {
        await _revisionSource.createRevisionTasks(
          _userId,
          task['title'] as String, // topic
          (task['subject_id'] as String?) ?? 'general',
          session.endedAt ?? DateTime.now().toUtc(),
        );
      }

      return const Right(unit);
    } catch (e) {
      return Left(DatabaseFailure('Failed to end session: $e'));
    }
  }

  @override
  Future<Either<Failure, List<StudySession>>> getSessionsForTask(
    String taskId,
  ) async {
    try {
      final sessions = await _sessionSource.getSessionsForTask(taskId);
      return Right(sessions);
    } catch (e) {
      return Left(DatabaseFailure('Failed to load sessions: $e'));
    }
  }

  @override
  Future<Either<Failure, List<StudySession>>> getRecentSessions({
    int limit = 30,
  }) async {
    try {
      final sessions = await _sessionSource.getRecentSessions(limit: limit);
      return Right(sessions);
    } catch (e) {
      return Left(DatabaseFailure('Failed to load recent sessions: $e'));
    }
  }

  @override
  Future<Either<Failure, int>> getSessionCount() async {
    try {
      final count = await _sessionSource.getSessionCount();
      return Right(count);
    } catch (e) {
      return Left(DatabaseFailure('Failed to count sessions: $e'));
    }
  }
}
