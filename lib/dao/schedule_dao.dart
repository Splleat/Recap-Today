import 'package:sqflite/sqflite.dart';
import '../database/database_helper.dart';

class ScheduleDao {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  Future<List<Map<String, dynamic>>> getAllSchedules() async {
    final db = await _dbHelper.database;
    return await db.query('schedule');
  }

  Future<int> insertSchedule(Map<String, dynamic> schedule) async {
    final db = await _dbHelper.database;
    return await db.insert('schedule', schedule);
  }

  Future<int> updateSchedule(Map<String, dynamic> schedule) async {
    final db = await _dbHelper.database;
    return await db.update('schedule', schedule, where: 'id = ?', whereArgs: [schedule['id']]);
  }

  Future<int> deleteSchedule(String id) async {
    final db = await _dbHelper.database;
    return await db.delete('schedule', where: 'id = ?', whereArgs: [id]);
  }
}
