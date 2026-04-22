import 'package:sqflite/sqflite.dart';

/// Database Migration 012
/// Adds password field to users table for authentication.
class Migration012AuthFields {
  static Future<void> up(Database db) async {
    await db.execute("ALTER TABLE users ADD COLUMN password TEXT");
  }
}
