import 'package:sqflite/sqflite.dart';
import '../model/checklist_item_model.dart' as dao_checklist_item_model;
import '../model/checklist_item.dart';
import '../model/checklist_model.dart';
import './abstract_database.dart';
import './database_helper.dart';

// Model Imports
import '../model/diary_model.dart';
import '../model/photo_model.dart';
import '../model/app_usage_model.dart';
import '../model/emotion_model.dart';
import '../model/location_model.dart';
import '../model/schedule_item.dart';
import '../model/pedometer_data.dart';
import '../model/weather_data.dart';
import '../model/sync_status.dart'; // Added import for SyncStatus

// DAO Imports
import 'dao/diary_dao.dart';
import 'dao/photo_dao.dart';
import 'dao/checklist_item_dao.dart';
import 'dao/schedule_dao.dart';
import 'dao/emotion_dao.dart';
import 'dao/location_dao.dart';
import 'dao/app_usage_dao.dart';
import 'dao/pedometer_dao.dart';
import 'dao/weather_dao.dart';

class SqfliteDatabase implements AbstractDatabase {
  Database? _db;
  bool _isInitialized = false;

  late final DiaryDao _diaryDao;
  late final PhotoDao _photoDao;
  late final ChecklistItemDao _checklistItemDao;
  late ScheduleDao _scheduleDao;
  late final EmotionDao _emotionDao;
  late final LocationDao _locationDao;
  late final AppUsageDao _appUsageDao;
  late final PedometerDao _pedometerDao;
  late final WeatherDao _weatherDao;

  SqfliteDatabase();

  // Initialization
  Future<void> init() async {
    if (_isInitialized) return;
    _db = await DatabaseHelper.instance.database;
    await _initDaos();
    _isInitialized = true;
    print("SqfliteDatabase initialized.");
  }

  // Initialize DAOs
  Future<void> _initDaos() async {
    if (_db == null) {
      throw Exception("Database not initialized before initializing DAOs.");
    }
    _diaryDao = DiaryDao(_db!);
    _photoDao = PhotoDao(_db!);
    _checklistItemDao = ChecklistItemDao();
    _scheduleDao = ScheduleDao(_db!);
    _emotionDao = EmotionDao(_db!);
    _locationDao = LocationDao(_db!);
    _appUsageDao = AppUsageDao(_db!);
    _pedometerDao = PedometerDao(_db!);
    _weatherDao = WeatherDao(_db!);
  }

  Future<void> _ensureInitialized() async {
    if (!_isInitialized) {
      await init();
    }
  }

  @override
  Future<Database> get database async {
    await _ensureInitialized();
    if (_db == null) {
      throw StateError(
        "Database not initialized. _ensureInitialized might have failed.",
      );
    }
    return _db!;
  }

  Future<void> close() async {
    if (_db != null && _db!.isOpen) {
      await _db!.close();
    }
    _isInitialized = false;
    _db = null;
  }

  // Last Sync Time methods
  @override
  Future<DateTime?> getLastSyncTime() async {
    await _ensureInitialized();
    // Placeholder - actual implementation needed, e.g., from a preferences table
    // For now, assuming it might be stored in a simple key-value way if not complex
    final prefs = await _db!.query(
      'sync_metadata',
      where: 'key = ?',
      whereArgs: ['lastSyncTime'],
    );
    if (prefs.isNotEmpty && prefs.first['value'] != null) {
      return DateTime.tryParse(prefs.first['value'] as String);
    }
    return null;
  }

  @override
  Future<void> setLastSyncTime(DateTime time) async {
    await _ensureInitialized();
    // Placeholder - actual implementation needed
    await _db!.insert('sync_metadata', {
      'key': 'lastSyncTime',
      'value': time.toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  // Diary Methods
  @override
  Future<DiaryModel> saveDiary(DiaryModel diary) async {
    await _ensureInitialized();
    return _diaryDao.saveDiary(diary);
  }

  @override
  Future<List<DiaryModel>> getDiaries() async {
    // Matched AbstractDatabase
    await _ensureInitialized();
    return _diaryDao
        .getDiaries(); // Assuming default includeDeleted = false in DAO or not applicable
  }

  @override
  Future<DiaryModel?> getDiaryForDate(String date) async {
    // Matched AbstractDatabase
    await _ensureInitialized();
    return _diaryDao.getDiaryForDate(
      date,
    ); // Assuming default includeDeleted = false in DAO
  }

  @override
  Future<int> deleteDiary(int diaryId) async {
    // Matched AbstractDatabase
    await _ensureInitialized();
    return _diaryDao.deleteDiary(diaryId);
  }

  @override
  Future<List<DiaryModel>> getUnsyncedDiaries({
    DateTime? lastSyncTimestamp,
  }) async {
    await _ensureInitialized();
    return _diaryDao.getUnsyncedDiaries(lastSyncTimestamp: lastSyncTimestamp);
  }

  @override
  Future<void> markDiariesAsSynced(
    List<String> clientTempIds,
    DateTime syncTimestamp, {
    Map<String, String>? serverIds,
  }) async {
    await _ensureInitialized();
    return _diaryDao.markDiariesAsSynced(
      clientTempIds,
      syncTimestamp,
      serverIds: serverIds,
    );
  }

  @override
  Future<void> applyDiarySyncChanges(List<DiaryModel> serverDiaries) async {
    // Matched AbstractDatabase
    await _ensureInitialized();
    return _diaryDao.applyDiarySyncChanges(
      serverDiaries,
    ); // Assumes DAO has this method
  }

  @override
  Future<bool> hasUnsyncedDiaryChanges({DateTime? lastSyncTimestamp}) async {
    await _ensureInitialized();
    final unsynced = await _diaryDao.getUnsyncedDiaries(
      lastSyncTimestamp: lastSyncTimestamp,
    );
    return unsynced.isNotEmpty;
  }

  @override
  Future<Map<String, dynamic>> searchDiaries(
    String query, {
    int? limit,
    int? offset,
  }) async {
    await _ensureInitialized();
    // Assuming _diaryDao has a searchDiaries method
    // return _diaryDao.searchDiaries(query, limit: limit, offset: offset);
    throw UnimplementedError(
      'searchDiaries not implemented in SqfliteDatabase yet',
    );
  }

  // Photo related methods
  @override
  Future<void> applyPhotoSyncChanges(List<Photo> serverPhotos) async {
    await _ensureInitialized();
    return _photoDao.applyPhotoSyncChanges(serverPhotos);
  }

  @override
  Future<List<Photo>> getUnsyncedPhotos({DateTime? lastSyncTimestamp}) async {
    await _ensureInitialized();
    return _photoDao.getUnsyncedPhotos(lastSyncTimestamp: lastSyncTimestamp);
  }

  @override
  Future<void> markPhotosAsSynced(
    List<String> clientTempIds,
    DateTime syncTimestamp, {
    Map<String, String>? serverIds,
  }) async {
    await _ensureInitialized();
    return _photoDao.markPhotosAsSynced(
      clientTempIds,
      syncTimestamp,
      serverIds: serverIds,
    );
  }

  @override
  Future<List<Photo>> getPhotosForDiary(int diaryId) async {
    await _ensureInitialized();
    return _photoDao.getPhotosForDiary(diaryId);
  }

  // This method is not part of AbstractDatabase, so no @override
  // However, if PhotoDao exposes it and it's useful, it can remain.
  // For now, let's assume it's not strictly needed by AbstractDatabase users.
  // Future<bool> hasUnsyncedPhotoChanges({DateTime? lastSyncTimestamp}) async {
  //   await _ensureInitialized();
  //   return _photoDao.hasUnsyncedPhotoChanges(lastSyncTimestamp: lastSyncTimestamp);
  // }

  // Helper methods for ChecklistItem conversion
  dao_checklist_item_model.ChecklistItem _toDaoChecklistItem(
    ChecklistItem item,
  ) {
    final map = item.toMap();
    return dao_checklist_item_model.ChecklistItem.fromMap({
      ...map,
      'id': item.serverId,
      'clientGeneratedId': item.clientTempId ?? item.id,
      'checklistId': item.checklistId,
    });
  }

  ChecklistItem _toAbstractChecklistItem(
    dao_checklist_item_model.ChecklistItem daoItem,
  ) {
    final map = daoItem.toMap();
    return ChecklistItem.fromMap({
      ...map,
      'id': daoItem.clientGeneratedId,
      'clientTempId': daoItem.clientGeneratedId,
      'serverId': daoItem.id,
      'checklistId': daoItem.checklistId,
    });
  }

  // ChecklistItem Methods
  @override
  Future<void> saveChecklistItems(List<ChecklistItem> items) async {
    await _ensureInitialized();
    try {
      final daoItems = items.map(_toDaoChecklistItem).toList();
      final db = await this.database;
      await db.transaction((txn) async {
        await _checklistItemDao.saveAllItems(daoItems, txn: txn);
      });
    } catch (e) {
      print('Error in saveChecklistItems: $e');
      rethrow;
    }
  }

  @override
  Future<List<ChecklistItem>> getChecklistItems() async {
    await _ensureInitialized();
    try {
      final daoItems = await _checklistItemDao.getAllItems();
      return daoItems.map(_toAbstractChecklistItem).toList();
    } catch (e) {
      print('Error in getChecklistItems: $e');
      rethrow;
    }
  }

  @override
  Future<int> insertChecklistItem(ChecklistItem item) async {
    await _ensureInitialized();
    try {
      final daoItem = _toDaoChecklistItem(item);
      return await _checklistItemDao.insert(daoItem);
    } catch (e) {
      print('Error in insertChecklistItem: $e');
      rethrow;
    }
  }

  @override
  Future<int> updateChecklistItem(ChecklistItem item) async {
    await _ensureInitialized();
    try {
      final daoItem = _toDaoChecklistItem(item);
      return await _checklistItemDao.update(daoItem);
    } catch (e) {
      print('Error in updateChecklistItem: $e');
      rethrow;
    }
  }

  @override
  Future<int> deleteChecklistItem(String clientTempIdOrServerId) async {
    await _ensureInitialized();
    try {
      // The DAO's delete method expects the primary key (integer id) or clientGeneratedId.
      // AbstractDatabase uses 'id' which is clientTempId for ChecklistItem.
      // So we pass clientTempIdOrServerId, assuming DAO handles it (prefers clientGeneratedId).
      return await _checklistItemDao.delete(clientTempIdOrServerId);
    } catch (e) {
      print('Error in deleteChecklistItem: $e');
      rethrow;
    }
  }

  @override
  Future<void> deleteAllChecklistItems() async {
    await _ensureInitialized();
    try {
      final db = await this.database;
      await db.transaction((txn) async {
        await _checklistItemDao.deleteAllItems(txn: txn);
      });
    } catch (e) {
      print('Error in deleteAllChecklistItems: $e');
      rethrow;
    }
  }

  @override
  Future<List<ChecklistItem>> getUnsyncedChecklistItems({
    DateTime? lastSyncTimestamp,
  }) async {
    await _ensureInitialized();
    try {
      final daoItems = await _checklistItemDao.getUnsyncedItems(
        lastSyncTimestamp: lastSyncTimestamp,
      );
      return daoItems.map(_toAbstractChecklistItem).toList();
    } catch (e) {
      print('Error in getUnsyncedChecklistItems: $e');
      rethrow;
    }
  }

  @override
  Future<void> markChecklistItemsAsSynced(
    List<String> clientTempIds,
    DateTime syncTimestamp, {
    Map<String, String>? serverIds,
  }) async {
    await _ensureInitialized();
    try {
      final db = await this.database;
      await db.transaction((txn) async {
        await _checklistItemDao.markAsSynced(
          clientTempIds,
          syncTimestamp: syncTimestamp,
          serverIds: serverIds,
          txn: txn,
        );
      });
    } catch (e) {
      print('Error in markChecklistItemsAsSynced: $e');
      rethrow;
    }
  }

  @override
  Future<bool> hasUnsyncedChecklistChanges({
    DateTime? lastSyncTimestamp,
  }) async {
    await _ensureInitialized();
    try {
      final unsynced = await getUnsyncedChecklistItems(
        lastSyncTimestamp: lastSyncTimestamp,
      );
      return unsynced.isNotEmpty;
    } catch (e) {
      print('Error in hasUnsyncedChecklistChanges: $e');
      rethrow;
    }
  }

  @override
  Future<void> applyChecklistSyncChanges(
    List<ChecklistItem> serverChecklistItems,
  ) async {
    await _ensureInitialized();
    try {
      final daoServerChecklistItems =
          serverChecklistItems.map(_toDaoChecklistItem).toList();
      final db = await this.database;
      await db.transaction((txn) async {
        await _checklistItemDao.applySyncChanges(
          daoServerChecklistItems,
          [],
          txn: txn,
        );
      });
    } catch (e) {
      print('Error in applyChecklistSyncChanges: $e');
      rethrow;
    }
  }

  // Methods for ChecklistModel (Parent Checklist) - These throw UnimplementedError as requested
  // These are NOT part of AbstractDatabase as defined for this task, so no @override.
  // If AbstractDatabase were to include them, they would need @override.
  Future<ChecklistModel> saveChecklist(ChecklistModel checklist) async {
    await _ensureInitialized();
    throw UnimplementedError(
      'saveChecklist (ChecklistModel) not implemented in SqfliteDatabase',
    );
  }

  Future<List<ChecklistModel>> getChecklists({
    bool includeDeleted = false,
  }) async {
    await _ensureInitialized();
    throw UnimplementedError(
      'getChecklists (ChecklistModel) not implemented in SqfliteDatabase',
    );
  }

  Future<ChecklistModel?> getChecklist(
    String id, {
    bool includeDeleted = false,
  }) async {
    await _ensureInitialized();
    throw UnimplementedError(
      'getChecklist (ChecklistModel) not implemented in SqfliteDatabase',
    );
  }

  Future<int> deleteChecklist(String id) async {
    await _ensureInitialized();
    throw UnimplementedError(
      'deleteChecklist (ChecklistModel) not implemented in SqfliteDatabase',
    );
  }

  Future<List<ChecklistModel>> getUnsyncedChecklists({
    DateTime? lastSyncTimestamp,
  }) async {
    await _ensureInitialized();
    throw UnimplementedError(
      'getUnsyncedChecklists (ChecklistModel) not implemented in SqfliteDatabase',
    );
  }

  Future<void> markChecklistsAsSynced(
    List<String> clientTempIds,
    DateTime syncTimestamp, {
    Map<String, String>? serverIds,
  }) async {
    await _ensureInitialized();
    throw UnimplementedError(
      'markChecklistsAsSynced (ChecklistModel) not implemented in SqfliteDatabase',
    );
  }

  Future<void> applyChecklistModelSyncChanges(
    List<ChecklistModel> serverChecklistModels,
    List<String> serverDeletedIds,
  ) async {
    await _ensureInitialized();
    throw UnimplementedError(
      'applyChecklistModelSyncChanges (ChecklistModel) not implemented in SqfliteDatabase',
    );
  }

  Future<bool> hasUnsyncedChecklistModelChanges({
    DateTime? lastSyncTimestamp,
  }) async {
    await _ensureInitialized();
    throw UnimplementedError(
      'hasUnsyncedChecklistModelChanges (ChecklistModel) not implemented in SqfliteDatabase',
    );
  }

  // Import methods from AbstractDatabase
  @override
  Future<void> importDiaries(
    List<Map<String, dynamic>> diariesData,
    DateTime syncTime,
  ) async {
    await _ensureInitialized();
    if (_db == null) throw Exception("Database not initialized.");
    return _db!.transaction((txn) async {
      await _diaryDao.importDiaries(diariesData, syncTime, txn: txn);
    });
  }

  @override
  Future<void> importPhotos(
    List<Map<String, dynamic>> photosData,
    DateTime syncTime,
  ) async {
    await _ensureInitialized();
    if (_db == null) throw Exception("Database not initialized.");
    return _db!.transaction((txn) async {
      await _photoDao.importPhotos(photosData, syncTime, txn: txn);
    });
  }

  @override
  Future<void> importChecklists(
    List<Map<String, dynamic>> itemsData,
    DateTime syncTime,
  ) async {
    await _ensureInitialized();
    try {
      final db = await this.database;
      await db.transaction((txn) async {
        await _checklistItemDao.importItems(itemsData, syncTime, txn: txn);
      });
    } catch (e) {
      print('Error in importChecklists (for ChecklistItem): $e');
      rethrow;
    }
  }

  // This was for ChecklistModel, which is not part of the current task's AbstractDatabase methods.
  // If it were, it would need @override. For now, it's an unimplemented local method.
  Future<void> importParentChecklists(
    List<Map<String, dynamic>> checklistModelData,
    DateTime syncTime,
  ) async {
    await _ensureInitialized();
    throw UnimplementedError(
      'importParentChecklists (for ChecklistModel) not implemented in SqfliteDatabase',
    );
  }

  // ScheduleItem methods
  @override
  Future<int> insertScheduleItem(ScheduleItem item) async {
    await _ensureInitialized();
    try {
      return await _scheduleDao.insertScheduleItem(item);
    } catch (e) {
      print('SqfliteDatabase: Error inserting schedule item: $e');
      return 0; // 0 indicates failure or no rows affected
    }
  }

  @override
  Future<int> updateScheduleItem(ScheduleItem item) async {
    await _ensureInitialized();
    try {
      return await _scheduleDao.updateScheduleItem(item);
    } catch (e) {
      print('SqfliteDatabase: Error updating schedule item: $e');
      return 0; // 0 indicates failure or no rows affected
    }
  }

  @override
  Future<List<ScheduleItem>> getScheduleItems() async {
    await _ensureInitialized();
    try {
      return await _scheduleDao.getScheduleItems();
    } catch (e) {
      print('SqfliteDatabase: Error getting all schedule items: $e');
      return [];
    }
  }

  @override
  Future<List<ScheduleItem>> getScheduleItemsForDate(DateTime date) async {
    await _ensureInitialized();
    try {
      return await _scheduleDao.getSchedulesByDate(
        date,
      ); // Corrected: Uses DateTime directly
    } catch (e) {
      print('SqfliteDatabase: Error getting schedule items for date $date: $e');
      return [];
    }
  }

  @override
  Future<List<ScheduleItem>> getRoutineScheduleItems() async {
    await _ensureInitialized();
    try {
      return await _scheduleDao.getRoutineScheduleItems(); // Corrected
    } catch (e) {
      print('SqfliteDatabase: Error getting routine schedule items: $e');
      return [];
    }
  }

  @override
  Future<ScheduleItem?> getScheduleItemById(String id) async {
    await _ensureInitialized();
    try {
      return await _scheduleDao.getScheduleItemById(id);
    } catch (e) {
      print('SqfliteDatabase: Error getting schedule item by id $id: $e');
      return null;
    }
  }

  @override
  Future<int> deleteScheduleItem(String id) async {
    await _ensureInitialized();
    try {
      return await _scheduleDao.deleteScheduleItem(id);
    } catch (e) {
      print('SqfliteDatabase: Error deleting schedule item by id $id: $e');
      return 0; // 0 indicates failure or no rows affected
    }
  }

  @override
  Future<int> deleteAllScheduleItems() async {
    await _ensureInitialized();
    try {
      return await _scheduleDao.deleteAllScheduleItems(); // Corrected
    } catch (e) {
      print('SqfliteDatabase: Error deleting all schedule items: $e');
      return 0; // 0 indicates failure or no rows affected
    }
  }

  @override
  Future<List<ScheduleItem>> getUnsyncedScheduleItems({
    DateTime? lastSyncTimestamp,
  }) async {
    await _ensureInitialized();
    try {
      return await _scheduleDao.getUnsyncedScheduleItems(
        lastSyncTimestamp: lastSyncTimestamp,
      ); // Corrected
    } catch (e) {
      print('SqfliteDatabase: Error getting unsynced schedule items: $e');
      return [];
    }
  }

  @override
  Future<void> markScheduleItemsAsSynced(
    List<String> clientTempIds,
    DateTime syncTimestamp, {
    Map<String, String>? serverIds,
  }) async {
    await _ensureInitialized();
    try {
      await _scheduleDao.markScheduleItemsAsSynced(
        // Corrected
        clientTempIds,
        syncTimestamp,
        serverIds: serverIds,
      );
    } catch (e) {
      print('SqfliteDatabase: Error marking schedule items as synced: $e');
    }
  }

  @override
  Future<List<ScheduleItem>> getScheduleItemsForRange(
    DateTime start,
    DateTime end,
  ) async {
    await _ensureInitialized();
    try {
      return await _scheduleDao.getSchedulesByDateRange(start, end);
    } catch (e) {
      print(
        'SqfliteDatabase: Error getting schedule items for range $start - $end: $e',
      );
      return [];
    }
  }

  @override
  Future<List<DateTime>> getScheduleDatesForMonth(int year, int month) async {
    await _ensureInitialized();
    try {
      return await _scheduleDao.getScheduleDatesForMonth(
        year,
        month,
      ); // Corrected
    } catch (e) {
      print(
        'SqfliteDatabase: Error getting schedule dates for month $year-$month: $e',
      );
      return [];
    }
  }

  @override
  Future<bool> hasSchedule() async {
    await _ensureInitialized();
    try {
      return await _scheduleDao.hasSchedule(); // Corrected
    } catch (e) {
      print('SqfliteDatabase: Error checking if schedule exists: $e');
      return false;
    }
  }

  @override
  Future<int> deleteScheduleItemsInRange(DateTime start, DateTime end) async {
    await _ensureInitialized();
    try {
      return await _scheduleDao.deleteScheduleItemsInRange(
        start,
        end,
      ); // Corrected
    } catch (e) {
      print(
        'SqfliteDatabase: Error deleting schedule items in range $start - $end: $e',
      );
      return 0; // 0 indicates failure or no rows affected
    }
  }

  @override
  Future<void> saveScheduleItems(List<ScheduleItem> items) async {
    await _ensureInitialized();
    try {
      // ScheduleDao.saveScheduleItems handles its own transaction if one isn't passed.
      await _scheduleDao.saveScheduleItems(items);
    } catch (e) {
      print('SqfliteDatabase: Error saving schedule items: $e');
      rethrow;
    }
  }

  @override
  Future<bool> hasUnsyncedScheduleChanges({DateTime? lastSyncTimestamp}) async {
    await _ensureInitialized();
    try {
      return await _scheduleDao.hasUnsyncedChanges(
        lastSyncTimestamp: lastSyncTimestamp,
      );
    } catch (e) {
      print(
        'SqfliteDatabase: Error checking for unsynced schedule changes: $e',
      );
      return false;
    }
  }

  @override
  Future<void> applyScheduleSyncChanges(
    List<ScheduleItem> serverSchedules,
  ) async {
    await _ensureInitialized();
    try {
      await _scheduleDao.applyScheduleItemSyncChanges(
        serverSchedules,
      ); // Corrected
    } catch (e) {
      print('SqfliteDatabase: Error applying schedule sync changes: $e');
    }
  }

  @override
  Future<void> importSchedules(
    List<Map<String, dynamic>> schedulesData,
    DateTime syncTime,
  ) async {
    await _ensureInitialized();
    try {
      await _scheduleDao.importSchedules(schedulesData, syncTime);
    } catch (e) {
      print('SqfliteDatabase: Error importing schedules: $e');
      rethrow;
    }
  }

  // --- Stubs for other AbstractDatabase methods ---
  // AppUsage methods
  @override
  Future<void> insertAppUsage(AppUsageModel appUsage) async {
    await _ensureInitialized();
    try {
      // AppUsageDao.insertAppUsage returns Future<String>, AbstractDatabase expects Future<void>
      await _appUsageDao.insertAppUsage(appUsage);
    } catch (e) {
      print('SqfliteDatabase: Error inserting app usage: $e');
      rethrow;
    }
  }

  @override
  Future<List<AppUsageModel>> getAllAppUsages() async {
    await _ensureInitialized();
    try {
      return await _appUsageDao.getAllAppUsages();
    } catch (e) {
      print('SqfliteDatabase: Error getting all app usages: $e');
      return [];
    }
  }

  @override
  Future<AppUsageModel?> getAppUsageById(String id) async {
    await _ensureInitialized();
    try {
      return await _appUsageDao.getAppUsageById(id);
    } catch (e) {
      print('SqfliteDatabase: Error getting app usage by id $id: $e');
      return null;
    }
  }

  @override
  Future<void> updateAppUsage(AppUsageModel appUsage) async {
    await _ensureInitialized();
    try {
      return await _appUsageDao.updateAppUsage(appUsage);
    } catch (e) {
      print('SqfliteDatabase: Error updating app usage: $e');
      rethrow;
    }
  }

  @override
  Future<void> deleteAppUsage(String id) async {
    await _ensureInitialized();
    try {
      return await _appUsageDao.deleteAppUsage(id);
    } catch (e) {
      print('SqfliteDatabase: Error deleting app usage by id $id: $e');
      rethrow;
    }
  }

  @override
  Future<void> deleteAllAppUsages() async {
    await _ensureInitialized();
    try {
      return await _appUsageDao.deleteAllAppUsages();
    } catch (e) {
      print('SqfliteDatabase: Error deleting all app usages: $e');
      rethrow;
    }
  }

  @override
  Future<void> deleteAppUsagesByDate(String date) async {
    await _ensureInitialized();
    try {
      return await _appUsageDao.deleteAppUsagesByDate(date);
    } catch (e) {
      print('SqfliteDatabase: Error deleting app usages for date $date: $e');
      rethrow;
    }
  }

  @override
  Future<void> insertAppUsages(List<AppUsageModel> appUsages) async {
    await _ensureInitialized();
    try {
      return await _appUsageDao.insertAppUsages(appUsages);
    } catch (e) {
      print('SqfliteDatabase: Error inserting app usages: $e');
      rethrow;
    }
  }

  @override
  Future<AppUsageSummary?> getAppUsageSummaryForDate(String date) async {
    await _ensureInitialized();
    try {
      return await _appUsageDao.getAppUsageSummaryForDate(date);
    } catch (e) {
      print(
        'SqfliteDatabase: Error getting app usage summary for date $date: $e',
      );
      return null;
    }
  }

  @override
  Future<List<AppUsageModel>> getUnsyncedAppUsages({
    DateTime? lastSyncTimestamp,
  }) async {
    await _ensureInitialized();
    try {
      return await _appUsageDao.getUnsyncedAppUsages(
        lastSyncTimestamp: lastSyncTimestamp,
      );
    } catch (e) {
      print('SqfliteDatabase: Error getting unsynced app usages: $e');
      return [];
    }
  }

  @override
  Future<void> markAppUsagesAsSynced(
    List<String> clientTempIds,
    DateTime syncTimestamp, {
    Map<String, String>? serverIds,
  }) async {
    await _ensureInitialized();
    try {
      // AppUsageDao has markAppUsagesAsSynced which matches this signature closely enough
      // if we pass the transaction explicitly.
      final db = await this.database;
      await db.transaction((txn) async {
        await _appUsageDao.markAppUsagesAsSynced(
          clientTempIds,
          syncTimestamp,
          serverIds: serverIds,
          txn: txn,
        );
      });
    } catch (e) {
      print('SqfliteDatabase: Error marking app usages as synced: $e');
      rethrow;
    }
  }

  @override
  Future<void> applyAppUsageSyncChanges(
    List<AppUsageModel> serverAppUsages,
  ) async {
    await _ensureInitialized();
    try {
      final db = await this.database;
      await db.transaction((txn) async {
        await _appUsageDao.applyAppUsageSyncChanges(serverAppUsages, txn: txn);
      });
    } catch (e) {
      print('SqfliteDatabase: Error applying app usage sync changes: $e');
      rethrow;
    }
  }

  @override
  Future<bool> hasUnsyncedAppUsageChanges({DateTime? lastSyncTimestamp}) async {
    await _ensureInitialized();
    try {
      final db = await this.database;
      return await db.transaction((txn) async {
        return await _appUsageDao.hasUnsyncedAppUsageChanges(
          lastSyncTimestamp: lastSyncTimestamp,
          txn: txn,
        );
      });
    } catch (e) {
      print(
        'SqfliteDatabase: Error checking for unsynced app usage changes: $e',
      );
      return false;
    }
  }

  @override
  Future<int> getAppUsageCountForDate(String date) async {
    await _ensureInitialized();
    try {
      final db = await this.database;
      return await db.transaction((txn) async {
        return await _appUsageDao.getAppUsageCountForDate(date, txn: txn);
      });
    } catch (e) {
      print('SqfliteDatabase: Error in getAppUsageCountForDate: $e');
      throw UnimplementedError(
        'getAppUsageCountForDate not fully implemented or DAO error: $e',
      );
    }
  }

  // EmotionRecord Methods
  @override
  Future<void> saveEmotion(EmotionRecord emotion) async {
    await _ensureInitialized();
    try {
      // EmotionDao.saveEmotion handles its own logic for insert/update based on date/hour
      await _emotionDao.saveEmotion(emotion);
    } catch (e) {
      print('SqfliteDatabase: Error saving emotion: $e');
      rethrow;
    }
  }

  @override
  Future<EmotionRecord?> getEmotionForHour(String date, int hour) async {
    await _ensureInitialized();
    try {
      return await _emotionDao.getEmotionForHour(date, hour);
    } catch (e) {
      print('SqfliteDatabase: Error getting emotion for hour $date $hour: $e');
      return null;
    }
  }

  @override
  Future<List<EmotionRecord>> getEmotionsForDate(String date) async {
    await _ensureInitialized();
    try {
      return await _emotionDao.getEmotionsForDate(date);
    } catch (e) {
      print('SqfliteDatabase: Error getting emotions for date $date: $e');
      return [];
    }
  }

  @override
  Future<EmotionRecord?> getEmotionById(String id) async {
    await _ensureInitialized();
    try {
      return await _emotionDao.getEmotionByClientTempId(id);
    } catch (e) {
      print('SqfliteDatabase: Error getting emotion by id $id: $e');
      return null;
    }
  }

  @override
  Future<void> deleteEmotion(String id) async {
    await _ensureInitialized();
    try {
      // EmotionDao.deleteEmotion performs a soft delete using the clientTempId (which is 'id' here)
      await _emotionDao.deleteEmotion(id);
    } catch (e) {
      print('SqfliteDatabase: Error deleting emotion by id $id: $e');
      rethrow;
    }
  }

  @override
  Future<List<EmotionRecord>> getUnsyncedEmotions({
    DateTime? lastSyncTimestamp,
  }) async {
    await _ensureInitialized();
    try {
      final db = await this.database;
      return await db.transaction((txn) async {
        return await _emotionDao.getUnsyncedEmotions(
          lastSyncTimestamp: lastSyncTimestamp,
          txn: txn,
        );
      });
    } catch (e) {
      print('SqfliteDatabase: Error getting unsynced emotions: $e');
      return [];
    }
  }

  @override
  Future<void> markEmotionsAsSynced(
    List<String> clientTempIds,
    DateTime syncTimestamp, {
    Map<String, String>? serverIds,
  }) async {
    await _ensureInitialized();
    try {
      final db = await this.database;
      await db.transaction((txn) async {
        await _emotionDao.markEmotionsAsSynced(
          clientTempIds,
          syncTimestamp,
          serverIds: serverIds,
          txn: txn,
        );
      });
    } catch (e) {
      print('SqfliteDatabase: Error marking emotions as synced: $e');
      rethrow;
    }
  }

  @override
  Future<bool> hasUnsyncedEmotionChanges({DateTime? lastSyncTimestamp}) async {
    await _ensureInitialized();
    try {
      return await _emotionDao.hasUnsyncedChanges(
        lastSyncTimestamp: lastSyncTimestamp,
      );
    } catch (e) {
      print('SqfliteDatabase: Error checking for unsynced emotion changes: $e');
      return false;
    }
  }

  @override
  Future<void> applyEmotionSyncChanges(
    List<Map<String, dynamic>> changes,
  ) async {
    await _ensureInitialized();
    try {
      final emotionsToUpsert =
          changes
              .where(
                (change) =>
                    change['status'] != 'deleted' && change['data'] != null,
              )
              .map(
                (change) => EmotionRecord.fromMap(
                  change['data'] as Map<String, dynamic>,
                ),
              )
              .toList();

      // For EmotionDao, applyEmotionSyncChanges takes List<EmotionRecord>
      // It handles deletions internally based on isDeleted flag in the EmotionRecord models.
      // So, we just pass all server emotions.
      final db = await this.database;
      await db.transaction((txn) async {
        await _emotionDao.applyEmotionSyncChanges(
          serverEmotions: emotionsToUpsert,
          txn: txn,
        );
      });
    } catch (e) {
      print('SqfliteDatabase: Error applying emotion sync changes: $e');
      rethrow;
    }
  }

  @override
  Future<List<EmotionRecord>> getDeletedAndUnsyncedEmotions({
    DateTime? lastSyncTimestamp,
  }) async {
    await _ensureInitialized();
    try {
      final db = await this.database;
      return await db.transaction((txn) async {
        return await _emotionDao.getDeletedAndUnsyncedEmotions(
          lastSyncTimestamp: lastSyncTimestamp,
          txn: txn,
        );
      });
    } catch (e) {
      print('SqfliteDatabase: Error getting deleted and unsynced emotions: $e');
      return [];
    }
  }

  // LocationRecord Methods
  @override
  Future<void> saveLocationLog(LocationRecord log) async {
    await _ensureInitialized();
    try {
      await _locationDao.saveLocationLog(log);
    } catch (e) {
      print('SqfliteDatabase: Error saving location log: $e');
      rethrow;
    }
  }

  @override
  Future<LocationRecord?> getLocationLogById(String id) async {
    await _ensureInitialized();
    try {
      return await _locationDao.getLocationLogByClientTempId(id);
    } catch (e) {
      print('SqfliteDatabase: Error getting location log by id $id: $e');
      return null;
    }
  }

  @override
  Future<LocationRecord?> getLocationLogByClientTempId(
    String clientTempId,
  ) async {
    await _ensureInitialized();
    try {
      return await _locationDao.getLocationLogByClientTempId(clientTempId);
    } catch (e) {
      print(
        'SqfliteDatabase: Error getting location log by clientTempId $clientTempId: $e',
      );
      return null;
    }
  }

  @override
  Future<List<LocationRecord>> getLocationLogsForDate(DateTime date) async {
    await _ensureInitialized();
    try {
      return await _locationDao.getLocationLogsForDate(date);
    } catch (e) {
      print('SqfliteDatabase: Error getting location logs for date $date: $e');
      return [];
    }
  }

  @override
  Future<List<LocationRecord>> getUnsyncedLocationLogs({
    DateTime? lastSyncTimestamp,
  }) async {
    await _ensureInitialized();
    try {
      final db = await this.database;
      return await db.transaction((txn) async {
        return await _locationDao.getUnsyncedLocationLogs(
          lastSyncTimestamp: lastSyncTimestamp,
          txn: txn,
        );
      });
    } catch (e) {
      print('SqfliteDatabase: Error getting unsynced location logs: $e');
      return [];
    }
  }

  @override
  Future<void> markLocationLogsAsSynced(
    List<String> clientTempIds,
    DateTime syncTimestamp, {
    Map<String, String>? serverIds,
  }) async {
    await _ensureInitialized();
    try {
      final db = await this.database;
      await db.transaction((txn) async {
        await _locationDao.markLocationLogsAsSynced(
          clientTempIds,
          syncTimestamp,
          serverIds: serverIds,
          txn: txn,
        );
      });
    } catch (e) {
      print('SqfliteDatabase: Error marking location logs as synced: $e');
      rethrow;
    }
  }

  @override
  Future<void> deleteLocationLog(String id) async {
    await _ensureInitialized();
    try {
      await _locationDao.deleteLocationLog(
        id,
      ); // DAO's deleteLocationLog is a soft delete
    } catch (e) {
      print('SqfliteDatabase: Error deleting location log by id $id: $e');
      rethrow;
    }
  }

  @override
  Future<void> hardDeleteLocationLog(String id) async {
    await _ensureInitialized();
    try {
      await _locationDao.hardDeleteLocationLog(
        id,
      ); // DAO's hardDeleteLocationLog
    } catch (e) {
      print('SqfliteDatabase: Error hard deleting location log by id $id: $e');
      rethrow;
    }
  }

  @override
  Future<bool> hasUnsyncedLocationChanges({DateTime? lastSyncTimestamp}) async {
    await _ensureInitialized();
    try {
      final db = await this.database;
      return await db.transaction((txn) async {
        return await _locationDao.hasUnsyncedLocationChanges(
          lastSyncTimestamp: lastSyncTimestamp,
          txn: txn,
        );
      });
    } catch (e) {
      print(
        'SqfliteDatabase: Error checking for unsynced location changes: $e',
      );
      return false;
    }
  }

  @override
  Future<void> applyLocationSyncChanges(
    List<Map<String, dynamic>> changes,
  ) async {
    await _ensureInitialized();
    try {
      final locationsToUpsert =
          changes
              .where(
                (change) => change['data'] != null,
              ) // Process all items, DAO handles isDeleted
              .map(
                (change) => LocationRecord.fromMap(
                  change['data'] as Map<String, dynamic>,
                ),
              )
              .toList();

      final db = await this.database;
      await db.transaction((txn) async {
        // LocationDao.applyLocationLogSyncChanges handles upserts and deletions based on isDeleted flag
        await _locationDao.applyLocationLogSyncChanges(
          locationsToUpsert,
          txn: txn,
        );
      });
    } catch (e) {
      print('SqfliteDatabase: Error applying location sync changes: $e');
      rethrow;
    }
  }

  @override
  Future<List<LocationRecord>> getDeletedAndUnsyncedLocationLogs({
    DateTime? lastSyncTimestamp,
  }) async {
    await _ensureInitialized();
    try {
      final db = await this.database;
      return await db.transaction((txn) async {
        return await _locationDao.getDeletedAndUnsyncedLocationLogs(
          lastSyncTimestamp: lastSyncTimestamp,
          txn: txn,
        );
      });
    } catch (e) {
      print(
        'SqfliteDatabase: Error getting deleted and unsynced location logs: $e',
      );
      return [];
    }
  }

  @override
  Future<List<LocationRecord>> getLocationLogsForUserAndDate(
    String userId,
    DateTime date,
  ) async {
    await _ensureInitialized();
    try {
      final db = await this.database;
      return await db.transaction((txn) async {
        return await _locationDao.getLocationsForUserAndDate(
          userId,
          date,
          txn: txn,
        );
      });
    } catch (e) {
      print('SqfliteDatabase: Error in getLocationLogsForUserAndDate: $e.');
      throw UnimplementedError('getLocationLogsForUserAndDate failed: $e');
    }
  }

  @override
  Future<List<LocationRecord>> getAllLocationLogsForUser(String userId) async {
    await _ensureInitialized();
    try {
      final db = await this.database;
      return await db.transaction((txn) async {
        return await _locationDao.getAllLocationLogsForUser(userId, txn: txn);
      });
    } catch (e) {
      print('SqfliteDatabase: Error in getAllLocationLogsForUser: $e.');
      throw UnimplementedError('getAllLocationLogsForUser failed: $e');
    }
  }

  @override
  Future<List<LocationRecord>> getLocationLogsForUserInRange(
    String userId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    await _ensureInitialized();
    try {
      final db = await this.database;
      return await db.transaction((txn) async {
        return await _locationDao.getLocationLogsForUserInRange(
          userId,
          startDate,
          endDate,
          txn: txn,
        );
      });
    } catch (e) {
      print('SqfliteDatabase: Error in getLocationLogsForUserInRange: $e.');
      throw UnimplementedError('getLocationLogsForUserInRange failed: $e');
    }
  }

  @override
  Future<void> deleteLocationLogsInRange(
    String userId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    await _ensureInitialized();
    try {
      final db = await this.database;
      await db.transaction((txn) async {
        await _locationDao.deleteLocationLogsInRange(
          userId,
          startDate,
          endDate,
          txn: txn,
        );
      });
    } catch (e) {
      print('SqfliteDatabase: Error in deleteLocationLogsInRange: $e.');
      throw UnimplementedError('deleteLocationLogsInRange failed: $e');
    }
  }

  @override
  Future<void> deleteAllLocationLogsForUser(String userId) async {
    await _ensureInitialized();
    try {
      final db = await this.database;
      await db.transaction((txn) async {
        await _locationDao.deleteAllLocationLogsForUser(userId, txn: txn);
      });
    } catch (e) {
      print('SqfliteDatabase: Error in deleteAllLocationLogsForUser: $e.');
      throw UnimplementedError('deleteAllLocationLogsForUser failed: $e');
    }
  }

  // PedometerData Methods
  @override
  Future<void> insertPedometerData(PedometerData data) async {
    await _ensureInitialized();
    try {
      await _pedometerDao.insertPedometerData(data);
    } catch (e) {
      print('SqfliteDatabase: Error inserting pedometer data: $e');
      rethrow;
    }
  }

  @override
  Future<PedometerData?> getPedometerDataById(String id) async {
    await _ensureInitialized();
    try {
      return await _pedometerDao.getPedometerDataByClientTempId(id);
    } catch (e) {
      print('SqfliteDatabase: Error getting pedometer data by id $id: $e');
      return null;
    }
  }

  @override
  Future<List<PedometerData>> getPedometerDataByDate(String date) async {
    await _ensureInitialized();
    try {
      final dateTime = DateTime.tryParse(date);
      if (dateTime == null) {
        print(
          'SqfliteDatabase: Invalid date string for getPedometerDataByDate: $date',
        );
        return [];
      }
      // PedometerDao.getPedometerDataByDate returns PedometerData?
      final singleData = await _pedometerDao.getPedometerDataByDate(dateTime);
      return singleData == null ? [] : [singleData];
    } catch (e) {
      print('SqfliteDatabase: Error getting pedometer data by date $date: $e');
      return [];
    }
  }

  @override
  Future<List<PedometerData>> getAllPedometerData() async {
    await _ensureInitialized();
    throw UnimplementedError(
      'getAllPedometerData not implemented as PedometerDao does not support it directly.',
    );
  }

  @override
  Future<void> updatePedometerData(PedometerData data) async {
    await _ensureInitialized();
    try {
      await _pedometerDao.updatePedometerData(data);
    } catch (e) {
      print('SqfliteDatabase: Error updating pedometer data: $e');
      rethrow;
    }
  }

  @override
  Future<void> deletePedometerData(String id) async {
    await _ensureInitialized();
    try {
      await _pedometerDao.softDeletePedometerDataByClientTempId(id);
    } catch (e) {
      print('SqfliteDatabase: Error deleting pedometer data by id $id: $e');
      rethrow;
    }
  }

  @override
  Future<List<PedometerData>> getUnsyncedPedometerData({
    DateTime? lastSyncTimestamp,
  }) async {
    await _ensureInitialized();
    try {
      // PedometerDao.getUnsyncedPedometerData does not take lastSyncTimestamp.
      // The parameter from AbstractDatabase is ignored here.
      final db = await this.database;
      return await db.transaction((txn) async {
        return await _pedometerDao.getUnsyncedPedometerData(txn: txn);
      });
    } catch (e) {
      print('SqfliteDatabase: Error getting unsynced pedometer data: $e');
      return [];
    }
  }

  @override
  Future<void> markPedometerDataAsSynced(
    List<String> clientTempIds,
    DateTime syncTimestamp, {
    Map<String, String>? serverIds,
  }) async {
    await _ensureInitialized();
    try {
      final List<Map<String, String>> clientServerIdMap =
          clientTempIds.map((tempId) {
            return {
              'clientTempId': tempId,
              'serverId': serverIds?[tempId] ?? tempId,
            };
          }).toList();
      final db = await this.database;
      await db.transaction((txn) async {
        await _pedometerDao.markPedometerDataAsSynced(
          clientServerIdMap,
          syncTimestamp,
          txn: txn,
        );
      });
    } catch (e) {
      print('SqfliteDatabase: Error marking pedometer data as synced: $e');
      rethrow;
    }
  }

  @override
  Future<void> applyPedometerDataSyncChanges(
    List<PedometerData> serverData,
  ) async {
    await _ensureInitialized();
    try {
      final db = await this.database;
      await db.transaction((txn) async {
        await _pedometerDao.applyPedometerDataSyncChanges(serverData, txn: txn);
      });
    } catch (e) {
      print('SqfliteDatabase: Error applying pedometer data sync changes: $e');
      rethrow;
    }
  }

  @override
  Future<bool> hasUnsyncedPedometerChanges({
    DateTime? lastSyncTimestamp,
  }) async {
    await _ensureInitialized();
    try {
      // PedometerDao does not have hasUnsyncedChanges.
      // Implement by fetching unsynced data and checking if the list is empty.
      // The lastSyncTimestamp is not used by the DAO's getUnsyncedPedometerData.
      final unsynced =
          await getUnsyncedPedometerData(); // This already uses a transaction
      return unsynced.isNotEmpty;
    } catch (e) {
      print(
        'SqfliteDatabase: Error checking for unsynced pedometer changes: $e',
      );
      return false;
    }
  }

  // --- WeatherData Methods ---
  @override
  Future<void> insertWeatherData(WeatherData weatherData) async {
    await _ensureInitialized();
    try {
      // DAO's insertWeatherData returns Future<int>, AbstractDatabase expects Future<void>
      await _weatherDao.insertWeatherData(weatherData);
    } catch (e) {
      print('SqfliteDatabase: Error inserting weather data: $e');
      rethrow;
    }
  }

  @override
  Future<List<WeatherData>> getAllWeatherData() async {
    await _ensureInitialized();
    // WeatherDao does not have a direct getAllWeatherData method.
    throw UnimplementedError(
      'getAllWeatherData not implemented as WeatherDao does not support it directly.',
    );
  }

  @override
  Future<WeatherData?> getWeatherDataById(String id) async {
    await _ensureInitialized();
    try {
      return await _weatherDao.getWeatherDataByClientTempId(id);
    } catch (e) {
      print('SqfliteDatabase: Error getting weather data by ID $id: $e');
      rethrow;
    }
  }

  @override
  Future<List<WeatherData>> getWeatherDataByDate(String date) async {
    await _ensureInitialized();
    try {
      final dateTime = DateTime.tryParse(date);
      if (dateTime == null) {
        print(
          'SqfliteDatabase: Invalid date string for getWeatherDataByDate: $date',
        );
        return [];
      }
      final weatherData = await _weatherDao.getWeatherDataByDate(dateTime);
      return weatherData == null ? [] : [weatherData];
    } catch (e) {
      print('SqfliteDatabase: Error getting weather data by date $date: $e');
      rethrow;
    }
  }

  @override
  Future<void> updateWeatherData(WeatherData weatherData) async {
    await _ensureInitialized();
    try {
      // DAO's updateWeatherData returns Future<int>, AbstractDatabase expects Future<void>
      await _weatherDao.updateWeatherData(weatherData);
    } catch (e) {
      print('SqfliteDatabase: Error updating weather data: $e');
      rethrow;
    }
  }

  @override
  Future<void> deleteWeatherData(String id) async {
    await _ensureInitialized();
    try {
      // DAO's softDeleteWeatherDataByClientTempId returns Future<int>, AbstractDatabase expects Future<void>
      await _weatherDao.softDeleteWeatherDataByClientTempId(id);
    } catch (e) {
      print('SqfliteDatabase: Error deleting weather data by ID $id: $e');
      rethrow;
    }
  }

  @override
  Future<List<WeatherData>> getUnsyncedWeatherData({
    DateTime? lastSyncTimestamp,
  }) async {
    await _ensureInitialized();
    try {
      // WeatherDao.getUnsyncedWeatherData() does not take lastSyncTimestamp.
      // The parameter from AbstractDatabase is ignored here.
      return await _weatherDao.getUnsyncedWeatherData();
    } catch (e) {
      print('SqfliteDatabase: Error getting unsynced weather data: $e');
      rethrow;
    }
  }

  @override
  Future<void> markWeatherDataAsSynced(
    List<String> clientTempIds,
    DateTime syncTimestamp, {
    Map<String, String>? serverIds,
  }) async {
    await _ensureInitialized();
    try {
      final List<Map<String, String>> clientServerIdMap =
          clientTempIds.map((tempId) {
            return {
              'clientTempId': tempId,
              'serverId': serverIds?[tempId] ?? tempId,
            };
          }).toList();
      final db = await this.database;
      await db.transaction((txn) async {
        await _weatherDao.markWeatherDataAsSynced(
          clientServerIdMap,
          syncTimestamp,
          txn: txn,
        );
      });
    } catch (e) {
      print('SqfliteDatabase: Error marking weather data as synced: $e');
      rethrow;
    }
  }

  @override
  Future<void> applyWeatherDataSyncChanges(
    List<WeatherData> serverWeatherData,
  ) async {
    await _ensureInitialized();
    try {
      final db = await this.database;
      await db.transaction((txn) async {
        await _weatherDao.applyWeatherDataSyncChanges(
          serverWeatherData,
          txn: txn,
        );
      });
    } catch (e) {
      print('SqfliteDatabase: Error applying weather data sync changes: $e');
      rethrow;
    }
  }

  @override
  Future<bool> hasUnsyncedWeatherChanges({DateTime? lastSyncTimestamp}) async {
    await _ensureInitialized();
    try {
      // WeatherDao.getUnsyncedWeatherData() does not take lastSyncTimestamp.
      final unsynced = await _weatherDao.getUnsyncedWeatherData();
      return unsynced.isNotEmpty;
    } catch (e) {
      print('SqfliteDatabase: Error checking for unsynced weather changes: $e');
      return false;
    }
  }

  @override
  Future<void> importWeathers(
    List<Map<String, dynamic>> weathersData,
    DateTime syncTime,
  ) async {
    await _ensureInitialized();
    try {
      final List<WeatherData> serverDataList =
          weathersData.map((dataMap) {
            final clientTempId =
                dataMap['clientTempId'] as String? ??
                'weather_${DateTime.now().millisecondsSinceEpoch}_${dataMap.hashCode}';

            return WeatherData.fromMap({
              ...dataMap,
              'clientTempId': clientTempId,
              'syncStatus': SyncStatus.synced.name,
              'lastSynced': syncTime.toIso8601String(),
              'updatedAt': dataMap['updatedAt'] ?? syncTime.toIso8601String(),
              'createdAt': dataMap['createdAt'] ?? syncTime.toIso8601String(),
            });
          }).toList();

      final db = await this.database;
      await db.transaction((txn) async {
        await _weatherDao.applyWeatherDataSyncChanges(serverDataList, txn: txn);
      });
    } catch (e) {
      print('SqfliteDatabase: Error importing weathers: $e');
      rethrow;
    }
  }

  // Add missing import methods
  @override
  Future<void> importAppUsages(
    List<Map<String, dynamic>> appUsagesData,
    DateTime syncTime,
  ) async {
    await _ensureInitialized();
    if (_db == null) throw Exception("Database not initialized.");
    try {
      final List<AppUsageModel> serverAppUsages =
          appUsagesData.map((dataMap) {
            final clientTempId =
                dataMap['clientTempId'] as String? ??
                'appusage_${DateTime.now().millisecondsSinceEpoch}_${dataMap.hashCode}';
            return AppUsageModel.fromJson({
              ...dataMap,
              'clientTempId': clientTempId,
              'syncStatus': SyncStatus.synced.name,
              'updatedAt':
                  (dataMap['updatedAt'] != null
                          ? DateTime.tryParse(dataMap['updatedAt'])
                          : syncTime)
                      ?.millisecondsSinceEpoch,
              'lastSynced':
                  syncTime
                      .millisecondsSinceEpoch, // AppUsageModel uses int for these
            });
          }).toList();

      await _db!.transaction((txn) async {
        // AppUsageDao.applyAppUsageSyncChanges handles upserts
        await _appUsageDao.applyAppUsageSyncChanges(serverAppUsages, txn: txn);
      });
    } catch (e) {
      print('SqfliteDatabase: Error importing app usages: $e');
      rethrow;
    }
  }

  @override
  Future<void> importEmotions(
    List<Map<String, dynamic>> emotionsData,
    DateTime syncTime,
  ) async {
    await _ensureInitialized();
    if (_db == null) throw Exception("Database not initialized.");
    try {
      final List<EmotionRecord> serverEmotions =
          emotionsData.map((dataMap) {
            final clientTempId =
                dataMap['id'] as String? ??
                'emotion_${DateTime.now().millisecondsSinceEpoch}_${dataMap.hashCode}';
            return EmotionRecord.fromMap({
              ...dataMap,
              'id': clientTempId, // EmotionRecord uses 'id' as clientTempId
              'syncStatus': SyncStatus.synced.name,
              'updatedAt': dataMap['updatedAt'] ?? syncTime.toIso8601String(),
              'lastSynced': syncTime.toIso8601String(),
            });
          }).toList();

      await _db!.transaction((txn) async {
        await _emotionDao.applyEmotionSyncChanges(
          serverEmotions: serverEmotions,
          txn: txn,
        );
      });
    } catch (e) {
      print('SqfliteDatabase: Error importing emotions: $e');
      rethrow;
    }
  }

  @override
  Future<void> importLocations(
    List<Map<String, dynamic>> locationsData,
    DateTime syncTime,
  ) async {
    await _ensureInitialized();
    if (_db == null) throw Exception("Database not initialized.");
    try {
      final List<LocationRecord> serverLocations =
          locationsData.map((dataMap) {
            final clientTempId =
                dataMap['clientTempId'] as String? ??
                'location_${DateTime.now().millisecondsSinceEpoch}_${dataMap.hashCode}';
            return LocationRecord.fromMap({
              ...dataMap,
              'clientTempId': clientTempId,
              'syncStatus': SyncStatus.synced.name,
              'updatedAt': dataMap['updatedAt'] ?? syncTime.toIso8601String(),
              'lastSynced': syncTime.toIso8601String(),
            });
          }).toList();

      await _db!.transaction((txn) async {
        await _locationDao.applyLocationLogSyncChanges(
          serverLocations,
          txn: txn,
        );
      });
    } catch (e) {
      print('SqfliteDatabase: Error importing locations: $e');
      rethrow;
    }
  }

  @override
  Future<void> importPedometers(
    List<Map<String, dynamic>> pedometersData,
    DateTime syncTime,
  ) async {
    await _ensureInitialized();
    if (_db == null) throw Exception("Database not initialized.");
    try {
      final List<PedometerData> serverPedometers =
          pedometersData.map((dataMap) {
            final clientTempId =
                dataMap['clientTempId'] as String? ??
                'pedometer_${DateTime.now().millisecondsSinceEpoch}_${dataMap.hashCode}';
            return PedometerData.fromMap({
              ...dataMap,
              'clientTempId': clientTempId,
              'syncStatus': SyncStatus.synced.name,
              'updatedAt':
                  DateTime.tryParse(dataMap['updatedAt'] as String? ?? '') ??
                  syncTime,
              'lastSynced': syncTime,
            });
          }).toList();

      await _db!.transaction((txn) async {
        await _pedometerDao.applyPedometerDataSyncChanges(
          serverPedometers,
          txn: txn,
        );
      });
    } catch (e) {
      print('SqfliteDatabase: Error importing pedometers: $e');
      rethrow;
    }
  }
}
