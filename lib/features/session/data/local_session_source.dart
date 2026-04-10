import 'package:uuid/uuid.dart';

import '../../../core/database/database_helper.dart';
import '../../../core/sync/sync_queue_service.dart';
import 'session_repository.dart';

const _uuid = Uuid();

/// Local SQLite data source for study_sessions table.
/// Handles creation on session start and full record write on session end.
class LocalSessionSource {
  final SyncQueueService _syncQueue;

  LocalSessionSource({required SyncQueueService syncQueue})
      : _syncQueue = syncQueue;

  /// Create a new session record when timer starts.
  /// Returns the created session with a new UUID.
  Future<StudySession> createSession(
      String? taskId, int plannedDurationSec, {String? skill, int? day}) async {
    final db = await DatabaseHelper.database;
    final now = DateTime.now().toUtc();
    final id = _uuid.v4();

    final session = StudySession(
      id: id,
      taskId: taskId,
      skill: skill,
      day: day,
      actualDuration: 0,
      plannedDuration: plannedDurationSec,
      pauseCount: 0,
      completed: false,
      startedAt: now,
      createdAt: now,
      updatedAt: now,
      syncStatus: 'local',
    );

    final sessionMap = {
      'id': session.id,
      'task_id': session.taskId,
      'skill': session.skill,
      'day': session.day,
      'actual_duration': session.actualDuration,
      'planned_duration': session.plannedDuration,
      'pause_count': session.pauseCount,
      'focus_score': null,
      'completed': 0,
      'started_at': session.startedAt.toIso8601String(),
      'ended_at': null,
      'created_at': session.createdAt.toIso8601String(),
      'updated_at': session.updatedAt.toIso8601String(),
      'sync_status': 'local',
      'is_deleted': 0,
    };

    await db.insert('study_sessions', sessionMap);
    await _syncQueue.enqueue(
        'study_sessions', session.id, SyncOp.insert, sessionMap);

    return session;
  }

  /// Write the final session record on EndSession.
  /// Critical write: actual_duration, focus_score, pause_count,
  /// completed=1, ended_at — all required.
  Future<void> endSession(StudySession session) async {
    final db = await DatabaseHelper.database;
    final now = DateTime.now().toUtc().toIso8601String();

    final updateMap = {
      'actual_duration': session.actualDuration,
      'planned_duration': session.plannedDuration,
      'pause_count': session.pauseCount,
      'focus_score': session.focusScore,
      'completed': session.completed ? 1 : 0,
      'ended_at': session.endedAt?.toIso8601String(),
      'updated_at': now,
      'sync_status': 'local',
    };

    await db.update(
      'study_sessions',
      updateMap,
      where: 'id = ?',
      whereArgs: [session.id],
    );

    await _syncQueue.enqueue(
        'study_sessions', session.id, SyncOp.update, updateMap);
  }

  /// Get all sessions for a specific task.
  Future<List<StudySession>> getSessionsForTask(String? taskId) async {
    final db = await DatabaseHelper.database;
    final rows = await db.query(
      'study_sessions',
      where: 'task_id = ? AND is_deleted = 0',
      whereArgs: [taskId],
      orderBy: 'started_at DESC',
    );
    return rows.map(_sessionFromMap).toList();
  }

  /// Get recent sessions across all tasks.
  Future<List<StudySession>> getRecentSessions({int limit = 30}) async {
    final db = await DatabaseHelper.database;
    final rows = await db.query(
      'study_sessions',
      where: 'is_deleted = 0 AND completed = 1',
      orderBy: 'ended_at DESC',
      limit: limit,
    );
    return rows.map(_sessionFromMap).toList();
  }

  /// Count total completed sessions (for ML minimum data check).
  Future<int> getSessionCount() async {
    final db = await DatabaseHelper.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM study_sessions WHERE completed = 1 AND is_deleted = 0',
    );
    return (result.first['count'] as int?) ?? 0;
  }

  // ─── Helpers ────────────────────────────────────────────────────────

  StudySession _sessionFromMap(Map<String, dynamic> map) {
    return StudySession(
      id: map['id'] as String,
      taskId: map['task_id'] as String?,
      skill: map['skill'] as String?,
      day: map['day'] as int?,
      actualDuration: map['actual_duration'] as int,
      plannedDuration: map['planned_duration'] as int,
      pauseCount: map['pause_count'] as int? ?? 0,
      focusScore: map['focus_score'] as double?,
      completed: (map['completed'] as int? ?? 0) == 1,
      startedAt: DateTime.parse(map['started_at'] as String),
      endedAt: map['ended_at'] != null
          ? DateTime.parse(map['ended_at'] as String)
          : null,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
      syncStatus: map['sync_status'] as String? ?? 'local',
      isDeleted: (map['is_deleted'] as int? ?? 0) == 1,
    );
  }
}
