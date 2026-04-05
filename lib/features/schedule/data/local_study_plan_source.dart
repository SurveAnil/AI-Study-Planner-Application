import '../../../../core/database/database_helper.dart';

class LocalStudyPlanSource {
  Future<List<Map<String, dynamic>>> getTasksForDate(String userId, String date) async {
    final db = await DatabaseHelper.database;
    return await db.rawQuery('''
      SELECT t.* FROM tasks t
      JOIN study_plans sp ON t.plan_id = sp.id
      WHERE sp.user_id = ? AND sp.plan_date = ? AND t.is_deleted = 0
    ''', [userId, date]);
  }

  Future<void> updateTaskStatus(String taskId, String status) async {
    final db = await DatabaseHelper.database;
    await db.update('tasks', {'status': status, 'updated_at': DateTime.now().toIso8601String()}, where: 'id = ?', whereArgs: [taskId]);
  }

  Future<Map<String, dynamic>?> getTaskById(String taskId) async {
    final db = await DatabaseHelper.database;
    final res = await db.query('tasks', where: 'id = ?', whereArgs: [taskId]);
    return res.isNotEmpty ? res.first : null;
  }
}
