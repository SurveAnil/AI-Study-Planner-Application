import 'package:sqflite/sqflite.dart';

/// Migration 005 — Day flow: date binding + day completion tracking.
///
/// Adds:
///   • `date` TEXT column to daily_plan_cache (maps plan to a calendar date)
///   • `stage_index` INTEGER column to daily_plan_cache
///   • NEW `day_completion` table to track which days the user has finished
///
/// RULE: Never edit this file. Add new migration files for schema changes.
class Migration005DayFlow {
  static Future<void> up(Database db) async {
    // ─── Add date + stage_index columns to daily_plan_cache ──────────────
    await db.execute(
        'ALTER TABLE daily_plan_cache ADD COLUMN date TEXT');
    await db.execute(
        'ALTER TABLE daily_plan_cache ADD COLUMN stage_index INTEGER DEFAULT 0');

    // ─── day_completion table ────────────────────────────────────────────
    await db.execute('''
      CREATE TABLE IF NOT EXISTS day_completion (
        id           INTEGER PRIMARY KEY AUTOINCREMENT,
        skill        TEXT NOT NULL,
        day          INTEGER NOT NULL,
        stage_index  INTEGER NOT NULL DEFAULT 0,
        completed_at INTEGER NOT NULL
      )
    ''');
  }
}
