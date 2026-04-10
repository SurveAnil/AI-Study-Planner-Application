import 'package:dartz/dartz.dart';

import '../../../core/error/failures.dart';
import '../../schedule/data/local_study_plan_source.dart';
import '../../revision/data/local_revision_source.dart';
import '../../roadmap/data/roadmap_local_service.dart';
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
    String? taskId,
    int plannedDurationSec, {
    String? skill,
    int? day,
  }) async {
    try {
      final session = await _sessionSource.createSession(taskId, plannedDurationSec,
          skill: skill, day: day);
      return Right(session);
    } catch (e) {
      return Left(DatabaseFailure('Failed to start session: $e'));
    }
  }

  @override
  Future<Either<Failure, Unit>> endSession(StudySession session) async {
    try {
      // 1. Write the complete study_sessions record
      await _sessionSource.endSession(session);

      // 2. Update status in appropriate table based on session type
      if (session.skill != null && session.day != null && session.taskId != null && session.completed) {
        // AI Roadmap task - mark as completed in task_progress
        final roadmapSvc = RoadmapLocalService.instance;
        // We find the index by matching taskId in the daily plan tasks
        final dailyPlan = await roadmapSvc.getDailyPlan(session.skill!, session.day!);
        if (dailyPlan != null) {
          final tasks = dailyPlan['tasks'] as List? ?? [];
          int index = -1;
          for (int i = 0; i < tasks.length; i++) {
            final t = tasks[i];
            if (t is Map<String, dynamic> && t['task_id'] == session.taskId) {
              index = i;
              break;
            }
          }
          if (index != -1) {
            await roadmapSvc.updateTaskStatus(
              session.skill!,
              session.day!,
              index,
              session.taskId!,
              'completed',
            );
          }
        }
      } else if (session.taskId != null && session.taskId != 'quick-focus' && session.completed) {
        // Legacy/Manual task marking
        try {
          await _planSource.updateTaskStatus(session.taskId!, 'done');
        } catch (_) {}
      }

      // 3. Create revision tasks ONLY if session was completed
      if (session.completed && session.taskId != null && session.taskId != 'quick-focus') {
         try {
            // Find task title for revision record
            String? title;
            if (session.skill != null && session.day != null) {
               final dp = await RoadmapLocalService.instance.getDailyPlan(session.skill!, session.day!);
               final ts = dp?['tasks'] as List? ?? [];
               for (var t in ts) {
                 if (t is Map && t['task_id'] == session.taskId) {
                   title = t['title'];
                   break;
                 }
               }
            } else {
               final task = await _planSource.getTaskById(session.taskId!);
               title = task?['title'] as String?;
            }

            if (title != null) {
              await _revisionSource.createRevisionTasks(
                _userId,
                title,
                session.skill ?? 'general',
                session.endedAt ?? DateTime.now().toUtc(),
              );
            }
         } catch (_) {}
      }

      return const Right(unit);
    } catch (e) {
      return Left(DatabaseFailure('Failed to end session: $e'));
    }
  }

  @override
  Future<Either<Failure, StudySession?>> getLatestSessionForTask(
    String? taskId,
  ) async {
    try {
      final sessions = await _sessionSource.getSessionsForTask(taskId);
      return Right(sessions.isNotEmpty ? sessions.first : null);
    } catch (e) {
      return Left(DatabaseFailure('Failed to load latest session: $e'));
    }
  }

  @override
  Future<Either<Failure, List<StudySession>>> getSessionsForTask(
    String? taskId,
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
