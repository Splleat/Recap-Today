import 'package:recap_today/data/abstract_database.dart'; // Import AbstractDatabase
import 'package:recap_today/model/emotion_model.dart';
import 'package:recap_today/repository/abstract_emotion_repository.dart';

class EmotionRepository implements AbstractEmotionRepository {
  final AbstractDatabase _database; // Use AbstractDatabase

  EmotionRepository(this._database); // Constructor updated

  static const String tableName = 'emotion_records';

  @override
  Future<void> addEmotionRecord(EmotionRecord record) async {
    try {
      await _database.addEmotionRecord(record); // Delegate to AbstractDatabase
    } catch (e) {
      print('Error adding emotion record via repository: $e');
      rethrow;
    }
  }

  @override
  Future<void> updateEmotionRecord(EmotionRecord record) async {
    try {
      await _database.updateEmotionRecord(
        record,
      ); // Delegate to AbstractDatabase
    } catch (e) {
      print('Error updating emotion record via repository: $e');
      rethrow;
    }
  }

  @override
  Future<EmotionRecord?> getEmotionRecordForHour(String date, int hour) async {
    // Signature updated
    try {
      return await _database.getEmotionRecordForHour(
        date,
        hour,
      ); // Delegate to AbstractDatabase
    } catch (e) {
      print('Error getting emotion record for hour via repository: $e');
      return null;
    }
  }

  @override
  Future<List<EmotionRecord>> getEmotionRecordsForDay(String date) async {
    // Signature updated
    try {
      return await _database.getEmotionRecordsForDay(
        date,
      ); // Delegate to AbstractDatabase
    } catch (e) {
      print('Error getting emotion records for day via repository: $e');
      return [];
    }
  }

  @override
  Future<void> deleteEmotionRecord(String id) async {
    // Signature updated
    try {
      await _database.deleteEmotionRecord(id); // Delegate to AbstractDatabase
    } catch (e) {
      print('Error deleting emotion record via repository: $e');
      rethrow;
    }
  }
}
