import '../database/database_helper.dart';

class LocationDao {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  Future<List<Map<String, dynamic>>> getAll() async {
    final db = await _dbHelper.database;
    return await db.query('location');
  }

  Future<List<Map<String, dynamic>>> getByUser(String userId) async {
    final db = await _dbHelper.database;
    return await db.query('location', where: 'userId = ?', whereArgs: [userId]);
  }

  Future<List<Map<String, dynamic>>> getByUserAndDate(String userId, String date) async {
    final db = await _dbHelper.database;
    return await db.query(
      'location',
      where: 'userId = ? AND date(timestamp) = ?',
      whereArgs: [userId, date],
    );
  }

  Future<List<Map<String, dynamic>>> getByUserInRange(String userId, DateTime start, DateTime end) async {
    final db = await _dbHelper.database;
    return await db.query(
      'location',
      where: 'userId = ? AND timestamp BETWEEN ? AND ?',
      whereArgs: [userId, start.toIso8601String(), end.toIso8601String()],
    );
  }

  Future<int> insert(Map<String, dynamic> data) async {
    final db = await _dbHelper.database;
    return await db.insert('location', data);
  }

  Future<int> deleteAllByUser(String userId) async {
    final db = await _dbHelper.database;
    return await db.delete('location', where: 'userId = ?', whereArgs: [userId]);
  }

  Future<int> deleteInRange(String userId, DateTime start, DateTime end) async {
    final db = await _dbHelper.database;
    return await db.delete(
      'location',
      where: 'userId = ? AND timestamp BETWEEN ? AND ?',
      whereArgs: [userId, start.toIso8601String(), end.toIso8601String()],
    );
  }

  Future<List<Map<String, dynamic>>> getUnsyncedLogs() async {
    final db = await _dbHelper.database;
    return await db.query('location', where: 'isSynced = 0');
  }

  Future<int> markAsSynced(List<int> ids) async {
    if (ids.isEmpty) return 0;
    final db = await _dbHelper.database;
    final idList = ids.join(',');
    return await db.rawUpdate('UPDATE location SET isSynced = 1 WHERE id IN ($idList)');
  }
}