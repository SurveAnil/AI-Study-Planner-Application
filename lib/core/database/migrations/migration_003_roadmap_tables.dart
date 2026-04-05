import 'package:sqflite/sqflite.dart';

/// Migration 003 — Roadmap & Daily Plan cache tables.
/// RULE: Never edit this file. Add new migration files for schema changes.
class Migration003RoadmapTables {
  static Future<void> up(Database db) async {
    // ─── roadmap_cache ─────────────────────────────────────────────────────
    // Stores roadmaps as JSON.
    await db.execute('''
      CREATE TABLE roadmap_cache (
        id           INTEGER PRIMARY KEY AUTOINCREMENT,
        skill        TEXT NOT NULL,
        roadmap_json TEXT NOT NULL,
        created_at   INTEGER NOT NULL
      )
    ''');

    // ─── daily_plan_cache ──────────────────────────────────────────────────
    // Stores one row per day number so Day 1, Day 2 etc. are cached
    // independently.
    await db.execute('''
      CREATE TABLE daily_plan_cache (
        id         TEXT PRIMARY KEY,
        day        INTEGER NOT NULL,
        plan_json  TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');
  }
}
