import 'package:sqflite/sqflite.dart';

/// Migration 006 — App settings key-value table.
///
/// Adds:
///   • `app_settings` table for storing application preferences
///     (e.g. active_skill, theme, etc.)
///
/// RULE: Never edit this file. Add new migration files for schema changes.
class Migration006AppSettings {
  static Future<void> up(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS app_settings (
        key   TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');
  }
}
