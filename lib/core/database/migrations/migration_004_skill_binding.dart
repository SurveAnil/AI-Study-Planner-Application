import 'package:sqflite/sqflite.dart';

/// Migration 004 — Skill-binding fix + task_progress table.
///
/// Fixes:
///   • roadmap_cache: TEXT PK (single row) → INTEGER AUTOINCREMENT (multi-row)
///   • daily_plan_cache: adds `skill` column for per-skill isolation
///   • NEW task_progress table for persisting per-task completion state
///
/// RULE: Never edit this file. Add new migration files for schema changes.
class Migration004SkillBinding {
  static Future<void> up(Database db) async {
    // ─── Drop legacy tables ─────────────────────────────────────────────────
    await db.execute('DROP TABLE IF EXISTS roadmap_cache');
    await db.execute('DROP TABLE IF EXISTS daily_plan_cache');

    // ─── roadmap_cache (multi-row, one per generated roadmap) ────────────────
    await db.execute('''
      CREATE TABLE roadmap_cache (
        id           INTEGER PRIMARY KEY AUTOINCREMENT,
        skill        TEXT NOT NULL,
        roadmap_json TEXT NOT NULL,
        created_at   INTEGER NOT NULL
      )
    ''');

    // ─── daily_plan_cache (skill-scoped) ────────────────────────────────────
    await db.execute('''
      CREATE TABLE daily_plan_cache (
        id         INTEGER PRIMARY KEY AUTOINCREMENT,
        skill      TEXT NOT NULL,
        day        INTEGER NOT NULL,
        plan_json  TEXT NOT NULL,
        created_at INTEGER NOT NULL
      )
    ''');

    // ─── task_progress (per-task completion state) ───────────────────────────
    await db.execute('''
      CREATE TABLE task_progress (
        id         INTEGER PRIMARY KEY AUTOINCREMENT,
        skill      TEXT NOT NULL,
        day        INTEGER NOT NULL,
        task_index INTEGER NOT NULL,
        status     TEXT NOT NULL DEFAULT 'pending'
      )
    ''');
  }
}
