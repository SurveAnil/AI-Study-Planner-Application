import 'package:sqflite/sqflite.dart';

/// Migration 009 — Central Learning State
///
/// Adds:
///   • `user_learning_state` table for tracking progression.
///   • `task_id` text column to `task_progress`.
///   • `generation_status` and `is_pre_generated` to `daily_plan_cache`.
class Migration009LearningState {
  static Future<void> up(Database db) async {
    await db.execute('''
      CREATE TABLE user_learning_state (
        skill TEXT PRIMARY KEY,
        start_date TEXT NOT NULL,
        current_day INTEGER NOT NULL,
        last_active_date TEXT NOT NULL,
        daily_hours INTEGER NOT NULL
      )
    ''');

    await db.execute(
      "ALTER TABLE task_progress ADD COLUMN task_id TEXT",
    );

    await db.execute(
      "ALTER TABLE daily_plan_cache ADD COLUMN generation_status TEXT",
    );

    await db.execute(
      "ALTER TABLE daily_plan_cache ADD COLUMN is_pre_generated INTEGER DEFAULT 0",
    );
  }
}
