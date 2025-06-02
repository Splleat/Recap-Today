// emotion_dao.dart
import 'package:sqflite/sqflite.dart';
import '../database/database_helper.dart';
import '../model/emotion/emotion_model.dart'; // EmotionRecord 모델 임포트

class EmotionDao {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  Future<List<EmotionRecord>> getAllEmotions() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query('emotion');
    return maps.map((map) => EmotionRecordExt.fromMap(map)).toList();
  }

  Future<EmotionRecord?> getEmotionById(String id) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> result = await db.query(
      'emotion',
      where: 'id = ?',
      whereArgs: [id],
    );
    return result.isNotEmpty ? EmotionRecordExt.fromMap(result.first) : null;
  }

  Future<int> insertEmotion(EmotionRecord emotion) async {
    final db = await _dbHelper.database;
    return await db.insert('emotion', emotion.toMap());
  }

  Future<int> updateEmotion(EmotionRecord emotion) async {
    final db = await _dbHelper.database;
    return await db.update(
      'emotion',
      emotion.toMap(),
      where: 'id = ?',
      whereArgs: [emotion.id],
    );
  }

  Future<int> deleteEmotion(String id) async {
    final db = await _dbHelper.database;
    return await db.delete(
      'emotion',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// 특정 날짜의 감정 기록 조회
  Future<List<EmotionRecord>> getEmotionsForDate(String date) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'emotion',
      where: 'date = ?',
      whereArgs: [date],
    );
    return maps.map((map) => EmotionRecordExt.fromMap(map)).toList();
  }

  /// 특정 날짜와 시간의 감정 기록 조회 (hour 기반)
  Future<EmotionRecord?> getEmotionForHour(String date, int hour) async {
    final db = await _dbHelper.database;
    // SQLite에서 시간 비교는 문자열 비교로 처리하는 경우가 많습니다.
    // 모델의 date 필드가 'yyyy-MM-dd HH:mm:ss' 형식이라고 가정합니다.
    final List<Map<String, dynamic>> result = await db.query(
      'emotion',
      where: 'substr(date, 1, 10) = ? AND cast(strftime(\'%H\', substr(date, 12, 8)) as INTEGER) = ?',
      whereArgs: [date, hour],
    );
    return result.isNotEmpty ? EmotionRecordExt.fromMap(result.first) : null;
  }

  /// 특정 사용자와 날짜의 감정 기록 조회
  Future<List<EmotionRecord>> getEmotionsForUserAndDate(String userId, String date) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'emotion',
      where: 'userId = ? AND date = ?',
      whereArgs: [userId, date],
    );
    return maps.map((map) => EmotionRecordExt.fromMap(map)).toList();
  }
}