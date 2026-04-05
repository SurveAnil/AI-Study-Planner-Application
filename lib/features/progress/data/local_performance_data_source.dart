import '../../../../core/database/database_helper.dart';
import '../../../../core/sync/sync_queue_service.dart';
import 'performance_data_repository.dart';

/// Local SQLite data source for performance_data table.
/// Logs user-entered practice scores from S07 Revision Calendar.
class LocalPerformanceDataSource {
  final SyncQueueService _syncQueue;

  LocalPerformanceDataSource({required SyncQueueService syncQueue})
      : _syncQueue = syncQueue;

  /// Insert a new performance record.
  /// Append-only behavior (Rule 8.3: Append-Only Bypass).
  Future<void> logScore(PerformanceData data) async {
    final db = await DatabaseHelper.database;
    final now = DateTime.now().toUtc().toIso8601String();

    final map = {
      'id': data.id,
      'user_id': data.userId,
      'subject': data.subject,
      'practice_score': data.practiceScore,
      'test_score': data.testScore,
      'session_count': data.sessionCount,
      'recorded_at': data.recordedAt.toIso8601String(),
      'created_at': data.createdAt.toIso8601String(),
      'updated_at': now,
      'sync_status': 'local',
      'is_deleted': 0,
    };

    await db.insert('performance_data', map);
    await _syncQueue.enqueue('performance_data', data.id, SyncOp.insert, map);
  }

  /// Query recent performance data.
  Future<List<PerformanceData>> getRecentData({int limit = 50}) async {
    final db = await DatabaseHelper.database;
    final rows = await db.query(
      'performance_data',
      where: 'is_deleted = 0',
      orderBy: 'recorded_at DESC',
      limit: limit,
    );
    return rows.map(_fromMap).toList();
  }

  // ─── Helpers ────────────────────────────────────────────────────────

  PerformanceData _fromMap(Map<String, dynamic> map) {
    return PerformanceData(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      subject: map['subject'] as String,
      practiceScore: map['practice_score'] as int?,
      testScore: map['test_score'] as int?,
      sessionCount: map['session_count'] as int? ?? 0,
      recordedAt: DateTime.parse(map['recorded_at'] as String),
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
      syncStatus: map['sync_status'] as String? ?? 'local',
      isDeleted: (map['is_deleted'] as int? ?? 0) == 1,
    );
  }
}
