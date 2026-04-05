import 'package:uuid/uuid.dart';
import '../../../core/database/database_helper.dart';
import '../../../core/error/failures.dart';
import '../../../core/sync/sync_queue_service.dart';
import '../models/draft_models.dart';

/// Transactionally writes an in-memory [PlanDraftResponse] to SQLite,
/// then enqueues both the plan and all tasks to the sync queue.
class CommitService {
  final Uuid _uuid = const Uuid();
  final SyncQueueService _syncQueue;

  CommitService({required SyncQueueService syncQueue}) : _syncQueue = syncQueue;

  /// Returns the new [planId] on success.
  /// Throws [DatabaseFailure] on any error.
  Future<String> commitPlan(
    String userId,
    PlanDraftResponse draft,
    String planDate, {
    String planSource = 'manual',
  }) async {
    final db = await DatabaseHelper.database;
    final planId = _uuid.v4();
    final now = DateTime.now().toUtc().toIso8601String();

    try {
      await db.transaction((txn) async {
        // 1. Insert study_plans row
        final planRow = {
          'id': planId,
          'user_id': userId,
          'plan_date': planDate,
          'plan_source': planSource,
          'total_time': draft.blocks.fold<int>(
            0,
            (sum, b) => sum + b.durationMinutes,
          ),
          'created_at': now,
          'updated_at': now,
          'sync_status': 'local',
          'is_deleted': 0,
        };
        await txn.insert('study_plans', planRow);

        // 2. Insert tasks rows
        for (final block in draft.blocks) {
          final taskId = _uuid.v4();
          final taskRow = {
            'id': taskId,
            'plan_id': planId,
            'user_id': userId,
            'title': block.title,
            'subject': block.subject ?? 'General',
            'block_type': block.type,
            // Map to schema: tasks uses status not block_type
            'start_time': block.startTime,
            'end_time': block.endTime,
            'planned_duration': block.durationMinutes,
            'priority': block.priority ?? 2,
            'status': 'pending',
            'created_at': now,
            'updated_at': now,
            'sync_status': 'local',
            'is_deleted': 0,
          };
          await txn.insert('tasks', taskRow);
        }
      });

      // 3. Enqueue for future cloud sync (outside the txn — non-critical)
      await _syncQueue.enqueue('study_plans', planId, SyncOp.insert, {
        'id': planId,
        'user_id': userId,
        'plan_date': planDate,
        'plan_source': planSource,
      });

      return planId;
    } catch (e) {
      throw DatabaseFailure('Failed to commit study plan: $e');
    }
  }
}
