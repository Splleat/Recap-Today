// abstract_database.dart
import 'package:recap_today/model/diary_model.dart';
import 'package:recap_today/model/checklist_item.dart';
import 'package:recap_today/model/app_usage_model.dart';
import 'package:recap_today/model/emotion_model.dart'; // EmotionRecord 모델 import 추가
import 'package:recap_today/model/schedule_item.dart';
import 'package:sqflite/sqflite.dart'; // sqflite import 추가

/// 데이터베이스 접근을 위한 추상 인터페이스
/// 다양한 데이터베이스 구현체를 일관적으로 사용할 수 있도록 정의합니다.
abstract class AbstractDatabase {
  // 데이터베이스 인스턴스 getter 추가
  Future<Database> get database;

  // 일기 관련 메서드
  Future<int> insertDiary(DiaryModel diary);
  Future<int> updateDiary(DiaryModel diary);
  Future<List<DiaryModel>> getDiaries();
  Future<DiaryModel?> getDiaryForDate(String date);
  Future<Map<String, dynamic>> searchDiaries(
    String query, {
    int? limit,
    int? offset,
  }); // New signature with limit and offset

  // 체크리스트 관련 메서드
  Future<int> insertChecklistItem(ChecklistItem item);
  Future<int> updateChecklistItem(ChecklistItem item);
  Future<List<ChecklistItem>> getChecklistItems();
  Future<ChecklistItem?> getChecklistItemById(String id);
  Future<int> deleteChecklistItem(String id);
  Future<int> deleteAllChecklistItems();
  Future<void> saveChecklistItems(List<ChecklistItem> items);

  // 앱 사용 기록 관련 메서드
  Future<int> insertAppUsage(AppUsageModel appUsage);
  Future<int> insertAppUsageBatch(List<AppUsageModel> appUsages);
  Future<List<AppUsageModel>> getAppUsageForDate(String date);
  Future<AppUsageSummary?> getAppUsageSummaryForDate(String date);
  Future<int> deleteAppUsageForDate(String date);

  // 일정 관련 메서드
  Future<int> insertScheduleItem(ScheduleItem item);
  Future<int> updateScheduleItem(ScheduleItem item);
  Future<List<ScheduleItem>> getScheduleItems();
  Future<List<ScheduleItem>> getScheduleItemsForDate(DateTime date);
  Future<List<ScheduleItem>> getRoutineScheduleItems();
  Future<ScheduleItem?> getScheduleItemById(String id);
  Future<int> deleteScheduleItem(String id);
  Future<int> deleteAllScheduleItems();

  // 일정 관련 추가 메서드
  Future<List<ScheduleItem>> getScheduleItemsForRange(
    DateTime start,
    DateTime end,
  );
  Future<List<DateTime>> getScheduleDatesForMonth(int year, int month);
  Future<bool> hasSchedule();
  Future<int> deleteScheduleItemsInRange(DateTime start, DateTime end);
  Future<void> saveScheduleItems(List<ScheduleItem> items);

  // 감정 기록 관련 메서드
  Future<int> addEmotionRecord(EmotionRecord emotionRecord);
  Future<int> updateEmotionRecord(EmotionRecord emotionRecord);
  Future<EmotionRecord?> getEmotionRecordForHour(String date, int hour);
  Future<List<EmotionRecord>> getEmotionRecordsForDay(String date);
  Future<int> deleteEmotionRecord(String id);
}
