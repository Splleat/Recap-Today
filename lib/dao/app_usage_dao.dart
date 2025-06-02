// app_usage_dao.dart
import 'package:sqflite/sqflite.dart';
import '../database/database_helper.dart';
import '../model/appusage/app_usage_model.dart'; // AppUsageModel 임포트

class AppUsageDao {
  final dbHelper = DatabaseHelper();

  Future<void> insertAppUsageBatch(List<AppUsageModel> list) async {
    final db = await dbHelper.database;
    final batch = db.batch();
    for (final item in list) {
      batch.insert('app_usage', item.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  Future<void> deleteAppUsageForUserAndDate(String userId, String date) async {
    final db = await dbHelper.database;
    await db.delete(
      'app_usage',
      where: 'userId = ? AND date = ?',
      whereArgs: [userId, date],
    );
  }

  Future<void> replaceAppUsagesForDate(String userId, String date, List<AppUsageModel> list) async {
    await deleteAppUsageForUserAndDate(userId, date);
    await insertAppUsageBatch(list);
  }


  Future<List<AppUsageModel>> getAllAppUsages() async {
    final db = await dbHelper.database;
    final result = await db.query('app_usage');
    return result.map((e) => AppUsageModelExt.fromMap(e)).toList();
  }
}
