import 'package:recap_today/model/emotion_model.dart';

// Abstract class defining the interface for emotion data operations
abstract class AbstractEmotionRepository {
  Future<void> addEmotionRecord(EmotionRecord record);
  Future<void> updateEmotionRecord(EmotionRecord record);
  Future<EmotionRecord?> getEmotionRecordForHour(String date, int hour);
  Future<List<EmotionRecord>> getEmotionRecordsForDay(String date);
  Future<void> deleteEmotionRecord(String id);
}
