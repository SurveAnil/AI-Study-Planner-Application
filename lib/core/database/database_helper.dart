import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import 'migrations/migration_001_initial_schema.dart';
import 'migrations/migration_002_onboarding_fields.dart';
import 'migrations/migration_003_roadmap_tables.dart';
import 'migrations/migration_004_skill_binding.dart';
import 'migrations/migration_005_day_flow.dart';
import 'migrations/migration_006_app_settings.dart';

/// Central database helper with version-based migration runner.
/// See Part 3.3 of SKILL.md.
class DatabaseHelper {
  static const int _dbVersion = 6; // Incremented for migration_006_app_settings

  static Database? _database;

  /// Returns the singleton database instance, creating it if necessary.
  static Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _openDb();
    return _database!;
  }

  static Future<Database> _openDb() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'study_planner.db');

    return openDatabase(
      path,
      version: _dbVersion,
      onCreate: (db, v) => _runMigrations(db, 0, v),
      onUpgrade: (db, o, n) => _runMigrations(db, o, n),
      onConfigure: (db) async {
        // Enable foreign key constraints
        await db.execute('PRAGMA foreign_keys = ON');
      },
    );
  }

  /// Runs all migrations between [from] (exclusive) and [to] (inclusive).
  static Future<void> _runMigrations(Database db, int from, int to) async {
    final migrations = <int, Future<void> Function(Database)>{
      1: Migration001InitialSchema.up,
      2: Migration002OnboardingFields.up,
      3: Migration003RoadmapTables.up,
      4: Migration004SkillBinding.up,
      5: Migration005DayFlow.up,
      6: Migration006AppSettings.up,
    };

    for (int v = from + 1; v <= to; v++) {
      final migration = migrations[v];
      if (migration != null) {
        await migration(db);
      }
    }
  }

  /// Closes the database connection. Used in testing/cleanup.
  static Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }
}
