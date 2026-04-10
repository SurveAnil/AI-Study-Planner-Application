import 'package:sqflite/sqflite.dart';

/// Migration 008 — Start Date for Roadmaps
///
/// Adds:
///   • `start_date` TEXT column to roadmap_cache.
///
/// This ensures proper scheduling without lazy assignment.
class Migration008StartDate {
  static Future<void> up(Database db) async {
    await db.execute(
      "ALTER TABLE roadmap_cache ADD COLUMN start_date TEXT",
    );
  }
}
