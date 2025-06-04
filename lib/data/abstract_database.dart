// abstract_database.dart
import 'package:recap_today/model/freezed/diary_model.dart';
import 'package:recap_today/model/freezed/checklist_item.dart';
import 'package:recap_today/model/freezed/app_usage_model.dart';
import 'package:recap_today/model/freezed/emotion_model.dart';
import 'package:recap_today/model/freezed/schedule_item.dart';
import 'package:recap_today/model/freezed/location_model.dart';
import 'package:recap_today/model/freezed/step_model.dart';
import 'package:sqflite/sqflite.dart';

/// 데이터베이스 접근을 위한 추상 인터페이스
/// 다양한 데이터베이스 구현체를 일관적으로 사용할 수 있도록 정의합니다.
abstract class AbstractDatabase {
  // 데이터베이스 인스턴스 및 기본 작업
  Future<Database> get database;
  Future close();
  
  // 일기 관련 메소드
  Future<int> insertDiary(DiaryModel diary);
  Future<DiaryModel?> getDiaryByDate(String date, String userId);
  Future<List<DiaryModel>> getAllDiaries(String userId);
  Future<int> updateDiary(DiaryModel diary);
  Future<int> deleteDiary(int id, String userId);
  Future<Map<String, dynamic>> searchDiaries(
    String query,
    String userId, {
    int? limit,
    int? offset,
  });
  
  // 체크리스트 관련 메소드
  Future<int> insertChecklistItem(ChecklistItem item);
  Future<List<ChecklistItem>> getAllChecklistItems(String userId);
  Future<int> updateChecklistItem(ChecklistItem item);
  Future<int> deleteChecklistItem(String id, String userId);
  Future<List<ChecklistItem>> getChecklistItemsByCompletedDate(String date, String userId);
  Future<List<ChecklistItem>> getIncompleteChecklistItems(String userId);
  Future<List<ChecklistItem>> getCompletedChecklistItems(String userId);
  Future<void> saveChecklistItems(List<ChecklistItem> items);
  
  // 앱 사용량 관련 메소드
  Future<int> insertAppUsage(AppUsageModel appUsage);
  Future<List<AppUsageModel>> getAppUsageByDate(String date, String userId);
  Future<int> deleteAppUsageByDate(String date, String userId);
  Future<int> insertAppUsageBatch(List<AppUsageModel> appUsages, String userId);

  // 일정 관련 메소드
  Future<int> insertScheduleItem(ScheduleItem item);
  Future<List<ScheduleItem>> getScheduleItemsByDate(String date, String userId);
  Future<List<ScheduleItem>> getAllScheduleItems(String userId);
  Future<int> updateScheduleItem(ScheduleItem item);
  Future<int> deleteScheduleItem(String id, String userId);
  
  // 감정 기록 관련 메소드
  Future<int> insertEmotionRecord(EmotionRecord emotion);
  Future<List<EmotionRecord>> getEmotionsByDate(String date, String userId);
  Future<EmotionRecord?> getEmotionByDateAndHour(String date, int hour, String userId);
  Future<int> updateEmotionRecord(EmotionRecord emotion);
  Future<int> deleteEmotionRecord(String id, String userId);
  
  // 위치 로그 관련 메소드
  Future<int> insertLocationLog(Map<String, dynamic> locationLog);
  Future<List<Map<String, dynamic>>> getLocationLogsForUserAndDate(String userId, String date);
  Future<List<Map<String, dynamic>>> getLocationLogsForUser(String userId);
  Future<List<Map<String, dynamic>>> getAllLocationLogsForUser(String userId);
  Future<int> deleteAllLocationLogsForUser(String userId);
  Future<List<Map<String, dynamic>>> getLocationLogsForUserInRange(String userId, DateTime start, DateTime end);
  Future<int> deleteLocationLogsInRange(String userId, DateTime start, DateTime end);
  
  // 걸음 수 관련 메소드
  Future<int> insertStepCount(StepModel step);
  Future<StepModel?> getStepsByDate(String date, String userId);
  
  // 사진 관련 메소드
  Future<int> insertPhoto(int diaryId, String path, String userId);
  Future<List<String>> getPhotosByDiaryId(int diaryId);
  Future<int> deletePhoto(int id, String userId);
  Future<int> deleteAllPhotosForDiary(int diaryId, String userId);
  
  // 동기화 관련 메소드
  Future<int> updateSyncStatus(String table, dynamic id, bool isSynced);
  Future<List<Map<String, dynamic>>> getUnsyncedItems(String table);
}
