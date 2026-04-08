import 'package:sqflite/sqflite.dart';

/// Migration 007 — Plan-level status column on daily_plan_cache.
///
/// Adds:
///   • `status` TEXT column (DEFAULT 'pending') to daily_plan_cache.
///     Possible values: 'pending' | 'completed' | 'skipped'
///
/// This enables:
///   • Marking a day as skipped (Take Day Off)
///   • Smart next-day navigation (jump over completed + skipped days)
///   • Schedule screen to colour-code days by status
///
/// RULE: Never edit this file. Add new migration files for schema changes.
class Migration007PlanStatus {
  static Future<void> up(Database db) async {
    await db.execute(
      "ALTER TABLE daily_plan_cache ADD COLUMN status TEXT NOT NULL DEFAULT 'pending'",
    );
  }
}
