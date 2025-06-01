// abstract_database.dart
import 'package:recap_today/model/diary_model.dart';
import 'package:recap_today/model/checklist_item.dart';
import 'package:recap_today/model/app_usage_model.dart';
import 'package:recap_today/model/emotion_model.dart'; // EmotionRecord 모델 import 추가
import 'package:recap_today/model/location_model.dart'; // LocationRecord 모델 import 추가
import 'package:recap_today/model/schedule_item.dart'; // Added import for ScheduleItem
import 'package:recap_today/model/photo_model.dart'; // Added import
import 'package:recap_today/model/pedometer_data.dart';
import 'package:recap_today/model/weather_data.dart';
import 'package:sqflite/sqflite.dart'; // Added import for Database, DatabaseExecutor

/// 데이터베이스 접근을 위한 추상 인터페이스
/// 다양한 데이터베이스 구현체를 일관적으로 사용할 수 있도록 정의합니다.
abstract class AbstractDatabase {
  // 데이터베이스 인스턴스 getter 추가
  Future<Database> get database;

  // 일기 관련 메서드
  Future<DiaryModel> saveDiary(DiaryModel diary); // New method
  Future<List<DiaryModel>> getDiaries();
  Future<DiaryModel?> getDiaryForDate(String date);
  Future<Map<String, dynamic>> searchDiaries(
    String query, {
    int? limit,
    int? offset,
  });
  Future<int> deleteDiary(
    int diaryId,
  ); // New method, assuming diaryId is int based on typical DB PKs
  Future<List<DiaryModel>> getUnsyncedDiaries({
    DateTime? lastSyncTimestamp,
  }); // Added for SyncService
  Future<void> markDiariesAsSynced(
    List<String> clientTempIds,
    DateTime syncTimestamp, {
    Map<String, String>? serverIds,
  }); // Added for SyncService // MODIFIED SIGNATURE
  Future<bool> hasUnsyncedDiaryChanges({DateTime? lastSyncTimestamp}); // Added
  Future<void> applyDiarySyncChanges(List<DiaryModel> serverDiaries); // Added

  // Photo related methods
  Future<void> applyPhotoSyncChanges(List<Photo> serverPhotos); // Added
  Future<List<Photo>> getUnsyncedPhotos({DateTime? lastSyncTimestamp});
  Future<void> markPhotosAsSynced(
    List<String> clientTempIds, // MODIFIED: photoClientTempIds -> clientTempIds
    DateTime syncTimestamp, {
    Map<String, String>? serverIds,
  }); // MODIFIED SIGNATURE & RETURN TYPE (int -> void)
  Future<List<Photo>> getPhotosForDiary(
    int diaryId,
  ); // Added: New abstract method

  // 체크리스트 관련 메서드
  Future<void> saveChecklistItems(List<ChecklistItem> items);
  Future<List<ChecklistItem>> getChecklistItems();
  Future<int> insertChecklistItem(ChecklistItem item);
  Future<int> updateChecklistItem(ChecklistItem item);
  Future<int> deleteChecklistItem(String id);
  Future<void> deleteAllChecklistItems(); // Added: New abstract method
  Future<List<ChecklistItem>> getUnsyncedChecklistItems({
    DateTime? lastSyncTimestamp,
  }); // Added for SyncService
  Future<void> markChecklistItemsAsSynced(
    List<String> clientTempIds, // MODIFIED: ids -> clientTempIds
    DateTime syncTimestamp, {
    Map<String, String>? serverIds,
  }); // Added for SyncService // MODIFIED SIGNATURE (String syncStatus -> DateTime, serverIds)
  Future<bool> hasUnsyncedChecklistChanges({
    DateTime? lastSyncTimestamp,
  }); // Added
  Future<void> applyChecklistSyncChanges(
    List<ChecklistItem> serverChecklists,
  ); // Added

  // AppUsage methods
  Future<void> insertAppUsage(AppUsageModel appUsage);
  Future<List<AppUsageModel>> getAllAppUsages();
  Future<AppUsageModel?> getAppUsageById(String id);
  Future<void> updateAppUsage(AppUsageModel appUsage);
  Future<void> deleteAppUsage(String id);
  Future<void> deleteAllAppUsages();
  Future<void> deleteAppUsagesByDate(String date); // Added
  Future<void> insertAppUsages(List<AppUsageModel> appUsages); // Added
  Future<AppUsageSummary?> getAppUsageSummaryForDate(String date); // Added
  Future<List<AppUsageModel>> getUnsyncedAppUsages({
    DateTime? lastSyncTimestamp,
  }); // Added for sync
  Future<void> markAppUsagesAsSynced(
    List<String> clientTempIds,
    DateTime syncTimestamp, { // MODIFIED: DateTime? -> DateTime
    Map<String, String>?
    serverIds, // MODIFIED: List<String>? -> Map<String, String>?
  }); // Added for sync // MODIFIED SIGNATURE
  Future<void> applyAppUsageSyncChanges(
    List<AppUsageModel> serverAppUsages,
  ); // Added for sync
  Future<bool> hasUnsyncedAppUsageChanges({
    DateTime? lastSyncTimestamp,
  }); // Added for sync

  Future<int> getAppUsageCountForDate(
    String date,
  ); // New method for counting app usage

  // 일정 관련 메서드
  Future<int> insertScheduleItem(ScheduleItem item);
  Future<int> updateScheduleItem(ScheduleItem item);
  Future<List<ScheduleItem>> getScheduleItems();
  Future<List<ScheduleItem>> getScheduleItemsForDate(DateTime date);
  Future<List<ScheduleItem>> getRoutineScheduleItems();
  Future<ScheduleItem?> getScheduleItemById(String id);
  Future<int> deleteScheduleItem(String id);
  Future<int> deleteAllScheduleItems();
  Future<List<ScheduleItem>> getUnsyncedScheduleItems({
    DateTime? lastSyncTimestamp,
  }); // Modified for SyncService
  Future<void> markScheduleItemsAsSynced(
    List<String> clientTempIds, // MODIFIED: ids -> clientTempIds
    DateTime syncTimestamp, {
    Map<String, String>? serverIds,
  }); // Added for SyncService // MODIFIED SIGNATURE (String syncStatus -> DateTime, serverIds)
  Future<List<ScheduleItem>> getScheduleItemsForRange(
    DateTime start,
    DateTime end,
  );
  Future<List<DateTime>> getScheduleDatesForMonth(int year, int month);
  Future<bool> hasSchedule();
  Future<int> deleteScheduleItemsInRange(DateTime start, DateTime end);
  Future<void> saveScheduleItems(List<ScheduleItem> items);
  Future<bool> hasUnsyncedScheduleChanges({
    DateTime? lastSyncTimestamp,
  }); // Added
  Future<void> applyScheduleSyncChanges(
    List<ScheduleItem> serverSchedules,
  ); // Added

  // 감정 기록 관련 메서드 (기존 메서드 시그니처 업데이트 및 새 메서드 추가)
  Future<void> saveEmotion(EmotionRecord emotion);
  Future<EmotionRecord?> getEmotionForHour(String date, int hour);
  Future<List<EmotionRecord>> getEmotionsForDate(String date);
  Future<EmotionRecord?> getEmotionById(String id);
  Future<void> deleteEmotion(String id);
  Future<List<EmotionRecord>> getUnsyncedEmotions({
    DateTime? lastSyncTimestamp,
  });
  Future<void> markEmotionsAsSynced(
    List<String> clientTempIds, // MODIFIED: ids -> clientTempIds
    DateTime syncTimestamp, {
    Map<String, String>? serverIds, // ADDED serverIds
  });
  Future<bool> hasUnsyncedEmotionChanges({DateTime? lastSyncTimestamp});
  Future<void> applyEmotionSyncChanges(List<Map<String, dynamic>> changes);
  Future<List<EmotionRecord>> getDeletedAndUnsyncedEmotions({
    DateTime? lastSyncTimestamp,
  });

  // LocationRecord 관련 메서드 (LocationDao API 미러링)
  Future<void> saveLocationLog(LocationRecord log);
  Future<LocationRecord?> getLocationLogById(String id);
  Future<LocationRecord?> getLocationLogByClientTempId(String clientTempId);
  Future<List<LocationRecord>> getLocationLogsForDate(DateTime date);
  Future<List<LocationRecord>> getUnsyncedLocationLogs({
    DateTime? lastSyncTimestamp,
  });
  Future<void> markLocationLogsAsSynced(
    List<String> clientTempIds, // MODIFIED: ids -> clientTempIds
    DateTime syncTimestamp, {
    Map<String, String>? serverIds, // ADDED serverIds
  }); // MODIFIED SIGNATURE (String syncStatus -> DateTime, serverIds)
  Future<void> deleteLocationLog(String id);
  Future<void> hardDeleteLocationLog(String id);
  Future<bool> hasUnsyncedLocationChanges({DateTime? lastSyncTimestamp});
  Future<void> applyLocationSyncChanges(List<Map<String, dynamic>> changes);
  Future<List<LocationRecord>> getDeletedAndUnsyncedLocationLogs({
    DateTime? lastSyncTimestamp,
  });
  Future<List<LocationRecord>> getLocationLogsForUserAndDate(
    String userId,
    DateTime date,
  );
  Future<List<LocationRecord>> getAllLocationLogsForUser(String userId);
  Future<List<LocationRecord>> getLocationLogsForUserInRange(
    String userId,
    DateTime startDate,
    DateTime endDate,
  );
  Future<void> deleteLocationLogsInRange(
    String userId,
    DateTime startDate,
    DateTime endDate,
  );
  Future<void> deleteAllLocationLogsForUser(String userId);

  // Pedometer Data
  Future<void> insertPedometerData(PedometerData data);
  Future<PedometerData?> getPedometerDataById(String id);
  Future<List<PedometerData>> getPedometerDataByDate(String date);
  Future<List<PedometerData>> getAllPedometerData();
  Future<void> updatePedometerData(PedometerData data);
  Future<void> deletePedometerData(String id);
  Future<List<PedometerData>> getUnsyncedPedometerData({
    DateTime? lastSyncTimestamp,
  }); // Added for sync
  Future<void> markPedometerDataAsSynced(
    List<String> clientTempIds, // MODIFIED: ids -> clientTempIds
    DateTime syncTimestamp, {
    Map<String, String>? serverIds, // ADDED serverIds
  }); // Added for sync // MODIFIED SIGNATURE
  Future<void> applyPedometerDataSyncChanges(
    List<PedometerData> serverData,
  ); // Added for sync
  Future<bool> hasUnsyncedPedometerChanges({
    DateTime? lastSyncTimestamp,
  }); // Added for sync

  // Weather Data
  Future<void> insertWeatherData(WeatherData data);
  Future<WeatherData?> getWeatherDataById(String id);
  Future<List<WeatherData>> getWeatherDataByDate(String date);
  Future<List<WeatherData>> getAllWeatherData();
  Future<void> updateWeatherData(WeatherData data);
  Future<void> deleteWeatherData(String id);
  Future<List<WeatherData>> getUnsyncedWeatherData({
    DateTime? lastSyncTimestamp,
  }); // Added for sync
  Future<void> markWeatherDataAsSynced(
    List<String> clientTempIds, // MODIFIED: ids -> clientTempIds
    DateTime syncTimestamp, {
    Map<String, String>? serverIds, // ADDED serverIds
  }); // Added for sync // MODIFIED SIGNATURE
  Future<void> applyWeatherDataSyncChanges(
    List<WeatherData> serverData,
  ); // Added for sync
  Future<bool> hasUnsyncedWeatherChanges({
    DateTime? lastSyncTimestamp,
  }); // Added for sync

  // Sync Service specific import methods
  Future<void> importChecklists(
    List<Map<String, dynamic>> itemsData,
    DateTime syncTime,
  );
  Future<void> importDiaries(
    List<Map<String, dynamic>> diariesData,
    DateTime syncTime,
  );
  Future<void> importPhotos(
    List<Map<String, dynamic>> photosData,
    DateTime syncTime,
  );
  Future<void> importAppUsages(
    List<Map<String, dynamic>> appUsagesData,
    DateTime syncTime,
  );
  Future<void> importEmotions(
    List<Map<String, dynamic>> emotionsData,
    DateTime syncTime,
  );
  Future<void> importLocations(
    List<Map<String, dynamic>> locationsData,
    DateTime syncTime,
  );
  Future<void> importPedometers(
    List<Map<String, dynamic>> pedometersData,
    DateTime syncTime,
  );
  Future<void> importSchedules(
    List<Map<String, dynamic>> schedulesData,
    DateTime syncTime,
  );
  Future<void> importWeathers(
    List<Map<String, dynamic>> weathersData,
    DateTime syncTime,
  );

  // Last Sync Time methods
  Future<void> setLastSyncTime(DateTime syncTime);
  Future<DateTime?> getLastSyncTime();
}
