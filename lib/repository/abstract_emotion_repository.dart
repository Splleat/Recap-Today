import 'package:recap_today/model/emotion_model.dart';

// Abstract class defining the interface for emotion data operations
abstract class AbstractEmotionRepository {
  Future<void> addEmotionRecord(
    EmotionRecord record,
  ); // Will be mapped to saveEmotion
  Future<void> updateEmotionRecord(
    EmotionRecord record,
  ); // Will be mapped to saveEmotion
  Future<EmotionRecord?> getEmotionRecordForHour(
    String date,
    int hour,
  ); // Will be mapped to getEmotionForHour
  Future<List<EmotionRecord>> getEmotionRecordsForDay(
    String date,
  ); // Will be mapped to getEmotionsForDate
  Future<void> deleteEmotionRecord(
    String id,
  ); // Will be mapped to deleteEmotion

  // New methods to align with AbstractDatabase and EmotionDao capabilities
  Future<EmotionRecord?> getEmotionById(String id);
  Future<List<EmotionRecord>> getUnsyncedEmotions();
  Future<void> markEmotionsAsSynced(List<String> ids, DateTime syncTime);
}
