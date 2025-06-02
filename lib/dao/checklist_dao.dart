import 'package:sqflite/sqflite.dart';
import '../database/database_helper.dart';
import '../model/checklist/checklist_item.dart';

class ChecklistDao {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  Future<List<ChecklistItem>> getAllChecklists() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query('checklist');
    return maps.map((map) => ChecklistItemExt.fromMap(map)).toList();
  }

  Future<ChecklistItem?> getChecklistById(String id) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> result = await db.query(
      'checklist',
      where: 'id = ?',
      whereArgs: [id],
    );
    return result.isNotEmpty ? ChecklistItemExt.fromMap(result.first) : null;
  }

  Future<int> insertChecklist(ChecklistItem item) async {
    final db = await _dbHelper.database;
    return await db.insert('checklist', item.toMap());
  }

  Future<int> updateChecklist(ChecklistItem item) async {
    final db = await _dbHelper.database;
    return await db.update(
      'checklist',
      item.toMap(),
      where: 'id = ?',
      whereArgs: [item.id],
    );
  }

  Future<int> deleteChecklist(String id) async {
    final db = await _dbHelper.database;
    return await db.delete(
      'checklist',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> insertAllChecklists(List<ChecklistItem> items) async {
    final db = await _dbHelper.database;
    final batch = db.batch();
    for (var item in items) {
      batch.insert('checklist', item.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }
}