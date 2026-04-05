import 'package:sqflite/sqflite.dart';

/// Migration 001 — Initial schema.
/// Creates all 7 tables with UUID v4 PKs and universal columns.
/// RULE: Never edit this file. Add new migration files for schema changes.
class Migration001InitialSchema {
  static Future<void> up(Database db) async {
    final batch = db.batch();

    // ─── 1. users ─────────────────────────────────────────────────────
    batch.execute('''
      CREATE TABLE users (
        id          TEXT PRIMARY KEY,
        name        TEXT NOT NULL,
        email       TEXT,
        device_id   TEXT NOT NULL,
        created_at  TEXT NOT NULL,
        updated_at  TEXT NOT NULL,
        sync_status TEXT DEFAULT 'local',
        is_deleted  INTEGER DEFAULT 0
      )
    ''');

    // ─── 2. study_plans ───────────────────────────────────────────────
    batch.execute('''
      CREATE TABLE study_plans (
        id          TEXT PRIMARY KEY,
        user_id     TEXT NOT NULL REFERENCES users(id),
        plan_date   TEXT NOT NULL,
        total_time  INTEGER NOT NULL,
        created_at  TEXT NOT NULL,
        updated_at  TEXT NOT NULL,
        sync_status TEXT DEFAULT 'local',
        is_deleted  INTEGER DEFAULT 0
      )
    ''');

    // ─── 3. tasks ─────────────────────────────────────────────────────
    batch.execute('''
      CREATE TABLE tasks (
        id               TEXT PRIMARY KEY,
        plan_id          TEXT NOT NULL REFERENCES study_plans(id),
        title            TEXT NOT NULL,
        subject          TEXT NOT NULL,
        start_time       TEXT NOT NULL,
        end_time         TEXT NOT NULL,
        planned_duration INTEGER NOT NULL,
        status           TEXT DEFAULT 'pending',
        resource_link    TEXT,
        priority         INTEGER DEFAULT 2,
        created_at       TEXT NOT NULL,
        updated_at       TEXT NOT NULL,
        sync_status      TEXT DEFAULT 'local',
        is_deleted       INTEGER DEFAULT 0
      )
    ''');

    // ─── 4. study_sessions ────────────────────────────────────────────
    batch.execute('''
      CREATE TABLE study_sessions (
        id               TEXT PRIMARY KEY,
        task_id          TEXT NOT NULL REFERENCES tasks(id),
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

    // ─── 5. revision_tasks ────────────────────────────────────────────
    batch.execute('''
      CREATE TABLE revision_tasks (
        id             TEXT PRIMARY KEY,
        user_id        TEXT NOT NULL REFERENCES users(id),
        topic          TEXT NOT NULL,
        subject        TEXT NOT NULL,
        scheduled_date TEXT NOT NULL,
        revision_type  TEXT NOT NULL,
        status         TEXT DEFAULT 'pending',
        created_at     TEXT NOT NULL,
        updated_at     TEXT NOT NULL,
        sync_status    TEXT DEFAULT 'local',
        is_deleted     INTEGER DEFAULT 0
      )
    ''');

    // ─── 6. performance_data ──────────────────────────────────────────
    batch.execute('''
      CREATE TABLE performance_data (
        id             TEXT PRIMARY KEY,
        user_id        TEXT NOT NULL REFERENCES users(id),
        subject        TEXT NOT NULL,
        practice_score INTEGER,
        test_score     INTEGER,
        session_count  INTEGER DEFAULT 0,
        recorded_at    TEXT NOT NULL,
        created_at     TEXT NOT NULL,
        updated_at     TEXT NOT NULL,
        sync_status    TEXT DEFAULT 'local',
        is_deleted     INTEGER DEFAULT 0
      )
    ''');

    // ─── 7. sync_queue ────────────────────────────────────────────────
    batch.execute('''
      CREATE TABLE sync_queue (
        id          TEXT PRIMARY KEY,
        table_name  TEXT NOT NULL,
        record_id   TEXT NOT NULL,
        operation   TEXT NOT NULL,
        payload     TEXT NOT NULL,
        created_at  TEXT NOT NULL,
        retry_count INTEGER DEFAULT 0,
        last_error  TEXT
      )
    ''');

    await batch.commit(noResult: true);
  }
}
