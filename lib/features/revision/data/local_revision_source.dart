import 'package:uuid/uuid.dart';

import '../../../core/database/database_helper.dart';
import '../../../core/sync/sync_queue_service.dart';
import 'revision_repository.dart';

const _uuid = Uuid();

/// Local SQLite data source for revision_tasks table.
/// Creates 4 spaced repetition tasks at Day+2/7/14/30 on session completion.
class LocalRevisionSource {
  final SyncQueueService _syncQueue;

  LocalRevisionSource({required SyncQueueService syncQueue})
      : _syncQueue = syncQueue;

  /// Spaced repetition intervals and their type labels.
  static const _intervals = [
    (days: 2, type: 'revision'),
    (days: 7, type: 'practice'),
    (days: 14, type: 'test'),
    (days: 30, type: 'final'),
  ];

  /// Creates 4 revision tasks at Day+2, +7, +14, +30 from sessionDate.
  /// Called immediately when a session is marked complete.
  Future<void> createRevisionTasks(
    String userId,
    String topic,
    String subject,
    DateTime sessionDate,
  ) async {
    final db = await DatabaseHelper.database;
    final now = DateTime.now().toUtc();
    final batch = db.batch();

    final records = <Map<String, dynamic>>[];

    for (final interval in _intervals) {
      final scheduledDate = sessionDate.add(Duration(days: interval.days));
      final id = _uuid.v4();

      final record = {
        'id': id,
        'user_id': userId,
        'topic': topic,
        'subject': subject,
        'scheduled_date': _formatDate(scheduledDate),
        'revision_type': interval.type,
        'status': 'pending',
        'created_at': now.toIso8601String(),
        'updated_at': now.toIso8601String(),
        'sync_status': 'local',
        'is_deleted': 0,
      };

      batch.insert('revision_tasks', record);
      records.add(record);
    }

    await batch.commit(noResult: true);

    // Enqueue all to sync queue
    for (final record in records) {
      await _syncQueue.enqueue(
        'revision_tasks',
        record['id'] as String,
        SyncOp.insert,
        record,
      );
    }
  }

  /// Query revision tasks for a given month.
  Future<List<RevisionTask>> getRevisionTasksForMonth(DateTime month) async {
    final db = await DatabaseHelper.database;
    final yearMonth =
        '${month.year}-${month.month.toString().padLeft(2, '0')}';

    final rows = await db.query(
      'revision_tasks',
      where: "scheduled_date LIKE ? AND is_deleted = 0",
      whereArgs: ['$yearMonth%'],
      orderBy: 'scheduled_date ASC',
    );

    return rows.map(_revisionFromMap).toList();
  }

  /// Get upcoming revision tasks within N days from today.
  Future<List<RevisionTask>> getUpcomingRevisions({int days = 7}) async {
    final db = await DatabaseHelper.database;
    final today = _formatDate(DateTime.now());
    final endDate = _formatDate(DateTime.now().add(Duration(days: days)));

    final rows = await db.query(
      'revision_tasks',
      where:
          "scheduled_date >= ? AND scheduled_date <= ? AND is_deleted = 0 AND status = 'pending'",
      whereArgs: [today, endDate],
      orderBy: 'scheduled_date ASC',
    );

    return rows.map(_revisionFromMap).toList();
  }

  /// Mark a revision task as done. Updates status, updated_at, sync_status.
  Future<void> markRevisionDone(String revisionId) async {
    final db = await DatabaseHelper.database;
    final now = DateTime.now().toUtc().toIso8601String();

    final updateMap = {
      'status': 'done',
      'updated_at': now,
      'sync_status': 'local',
    };

    await db.update(
      'revision_tasks',
      updateMap,
      where: 'id = ?',
      whereArgs: [revisionId],
    );

    await _syncQueue.enqueue(
      'revision_tasks',
      revisionId,
      SyncOp.update,
      updateMap,
    );
  }

  // ─── Helpers ────────────────────────────────────────────────────────

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  RevisionTask _revisionFromMap(Map<String, dynamic> map) {
    return RevisionTask(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      topic: map['topic'] as String,
      subject: map['subject'] as String,
      scheduledDate: map['scheduled_date'] as String,
      revisionType: map['revision_type'] as String,
      status: map['status'] as String? ?? 'pending',
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
      syncStatus: map['sync_status'] as String? ?? 'local',
      isDeleted: (map['is_deleted'] as int? ?? 0) == 1,
    );
  }
}
