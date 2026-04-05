import 'package:sqflite/sqflite.dart';

/// Database Migration 002
/// Adds onboarding profile fields, plan block types, and cluster caching columns
/// as specified in v2.0 Architecture.
class Migration002OnboardingFields {
  static Future<void> up(Database db) async {
    // Users table additions
    await db.execute("ALTER TABLE users ADD COLUMN subjects TEXT NOT NULL DEFAULT '[]'");
    await db.execute("ALTER TABLE users ADD COLUMN daily_goal_hours REAL NOT NULL DEFAULT 2.0");
    await db.execute("ALTER TABLE users ADD COLUMN study_window_start TEXT NOT NULL DEFAULT '09:00'");
    await db.execute("ALTER TABLE users ADD COLUMN study_window_end TEXT NOT NULL DEFAULT '21:00'");
    await db.execute("ALTER TABLE users ADD COLUMN long_term_goals TEXT");
    await db.execute("ALTER TABLE users ADD COLUMN learning_style TEXT NOT NULL DEFAULT 'mixed'");
    await db.execute("ALTER TABLE users ADD COLUMN exam_date TEXT");
    await db.execute("ALTER TABLE users ADD COLUMN onboarding_complete INTEGER NOT NULL DEFAULT 0");

    // Tasks table additions
    await db.execute("ALTER TABLE tasks ADD COLUMN block_type TEXT NOT NULL DEFAULT 'study'");

    // Study Plans table additions
    await db.execute("ALTER TABLE study_plans ADD COLUMN plan_source TEXT NOT NULL DEFAULT 'ai'");

    // Performance Data table additions
    await db.execute("ALTER TABLE performance_data ADD COLUMN cluster_label TEXT");
  }
}
