import 'package:sqflite/sqflite.dart';

/// Migration 011 — Adds skill and day to study_sessions table.
class Migration011StudySessionMetadata {
  static Future<void> up(Database db) async {
    await db.execute('ALTER TABLE study_sessions ADD COLUMN skill TEXT');
    await db.execute('ALTER TABLE study_sessions ADD COLUMN day INTEGER');
  }
}
