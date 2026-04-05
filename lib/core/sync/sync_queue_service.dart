import 'dart:convert';

import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import '../database/database_helper.dart';
import '../network/network_info.dart';

/// Operation types for sync queue entries.
enum SyncOp { insert, update, delete }

/// Buffers all local writes for future cloud sync.
/// See Part 8.2 of SKILL.md.
///
/// Every SQLite write must:
/// 1. Write with sync_status = 'local'
/// 2. Set updated_at = DateTime.now().toUtc()
/// 3. Enqueue to sync_queue via this service
class SyncQueueService {
  final NetworkInfo _networkInfo;
  static const _uuid = Uuid();

  SyncQueueService({required NetworkInfo networkInfo})
      : _networkInfo = networkInfo;

  /// Enqueue a record change for later sync.
  /// Called on every SQLite write.
  Future<void> enqueue(
    String tableName,
    String recordId,
    SyncOp operation,
    Map<String, dynamic> payload,
  ) async {
    final db = await DatabaseHelper.database;
    await db.insert('sync_queue', {
      'id': _uuid.v4(),
      'table_name': tableName,
      'record_id': recordId,
      'operation': operation.name,
      'payload': jsonEncode(payload),
      'created_at': DateTime.now().toUtc().toIso8601String(),
      'retry_count': 0,
    });
  }

  /// Drain the sync queue when connectivity is restored.
  /// Called by ConnectivityPlus listener on reconnect.
  Future<void> drainQueue() async {
    final isConnected = await _networkInfo.isConnected;
    if (!isConnected) return;

    final db = await DatabaseHelper.database;
    final pending = await db.query(
      'sync_queue',
      orderBy: 'created_at ASC',
    );

    for (final row in pending) {
      try {
        // Implementation for remote push will go here
        // await _remote.pushRecord(row);

        // On success, remove from queue
        await db.delete(
          'sync_queue',
          where: 'id = ?',
          whereArgs: [row['id']],
        );
      } catch (e) {
        final retries = (row['retry_count'] as int) + 1;
        if (retries >= 5) {
          // Escalate to conflict resolution
          await _flagAsConflict(db, row);
        } else {
          await db.update(
            'sync_queue',
            {
              'retry_count': retries,
              'last_error': e.toString(),
            },
            where: 'id = ?',
            whereArgs: [row['id']],
          );
        }
      }
    }
  }

  /// Escalates a sync queue entry as a conflict after 5 failed retries.
  Future<void> _flagAsConflict(
    Database db,
    Map<String, dynamic> row,
  ) async {
    // Update the original record's sync_status to 'conflict'
    final tableName = row['table_name'] as String;
    final recordId = row['record_id'] as String;

    await db.update(
      tableName,
      {'sync_status': 'conflict'},
      where: 'id = ?',
      whereArgs: [recordId],
    );

    // Remove from sync queue — conflict is now tracked on the record itself
    await db.delete(
      'sync_queue',
      where: 'id = ?',
      whereArgs: [row['id']],
    );
  }
}
