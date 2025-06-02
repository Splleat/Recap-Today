// emotion_repository.dart
import 'package:recap_today/dao/emotion_dao.dart'; // Import EmotionDao
import 'package:recap_today/model/emotion/emotion_model.dart';
import 'package:recap_today/repository/abstract_emotion_repository.dart';

class EmotionRepository implements AbstractEmotionRepository {
  final EmotionDao _emotionDao; // Use EmotionDao

  EmotionRepository(this._emotionDao); // Constructor updated

  static const String tableName = 'emotion'; // 테이블 이름 업데이트

  @override
  Future<void> addEmotionRecord(EmotionRecord record) async {
    try {
      await _emotionDao.insertEmotion(record); // Delegate to EmotionDao
    } catch (e) {
      print('Error adding emotion record via repository: $e');
      rethrow;
    }
  }

  @override
  Future<void> updateEmotionRecord(EmotionRecord record) async {
    try {
      await _emotionDao.updateEmotion(record); // Delegate to EmotionDao
    } catch (e) {
      print('Error updating emotion record via repository: $e');
      rethrow;
    }
  }

  @override
  Future<EmotionRecord?> getEmotionRecordForHour(String date, int hour) async {
    try {
      return await _emotionDao.getEmotionForHour(date, hour); // Delegate to EmotionDao
    } catch (e) {
      print('Error getting emotion record for hour via repository: $e');
      return null;
    }
  }

  @override
  Future<List<EmotionRecord>> getEmotionRecordsForDay(String date) async {
    try {
      return await _emotionDao.getEmotionsForDate(date); // Delegate to EmotionDao
    } catch (e) {
      print('Error getting emotion records for day via repository: $e');
      return [];
    }
  }

  @override
  Future<void> deleteEmotionRecord(String id) async {
    try {
      await _emotionDao.deleteEmotion(id); // Delegate to EmotionDao
    } catch (e) {
      print('Error deleting emotion record via repository: $e');
      rethrow;
    }
  }
}