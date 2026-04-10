import 'package:sqflite/sqflite.dart';

/// Migration 010 — Relax session FK.
///
/// Current Issue: study_sessions table strictly references tasks(id) which
/// doesn't contain AI tasks (stored in JSON) or support quick focus.
///
/// Action: Recreate study_sessions table with NULLable task_id and no strict FK.
class Migration010RelaxSessionFk {
  static Future<void> up(Database db) async {
    // 1. Rename old table
    await db.execute('ALTER TABLE study_sessions RENAME TO study_sessions_old');

    // 2. Create new table without strictly enforced FK on task_id
    // Note: We keep the column task_id but make it nullable and remove the REFERENCES clause
    await db.execute('''
      CREATE TABLE study_sessions (
        id               TEXT PRIMARY KEY,
        task_id          TEXT,
        actual_duration  INTEGER NOT NULL,
        planned_duration INTEGER NOT NULL,
        pause_count      INTEGER DEFAULT 0,
        focus_score      REAL,
        completed        INTEGER DEFAULT 0,
        started_at       TEXT NOT NULL,
        ended_at         TEXT,
        created_at       TEXT NOT NULL,
        updated_at       TEXT NOT NULL,
        sync_status      TEXT DEFAULT 'local',
        is_deleted       INTEGER DEFAULT 0
      )
    ''');

    // 3. Migrate data
    await db.execute('''
      INSERT INTO study_sessions (
        id, task_id, actual_duration, planned_duration,
        pause_count, focus_score, completed, started_at,
        ended_at, created_at, updated_at, sync_status, is_deleted
      )
      SELECT 
        id, task_id, actual_duration, planned_duration,
        pause_count, focus_score, completed, started_at,
        ended_at, created_at, updated_at, sync_status, is_deleted
      FROM study_sessions_old
    ''');

    // 4. Drop old table
    await db.execute('DROP TABLE study_sessions_old');
  }
}
