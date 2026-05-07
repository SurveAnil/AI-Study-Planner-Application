import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:crypto/crypto.dart';
import 'package:sqflite/sqflite.dart';

import '../../../core/database/database_helper.dart';
import '../../../core/util/app_logger.dart';

/// Handles reading and writing roadmap, daily-plan, and task-progress data
/// from/to SQLite.
class RoadmapLocalService {
  // ── Singleton ─────────────────────────────────────────────────────────────

  RoadmapLocalService._();
  static final RoadmapLocalService instance = RoadmapLocalService._();

  // ── Roadmap ───────────────────────────────────────────────────────────────

  /// Inserts a new roadmap row.
  Future<void> saveRoadmap(String skill, Map<String, dynamic> roadmap, {String? startDate}) async {
    final db = await DatabaseHelper.database;
    final now = DateTime.now().millisecondsSinceEpoch;

    await db.insert('roadmap_cache', {
      'skill': skill,
      'roadmap_json': json.encode(roadmap),
      'created_at': now,
      'start_date': startDate,
    });
    
    logger.i("Roadmap saved successfully to roadmap_cache");
  }

  /// Returns the most recently generated roadmap, or null if none exists.
  Future<Map<String, dynamic>?> getLatestRoadmap() async {
    final db = await DatabaseHelper.database;
    final rows = await db.query(
      'roadmap_cache',
      orderBy: 'created_at DESC',
      limit: 1,
    );
    if (rows.isEmpty) return null;
    try {
      final source = rows.first['roadmap_json'] as String;
      final decoded = await compute(_decodeMap, source);
      if (decoded == null) return null;
      
      decoded['skill'] ??= rows.first['skill'];
      return decoded;
    } catch (_) {
      return null;
    }
  }

  /// Returns every saved roadmap, newest first.
  Future<List<Map<String, dynamic>>> getAllRoadmaps() async {
    final db = await DatabaseHelper.database;
    return db.query(
      'roadmap_cache',
      orderBy: 'created_at DESC',
    );
  }

  /// Deletes all daily plans, task progress, AND day completions for [skill].
  Future<void> clearPlansForSkill(String skill) async {
    final db = await DatabaseHelper.database;
    await db.delete('daily_plan_cache',
        where: 'skill = ?', whereArgs: [skill]);
    await db.delete('task_progress', where: 'skill = ?', whereArgs: [skill]);
    await db.delete('day_completion', where: 'skill = ?', whereArgs: [skill]);
  }

  // ── Learning State ────────────────────────────────────────────────────────

  Future<void> initLearningState(String skill, String startDate, int dailyHours) async {
    final db = await DatabaseHelper.database;
    await db.insert(
      'user_learning_state',
      {
        'skill': skill,
        'start_date': startDate,
        'current_day': 1,
        'last_active_date': startDate,
        'daily_hours': dailyHours,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<Map<String, dynamic>?> getLearningState(String skill) async {
    final db = await DatabaseHelper.database;
    final rows = await db.query(
      'user_learning_state',
      where: 'skill = ?',
      whereArgs: [skill],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return rows.first;
  }

  Future<bool> progressDayIfNeeded(String skill) async {
    final state = await getLearningState(skill);
    if (state == null) return false;

    final startDateStr = state['start_date'] as String;
    final lastActiveStr = state['last_active_date'] as String;
    final currentDay = state['current_day'] as int;

    final today = DateTime.now();
    final todayStr = today.toIso8601String().split('T')[0];
    final todayDate = DateTime.parse(todayStr);
    final startDate = DateTime.parse(startDateStr);
    
    if (startDate.isAfter(todayDate)) {
      return false;
    }

    final lastActiveDate = DateTime.parse(lastActiveStr);

    if (todayDate.isBefore(lastActiveDate)) {
      return true; // time_anomaly = true
    }

    if (todayDate.isAfter(lastActiveDate)) {
      final daysPassed = todayDate.difference(lastActiveDate).inDays;
      if (daysPassed > 0) {
        final db = await DatabaseHelper.database;
        await db.update(
          'user_learning_state',
          {
            'current_day': currentDay + daysPassed,
            'last_active_date': todayStr,
          },
          where: 'skill = ?',
          whereArgs: [skill],
        );
      }
    }
    return false;
  }

  Future<void> updateCurrentDay(String skill, int newDay) async {
    final db = await DatabaseHelper.database;
    final todayStr = DateTime.now().toIso8601String().split('T')[0];
    await db.update(
      'user_learning_state',
      {
        'current_day': newDay,
        'last_active_date': todayStr,
      },
      where: 'skill = ?',
      whereArgs: [skill],
    );
  }

  // ── Daily Plan ────────────────────────────────────────────────────────────

  Future<void> saveDailyPlan(
    String skill,
    int day,
    Map<String, dynamic> planData, {
    String? date,
    int stageIndex = 0,
    String? generationStatus,
    int isPreGenerated = 0,
  }) async {
    final db = await DatabaseHelper.database;
    final now = DateTime.now().millisecondsSinceEpoch;

    await db.delete(
      'daily_plan_cache',
      where: 'skill = ? AND day = ?',
      whereArgs: [skill, day],
    );

    await db.insert('daily_plan_cache', {
      'skill': skill,
      'day': day,
      'plan_json': json.encode(planData),
      'created_at': now,
      'date': date,
      'stage_index': stageIndex,
      'generation_status': generationStatus,
      'is_pre_generated': isPreGenerated,
    });
  }

  Future<Map<String, dynamic>?> getDailyPlan(String skill, int day) async {
    final db = await DatabaseHelper.database;
    final rows = await db.query(
      'daily_plan_cache',
      where: 'skill = ? AND day = ?',
      whereArgs: [skill, day],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    try {
      final source = rows.first['plan_json'] as String;
      final decodedMap = await compute(_decodeMap, source);
      if (decodedMap != null) {
        decodedMap['generation_status'] = rows.first['generation_status'];
        decodedMap['is_pre_generated'] = rows.first['is_pre_generated'];
        decodedMap['status'] = rows.first['status'];

        bool migrated = false;
        final tasks = decodedMap['tasks'] as List? ?? [];
        for (int i = 0; i < tasks.length; i++) {
          final t = tasks[i];
          if (t is Map<String, dynamic>) {
            if (!t.containsKey('task_position') || !t.containsKey('task_id')) {
              t['task_position'] = i;
              final title = t['title'] ?? 'untitled';
              final type = t['type'] ?? 'learn';
              t['task_id'] = generateTaskId(title, type, day, i);
              migrated = true;
            }
          }
        }

        if (migrated) {
          await db.update(
            'daily_plan_cache',
            {'plan_json': json.encode(decodedMap)},
            where: 'skill = ? AND day = ?',
            whereArgs: [skill, day],
          );
        }
      }
      return decodedMap;
    } catch (_) {
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> getPlansForDate(String dateStr) async {
    final db = await DatabaseHelper.database;
    return db.query(
      'daily_plan_cache',
      where: 'date = ?',
      whereArgs: [dateStr],
    );
  }

  Future<void> finalizePlan(String skill, int day) async {
    final db = await DatabaseHelper.database;
    await db.update(
      'daily_plan_cache',
      {'status': 'finalized'},
      where: 'skill = ? AND day = ?',
      whereArgs: [skill, day],
    );
  }

  Future<bool> isPlanFinalized(String skill, int day) async {
    final db = await DatabaseHelper.database;
    final rows = await db.query(
      'daily_plan_cache',
      columns: ['status'],
      where: 'skill = ? AND day = ?',
      whereArgs: [skill, day],
      limit: 1,
    );
    if (rows.isEmpty) return false;
    final status = rows.first['status'] as String?;
    return status == 'finalized' || status == 'completed' || status == 'skipped';
  }

  // ── Smart Scheduling ──────────────────────────────────────────────────────

  String calculateDate(String startDateStr, int dayNumber) {
    if (startDateStr.isEmpty) return '';
    try {
      final start = DateTime.parse(startDateStr);
      final target = start.add(Duration(days: dayNumber - 1));
      return target.toIso8601String().split('T')[0];
    } catch (_) {
      return '';
    }
  }

  // ── Task Progress ─────────────────────────────────────────────────────────

  static String generateTaskId(String title, String type, int day, int position) {
    if (title.isEmpty) title = 'untitled';
    if (type.isEmpty) type = 'learn';
    final bytes = utf8.encode('$title$type$day$position');
    return md5.convert(bytes).toString();
  }

  Future<void> updateTaskStatus(
      String skill, int day, int index, String taskId, String status) async {
    final db = await DatabaseHelper.database;

    final existing = await db.query(
      'task_progress',
      where: 'skill = ? AND day = ? AND task_id = ?',
      whereArgs: [skill, day, taskId],
      limit: 1,
    );

    if (existing.isNotEmpty) {
      await db.update(
        'task_progress',
        {'status': status},
        where: 'id = ?',
        whereArgs: [existing.first['id']],
      );
    } else {
      final oldRows = await db.query(
          'task_progress',
          where: 'skill = ? AND day = ? AND task_index = ?',
          whereArgs: [skill, day, index],
          limit: 1);
      if (oldRows.isNotEmpty) {
        await db.update(
          'task_progress',
          {'status': status, 'task_id': taskId},
          where: 'id = ?',
          whereArgs: [oldRows.first['id']],
        );
      } else {
        await db.insert('task_progress', {
          'skill': skill,
          'day': day,
          'task_index': index,
          'task_id': taskId,
          'status': status,
        });
      }
    }
  }

  Future<String?> getTaskStatus(String skill, int day, int index, String taskId) async {
    final db = await DatabaseHelper.database;
    final rows = await db.query(
      'task_progress',
      columns: ['id', 'status'],
      where: 'skill = ? AND day = ? AND task_id = ?',
      whereArgs: [skill, day, taskId],
      limit: 1,
    );
    if (rows.isNotEmpty) return rows.first['status'] as String?;

    final oldRows = await db.query(
      'task_progress',
      columns: ['id', 'status'],
      where: 'skill = ? AND day = ? AND task_index = ?',
      whereArgs: [skill, day, index],
      limit: 1,
    );
    if (oldRows.isNotEmpty) {
      await db.update('task_progress', {'task_id': taskId},
          where: 'id = ?', whereArgs: [oldRows.first['id']]);
      return oldRows.first['status'] as String?;
    }
    return null;
  }

  // ── Day Completion ────────────────────────────────────────────────────────

  Future<void> markDayComplete(String skill, int day,
      {int stageIndex = 0}) async {
    final db = await DatabaseHelper.database;
    final now = DateTime.now().millisecondsSinceEpoch;

    final existing = await db.query(
      'day_completion',
      where: 'skill = ? AND day = ?',
      whereArgs: [skill, day],
      limit: 1,
    );
    if (existing.isNotEmpty) return;

    await db.insert('day_completion', {
      'skill': skill,
      'day': day,
      'stage_index': stageIndex,
      'completed_at': now,
    });
  }

  Future<bool> isDayCompleted(String skill, int day) async {
    final db = await DatabaseHelper.database;
    final rows = await db.query(
      'day_completion',
      where: 'skill = ? AND day = ?',
      whereArgs: [skill, day],
      limit: 1,
    );
    return rows.isNotEmpty;
  }

  Future<void> markDaySkipped(String skill, int day) async {
    final db = await DatabaseHelper.database;
    final existing = await db.query(
      'daily_plan_cache',
      where: 'skill = ? AND day = ?',
      whereArgs: [skill, day],
      limit: 1,
    );

    if (existing.isNotEmpty) {
      await db.update(
        'daily_plan_cache',
        {'status': 'skipped'},
        where: 'skill = ? AND day = ?',
        whereArgs: [skill, day],
      );
    } else {
      await db.insert('daily_plan_cache', {
        'skill': skill,
        'day': day,
        'plan_json': '{"tasks":[]}',
        'created_at': DateTime.now().millisecondsSinceEpoch,
        'status': 'skipped',
      });
    }
  }

  Future<int> getNextPendingDay(String skill) async {
    final db = await DatabaseHelper.database;
    final rows = await db.query(
      'daily_plan_cache',
      columns: ['day', 'status'],
      where: 'skill = ?',
      whereArgs: [skill],
      orderBy: 'day ASC',
    );

    if (rows.isEmpty) return 1;

    final int maxDay = (rows.last['day'] as int?) ?? 1;
    final Map<int, String> statusMap = {
      for (final r in rows)
        (r['day'] as int): (r['status'] as String? ?? 'pending'),
    };

    for (int d = 1; d <= maxDay; d++) {
      final s = statusMap[d] ?? 'pending';
      if (s != 'completed' && s != 'skipped') return d;
    }

    return maxDay + 1;
  }

  Future<int> getLastCompletedDay(String skill) async {
    final db = await DatabaseHelper.database;
    final rows = await db.rawQuery(
      'SELECT MAX(day) as max_day FROM day_completion WHERE skill = ?',
      [skill],
    );
    if (rows.isEmpty || rows.first['max_day'] == null) return 0;
    return rows.first['max_day'] as int;
  }

  // ── Active Skill ──────────────────────────────────────────────────────────

  Future<void> setActiveSkill(String skill) async {
    final db = await DatabaseHelper.database;
    await db.rawInsert(
      'INSERT OR REPLACE INTO app_settings (key, value) VALUES (?, ?)',
      ['active_skill', skill],
    );
  }

  Future<String?> getActiveSkill() async {
    final db = await DatabaseHelper.database;
    final rows = await db.query(
      'app_settings',
      where: 'key = ?',
      whereArgs: ['active_skill'],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return rows.first['value'] as String?;
  }

  // ── Skill-Specific Queries ────────────────────────────────────────────────

  Future<Map<String, dynamic>?> getRoadmapForSkill(String skill) async {
    final db = await DatabaseHelper.database;
    final rows = await db.query(
      'roadmap_cache',
      where: 'skill = ?',
      whereArgs: [skill],
      orderBy: 'created_at DESC',
      limit: 1,
    );
    if (rows.isEmpty) return null;
    try {
      final decoded = json.decode(rows.first['roadmap_json'] as String)
          as Map<String, dynamic>;
      decoded['skill'] ??= rows.first['skill'];
      return decoded;
    } catch (_) {
      return null;
    }
  }

  Future<List<String>> getDistinctSkills() async {
    final db = await DatabaseHelper.database;
    final rows = await db.rawQuery(
      'SELECT DISTINCT skill FROM roadmap_cache ORDER BY created_at DESC',
    );
    return rows.map((r) => r['skill'] as String).toList();
  }

  Future<List<Map<String, dynamic>>> getPlansForDateAndSkill(
      String dateStr, String skill) async {
    final db = await DatabaseHelper.database;
    return db.query(
      'daily_plan_cache',
      where: 'date = ? AND skill = ?',
      whereArgs: [dateStr, skill],
    );
  }
}

Map<String, dynamic>? _decodeMap(String source) {
  try {
    return json.decode(source) as Map<String, dynamic>;
  } catch (_) {
    return null;
  }
}
