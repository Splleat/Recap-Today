import '../database/database_helper.dart';
import '../model/diary/diary_model.dart';
import '../model/photo/photo_model.dart';

class DiaryDao {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  Future<List<Diary>> getAllDiaries() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> result = await db.query('diary');
    return result.map((map) => DiaryExt.fromMap(map)).toList();
  }

  Future<Diary?> getDiaryByDate(String date) async {
    final db = await _dbHelper.database;
    final result = await db.query(
      'diary',
      where: 'date = ?',
      whereArgs: [date],
    );
    if (result.isEmpty) return null;
    return DiaryExt.fromMap(result.first);
  }

  Future<int> insertDiary(Diary diary) async {
    final db = await _dbHelper.database;
    return await db.insert('diary', diary.toMap());
  }

  Future<int> updateDiary(Diary diary) async {
    final db = await _dbHelper.database;
    return await db.update(
      'diary',
      diary.toMap(),
      where: 'id = ?',
      whereArgs: [diary.id],
    );
  }

  Future<int> deleteDiary(String id) async {
    final db = await _dbHelper.database;
    return await db.delete('diary', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> insertPhotos(String diaryId, List<String> paths) async {
    final db = await _dbHelper.database;
    final batch = db.batch();
    for (final path in paths) {
      batch.insert('photo', Photo(diaryId: diaryId, path: path).toMap());
    }
    await batch.commit(noResult: true);
  }

  Future<void> deletePhotosForDiary(String diaryId) async {
    final db = await _dbHelper.database;
    await db.delete('photo', where: 'diaryId = ?', whereArgs: [diaryId]);
  }

  Future<Map<String, dynamic>> searchDiaries(String query, {int? limit, int? offset}) async {
    final db = await _dbHelper.database;
    final result = await db.query(
      'diary',
      where: 'title LIKE ? OR content LIKE ?',
      whereArgs: ['%$query%', '%$query%'],
      limit: limit,
      offset: offset,
    );
    return {
      'results': result.map((e) => DiaryExt.fromMap(e)).toList(),
      'count': result.length,
    };
  }
}