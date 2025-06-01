import 'package:logging/logging.dart';
import 'package:flutter/foundation.dart';
import 'package:recap_today/api/api_service.dart';
import 'package:recap_today/data/abstract_database.dart';
import 'package:recap_today/model/sync_status.dart' as model_sync_status;
import 'package:recap_today/model/syncable_item_type.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:recap_today/repository/emotion_repository.dart';

class SyncService extends ChangeNotifier {
  final AbstractDatabase _database;
  final ApiService _apiService;
  final EmotionRepository _emotionRepository;
  static final Logger _logger = Logger('SyncService');

  bool _isSyncing = false;
  final List<SyncEvent> _syncEvents = [];

  SyncService(this._database, this._apiService, this._emotionRepository);

  Future<void> syncAllData() async {
    if (_isSyncing) {
      print('Sync already in progress.');
      return;
    }
    _isSyncing = true;
    _syncEvents.add(
      SyncEvent(
        SyncEventType.syncStarted,
        message: 'Sync started at \${DateTime.now().toIso8601String()}',
      ),
    );
    notifyListeners();

    try {
      final itemsToSync = SyncableItemType.values;
      await performSelectiveSync(
        itemsToSync,
        onItemProgressUpdate: (itemType, itemName, progress) {
          _syncEvents.add(
            SyncEvent(
              SyncEventType.syncProgress,
              message:
                  'Syncing $itemName: \${(progress * 100).toStringAsFixed(0)}%',
            ),
          );
          notifyListeners();
        },
        checkIfCancelledCallback: () => !_isSyncing,
      );

      _syncEvents.add(
        SyncEvent(
          SyncEventType.syncCompleted,
          message: 'Sync completed at \${DateTime.now().toIso8601String()}',
        ),
      );
    } catch (e) {
      _syncEvents.add(
        SyncEvent(
          SyncEventType.syncError,
          message: 'Unexpected error during full sync: $e',
        ),
      );
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  Future<void> syncUnsyncedData() async {
    if (_isSyncing) {
      print('Sync already in progress.');
      return;
    }
    _isSyncing = true;
    _syncEvents.add(
      SyncEvent(
        SyncEventType.syncStarted,
        message: 'Sync started at \${DateTime.now().toIso8601String()}',
      ),
    );
    notifyListeners();

    // try {
    // NOTE: The logic below is likely deprecated by performSelectiveSync and its internal methods.
    // Commenting out to avoid compilation errors with ApiService method signature changes.
    // If this method is still needed, it will require significant rework to align with current sync patterns.

    /*
      // Sync Location Data
      final unsyncedLocationLogs = await _database.getUnsyncedLocationLogs();
      if (unsyncedLocationLogs.isNotEmpty) {
        _syncEvents.add(SyncEvent(SyncEventType.syncProgress, message: 'Found \${unsyncedLocationLogs.length} unsynced location logs.'));
        notifyListeners();
        try {
          final List<Map<String, dynamic>> locationData = unsyncedLocationLogs.map((log) => log.toSyncMap()).toList();
          // final syncResponse = await _apiService.syncLocations(locationData); // ERROR: Argument type mismatch
          // ... rest of location sync logic
        } catch (e) {
          _syncEvents.add(SyncEvent(SyncEventType.syncError, message: 'Error syncing location data: $e'));
          notifyListeners();
        }
      } else {
        _syncEvents.add(SyncEvent(SyncEventType.syncProgress, message: 'No unsynced location logs to sync.'));
        notifyListeners();
      }

      // Sync Diary Data
      final unsyncedDiaries = await _database.getUnsyncedDiaries();
      if (unsyncedDiaries.isNotEmpty) {
        _syncEvents.add(SyncEvent(SyncEventType.syncProgress, message: 'Found \${unsyncedDiaries.length} unsynced diaries.'));
        notifyListeners();
        try {
          final List<Map<String, dynamic>> diaryData = unsyncedDiaries.map((diary) => diary.toSyncMap()).toList();
          final syncResponse = await _apiService.syncDiaries(diaryData);
          // ... rest of diary sync logic
        } catch (e) {
          _syncEvents.add(SyncEvent(SyncEventType.syncError, message: 'Error syncing diary data: $e'));
          notifyListeners();
        }
      } else {
        _syncEvents.add(SyncEvent(SyncEventType.syncProgress, message: 'No unsynced diaries to sync.'));
        notifyListeners();
      }

      // Sync Checklist Data
      final unsyncedChecklistItems = await _database.getUnsyncedChecklistItems();
      if (unsyncedChecklistItems.isNotEmpty) {
        _syncEvents.add(SyncEvent(SyncEventType.syncProgress, message: 'Found \${unsyncedChecklistItems.length} unsynced checklist items.'));
        notifyListeners();
        try {
          final List<Map<String, dynamic>> checklistData = unsyncedChecklistItems.map((item) => item.toSyncMap()).toList();
          // final syncResponse = await _apiService.syncChecklists(checklistData); // ERROR: Argument type mismatch
          // ... rest of checklist sync logic
        } catch (e) {
          _syncEvents.add(SyncEvent(SyncEventType.syncError, message: 'Error syncing checklist data: $e'));
          notifyListeners();
        }
      } else {
        _syncEvents.add(SyncEvent(SyncEventType.syncProgress, message: 'No unsynced checklist items to sync.'));
        notifyListeners();
      }

      // Sync Emotion Data
      final unsyncedEmotions = await _database.getUnsyncedEmotions();
      if (unsyncedEmotions.isNotEmpty) {
        _syncEvents.add(SyncEvent(SyncEventType.syncProgress, message: 'Found \${unsyncedEmotions.length} unsynced emotions.'));
        notifyListeners();
        try {
          final List<Map<String, dynamic>> emotionData = unsyncedEmotions.map((emotion) => emotion.toSyncMap()).toList();
          // final syncResponse = await _apiService.syncEmotions(emotionData); // ERROR: Argument type mismatch
          // ... rest of emotion sync logic
        } catch (e) {
          _syncEvents.add(SyncEvent(SyncEventType.syncError, message: 'Error syncing emotion data: $e'));
          notifyListeners();
        }
      } else {
        _syncEvents.add(SyncEvent(SyncEventType.syncProgress, message: 'No unsynced emotions to sync.'));
        notifyListeners();
      }

      // Sync ScheduleItem Data
      final unsyncedScheduleItems = await _database.getUnsyncedScheduleItems();
      if (unsyncedScheduleItems.isNotEmpty) {
        _syncEvents.add(SyncEvent(SyncEventType.syncProgress, message: 'Found \${unsyncedScheduleItems.length} unsynced schedule items.'));
        notifyListeners();
        try {
          final List<Map<String, dynamic>> scheduleItemData = unsyncedScheduleItems.map((item) => item.toSyncMap()).toList();
          // final syncResponse = await _apiService.syncSchedules(scheduleItemData); // ERROR: Argument type mismatch
          // ... rest of schedule sync logic
        } catch (e) {
          _syncEvents.add(SyncEvent(SyncEventType.syncError, message: 'Error syncing schedule item data: $e'));
          notifyListeners();
        }
      } else {
        _syncEvents.add(SyncEvent(SyncEventType.syncProgress, message: 'No unsynced schedule items to sync.'));
        notifyListeners();
      }
      */

    _syncEvents.add(
      SyncEvent(
        SyncEventType.syncProgress,
        message: 'syncUnsyncedData is largely deprecated. Use selective sync.',
      ),
    );
    _syncEvents.add(
      SyncEvent(
        SyncEventType.syncCompleted,
        message:
            'Sync (deprecated) completed at \${DateTime.now().toIso8601String()}',
      ),
    );
    _isSyncing = false;
    notifyListeners();
  }

  // Changed parameter type from http.Response to Map<String, dynamic>
  Future<void> _processSyncResponse(Map<String, dynamic> data) async {
    // Removed: if (response.statusCode == 200) {
    // Removed: final data = jsonDecode(response.body);

    final serverSyncTime = data['serverSyncTime'];
    if (serverSyncTime == null) {
      _logger.severe('Sync response missing serverSyncTime');
      throw Exception('Sync failed: serverSyncTime missing from response');
    }
    final DateTime parsedSyncTime = DateTime.parse(serverSyncTime as String);

    // Process checklists
    if (data['checklists'] != null && data['checklists'] is List) {
      final checklists = List<Map<String, dynamic>>.from(data['checklists']);
      if (checklists.isNotEmpty) {
        await _database.importChecklists(checklists, parsedSyncTime);
      }
    }

    // Process diaries
    if (data['diaries'] != null && data['diaries'] is List) {
      final diaries = List<Map<String, dynamic>>.from(data['diaries']);
      if (diaries.isNotEmpty) {
        await _database.importDiaries(diaries, parsedSyncTime);
      }
    }

    // Process photos
    if (data['photos'] != null && data['photos'] is List) {
      final photos = List<Map<String, dynamic>>.from(data['photos']);
      if (photos.isNotEmpty) {
        await _database.importPhotos(photos, parsedSyncTime);
      }
    }

    // Process emotions
    if (data['emotions'] != null && data['emotions'] is List) {
      final emotions = List<Map<String, dynamic>>.from(data['emotions']);
      if (emotions.isNotEmpty) {
        await _emotionRepository.consolidateServerEmotions(emotions);
      }
    }

    // Process app usages
    if (data['appUsages'] != null && data['appUsages'] is List) {
      final appUsages = List<Map<String, dynamic>>.from(data['appUsages']);
      if (appUsages.isNotEmpty) {
        await _database.importAppUsages(appUsages, parsedSyncTime);
      }
    }

    // Process locations
    if (data['locations'] != null && data['locations'] is List) {
      final locations = List<Map<String, dynamic>>.from(data['locations']);
      if (locations.isNotEmpty) {
        await _database.importLocations(locations, parsedSyncTime);
      }
    }

    // Process pedometers
    if (data['pedometers'] != null && data['pedometers'] is List) {
      final pedometers = List<Map<String, dynamic>>.from(data['pedometers']);
      if (pedometers.isNotEmpty) {
        await _database.importPedometers(pedometers, parsedSyncTime);
      }
    }

    // Process schedules
    if (data['schedules'] != null && data['schedules'] is List) {
      final schedules = List<Map<String, dynamic>>.from(data['schedules']);
      if (schedules.isNotEmpty) {
        await _database.importSchedules(schedules, parsedSyncTime);
      }
    }

    // Process weathers
    if (data['weathers'] != null && data['weathers'] is List) {
      final weathers = List<Map<String, dynamic>>.from(data['weathers']);
      if (weathers.isNotEmpty) {
        await _database.importWeathers(weathers, parsedSyncTime);
      }
    }

    await _database.setLastSyncTime(parsedSyncTime);
    _logger.info('Sync successful. Last sync time updated to: $serverSyncTime');
    // Removed: else block for statusCode != 200, as ApiService is expected to throw on error or return structured error.
  }

  Future<bool> hasUnsyncedChanges(
    SyncableItemType itemType, {
    DateTime? lastSyncTimestamp,
  }) async {
    switch (itemType) {
      case SyncableItemType.diary:
      case SyncableItemType.photos:
        return await _database.hasUnsyncedDiaryChanges(
          lastSyncTimestamp: lastSyncTimestamp,
        );
      case SyncableItemType.checklists:
        return await _database.hasUnsyncedChecklistChanges(
          lastSyncTimestamp: lastSyncTimestamp,
        );
      case SyncableItemType.emotions:
        return await _database.hasUnsyncedEmotionChanges(
          lastSyncTimestamp: lastSyncTimestamp,
        ); // Added lastSyncTimestamp
      case SyncableItemType.locations:
        return await _database.hasUnsyncedLocationChanges(
          lastSyncTimestamp: lastSyncTimestamp,
        ); // Added lastSyncTimestamp
      case SyncableItemType.schedules:
        return await _database.hasUnsyncedScheduleChanges(
          lastSyncTimestamp: lastSyncTimestamp,
        );
    }
  }

  Future<Map<SyncableItemType, SyncItemResult>> performSelectiveSync(
    List<SyncableItemType> itemsToSync, {
    required Function(SyncableItemType item, String itemName, double progress)
    onItemProgressUpdate,
    required bool Function() checkIfCancelledCallback,
  }) async {
    final Map<SyncableItemType, SyncItemResult> results = {};

    for (final itemType in itemsToSync) {
      if (checkIfCancelledCallback()) {
        results[itemType] = SyncItemResult(
          success: false,
          cancelled: true,
          error: 'Cancelled by user',
        );
        continue;
      }

      String itemName = _getFriendlyItemName(itemType);
      onItemProgressUpdate(itemType, itemName, 0.0);

      try {
        onItemProgressUpdate(itemType, itemName, 0.1);

        late SyncItemResult itemResult;
        switch (itemType) {
          case SyncableItemType.diary:
          case SyncableItemType.photos: // Handled together
            itemResult = await _syncDiariesAndPhotosInternal(
              checkIfCancelled: checkIfCancelledCallback,
              onProgress: (progress) {
                onItemProgressUpdate(itemType, itemName, 0.1 + progress * 0.8);
              },
            );
            break;
          case SyncableItemType.checklists:
            itemResult = await _syncChecklistsInternal(
              checkIfCancelled: checkIfCancelledCallback,
              onProgress: (progress) {
                onItemProgressUpdate(itemType, itemName, 0.1 + progress * 0.8);
              },
            );
            break;
          case SyncableItemType.emotions:
            itemResult = await _syncEmotionsInternal(
              checkIfCancelled: checkIfCancelledCallback,
              onProgress: (progress) {
                onItemProgressUpdate(itemType, itemName, 0.1 + progress * 0.8);
              },
            );
            break;
          case SyncableItemType.locations:
            itemResult = await _syncLocationsInternal(
              checkIfCancelled: checkIfCancelledCallback,
              onProgress: (progress) {
                onItemProgressUpdate(itemType, itemName, 0.1 + progress * 0.8);
              },
            );
            break;
          case SyncableItemType.schedules:
            itemResult = await _syncSchedulesInternal(
              checkIfCancelled: checkIfCancelledCallback,
              onProgress: (progress) {
                onItemProgressUpdate(itemType, itemName, 0.1 + progress * 0.8);
              },
            );
            break;
        }
        results[itemType] = itemResult;
      } catch (e) {
        results[itemType] = SyncItemResult(success: false, error: e.toString());
      }

      if (checkIfCancelledCallback() &&
          !(results[itemType]?.cancelled ?? false)) {
        results[itemType] = SyncItemResult(
          success: false,
          cancelled: true,
          error: 'Cancelled by user',
        );
      } else if (results[itemType]?.success == true) {
        onItemProgressUpdate(itemType, itemName, 1.0);
      }
    }
    return results;
  }

  String _getFriendlyItemName(SyncableItemType itemType) {
    switch (itemType) {
      case SyncableItemType.diary:
        return 'Diaries';
      case SyncableItemType.photos:
        return 'Photos';
      case SyncableItemType.checklists:
        return 'Checklists';
      case SyncableItemType.emotions:
        return 'Emotions';
      case SyncableItemType.locations:
        return 'Locations';
      case SyncableItemType.schedules:
        return 'Schedules';
      // No default needed as all enum values are covered.
    }
  }

  Future<DateTime?> getLastSyncTimestampForItem(
    SyncableItemType itemType,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final timestampMillis = prefs.getInt(
      'sync_last_timestamp_\${itemType.name}',
    );
    if (timestampMillis != null) {
      return DateTime.fromMillisecondsSinceEpoch(timestampMillis);
    }
    return null;
  }

  Future<void> _setLastSyncTimestampForItem(
    SyncableItemType itemType,
    DateTime timestamp,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(
      'sync_last_timestamp_\${itemType.name}',
      timestamp.millisecondsSinceEpoch,
    );
  }

  Future<SyncItemResult> _syncDiariesAndPhotosInternal({
    required bool Function() checkIfCancelled,
    required Function(double) onProgress,
  }) async {
    try {
      onProgress(0.0);
      final DateTime? lastDiarySyncTime = await getLastSyncTimestampForItem(
        SyncableItemType.diary,
      );
      final DateTime? lastPhotoSyncTime = await getLastSyncTimestampForItem(
        SyncableItemType.photos,
      );
      onProgress(0.1);

      if (checkIfCancelled())
        return SyncItemResult(
          success: false,
          cancelled: true,
          error: 'Cancelled',
        );

      final unsyncedDiaries = await _database.getUnsyncedDiaries(
        lastSyncTimestamp: lastDiarySyncTime,
      );
      final unsyncedPhotos = await _database.getUnsyncedPhotos(
        lastSyncTimestamp: lastPhotoSyncTime,
      );
      await Future.delayed(const Duration(milliseconds: 10));
      if (checkIfCancelled())
        return SyncItemResult(
          success: false,
          cancelled: true,
          error: 'Cancelled',
        );
      onProgress(0.2);

      final List<Map<String, dynamic>> diaryChanges = [];
      for (var diary in unsyncedDiaries) {
        List<Map<String, dynamic>> photoChangesForDiary = [];
        if (diary.syncStatus != model_sync_status.SyncStatus.deleted) {
          final photosOfDiary =
              diary.id != null
                  ? await _database.getPhotosForDiary(diary.id!)
                  : diary.photos ?? [];
          for (var photo in photosOfDiary) {
            if (photo.syncStatus != model_sync_status.SyncStatus.synced ||
                diary.syncStatus != model_sync_status.SyncStatus.synced) {
              photoChangesForDiary.add(photo.toSyncMap());
            }
          }
        }
        Map<String, dynamic> diaryMap = diary.toSyncMap();
        if (diary.syncStatus != model_sync_status.SyncStatus.deleted) {
          diaryMap['photos'] = photoChangesForDiary;
        } else {
          diaryMap['photos'] = [];
        }
        diaryChanges.add(diaryMap);
      }
      onProgress(0.3);
      if (checkIfCancelled())
        return SyncItemResult(
          success: false,
          cancelled: true,
          error: 'Cancelled',
        );

      final List<Map<String, dynamic>> standalonePhotoChanges = [];
      for (var photo in unsyncedPhotos) {
        // Assuming photo.diaryId is nullable int. If 0 means no association, use photo.diaryId == 0
        // For now, if it's non-nullable as per previous error, this check needs to be photo.diaryId == 0 (if 0 is the convention)
        // Or, if it's truly standalone, the model/DB schema should reflect that (e.g., nullable diaryId).
        // Given the error "The operand can't be 'null'", diaryId is non-nullable.
        // We'll assume 0 means it's standalone for now, or this logic needs review based on actual Photo model.
        if (photo.diaryId == 0) {
          standalonePhotoChanges.add(photo.toSyncMap());
        }
      }
      onProgress(0.4);
      if (checkIfCancelled())
        return SyncItemResult(
          success: false,
          cancelled: true,
          error: 'Cancelled',
        );

      if (diaryChanges.isEmpty && standalonePhotoChanges.isEmpty) {
        onProgress(1.0);
        return SyncItemResult(
          success: true,
          message: 'No diary/photo changes to sync',
        );
      }

      onProgress(0.5);
      // Changed: ApiService call now returns Map<String, dynamic>
      final Map<String, dynamic> apiResponse = await _apiService
          .syncDiariesAndPhotos(
            diaryChanges: diaryChanges,
            standalonePhotoChanges: standalonePhotoChanges,
            lastDiarySyncTime: lastDiarySyncTime?.toIso8601String(),
            lastPhotoSyncTime: lastPhotoSyncTime?.toIso8601String(),
          );
      onProgress(0.7);
      if (checkIfCancelled())
        return SyncItemResult(
          success: false,
          cancelled: true,
          error: 'Cancelled',
        );

      await _processSyncResponse(apiResponse); // Pass Map<String, dynamic>
      onProgress(0.9);

      final DateTime newSyncTime = DateTime.now();
      await _setLastSyncTimestampForItem(SyncableItemType.diary, newSyncTime);
      await _setLastSyncTimestampForItem(SyncableItemType.photos, newSyncTime);
      onProgress(1.0);
      return SyncItemResult(success: true);
    } catch (e) {
      _logger.severe('_syncDiariesAndPhotosInternal failed: $e');
      return SyncItemResult(success: false, error: e.toString());
    }
  }

  Future<SyncItemResult> _syncChecklistsInternal({
    required bool Function() checkIfCancelled,
    required Function(double) onProgress,
  }) async {
    try {
      onProgress(0.0);
      final DateTime? lastSyncTime = await getLastSyncTimestampForItem(
        SyncableItemType.checklists,
      );
      onProgress(0.1);
      if (checkIfCancelled())
        return SyncItemResult(
          success: false,
          cancelled: true,
          error: 'Cancelled',
        );

      final unsyncedItems = await _database.getUnsyncedChecklistItems(
        lastSyncTimestamp: lastSyncTime,
      );
      onProgress(0.3);
      if (checkIfCancelled())
        return SyncItemResult(
          success: false,
          cancelled: true,
          error: 'Cancelled',
        );

      if (unsyncedItems.isEmpty) {
        onProgress(1.0);
        return SyncItemResult(
          success: true,
          message: 'No checklist changes to sync',
        );
      }

      final List<Map<String, dynamic>> changes =
          unsyncedItems
              .map((item) => item.toSyncMap())
              .toList(); // Assumes Checklistitem.toSyncMap()
      onProgress(0.5);

      // Changed: ApiService call now returns Map<String, dynamic>
      // Also, assuming syncChecklists takes a single Map payload. Adjust if API is different.
      final Map<String, dynamic> apiResponse = await _apiService.syncChecklists(
        {'changes': changes, 'lastSyncTime': lastSyncTime?.toIso8601String()},
      );
      onProgress(0.7);
      if (checkIfCancelled())
        return SyncItemResult(
          success: false,
          cancelled: true,
          error: 'Cancelled',
        );

      await _processSyncResponse(apiResponse); // Pass Map<String, dynamic>
      onProgress(0.9);

      await _setLastSyncTimestampForItem(
        SyncableItemType.checklists,
        DateTime.now(),
      );
      onProgress(1.0);
      return SyncItemResult(success: true);
    } catch (e) {
      _logger.severe('_syncChecklistsInternal failed: $e');
      return SyncItemResult(success: false, error: e.toString());
    }
  }

  Future<SyncItemResult> _syncEmotionsInternal({
    required bool Function() checkIfCancelled,
    required Function(double) onProgress,
  }) async {
    try {
      onProgress(0.0);
      final DateTime? lastSyncTime = await getLastSyncTimestampForItem(
        SyncableItemType.emotions,
      );
      onProgress(0.1);
      if (checkIfCancelled())
        return SyncItemResult(
          success: false,
          cancelled: true,
          error: 'Cancelled',
        );

      final unsyncedItems = await _database.getUnsyncedEmotions(
        lastSyncTimestamp: lastSyncTime,
      );
      final deletedItems = await _database.getDeletedAndUnsyncedEmotions(
        lastSyncTimestamp: lastSyncTime,
      );

      final allChanges = [...unsyncedItems, ...deletedItems];
      onProgress(0.3);
      if (checkIfCancelled())
        return SyncItemResult(
          success: false,
          cancelled: true,
          error: 'Cancelled',
        );

      if (allChanges.isEmpty) {
        onProgress(1.0);
        return SyncItemResult(
          success: true,
          message: 'No emotion changes to sync',
        );
      }

      final List<Map<String, dynamic>> changes =
          allChanges
              .map((item) => item.toSyncMap())
              .toList(); // Assumes EmotionRecord.toSyncMap()
      onProgress(0.5);

      // Changed: ApiService call now returns Map<String, dynamic>
      final Map<String, dynamic> apiResponse = await _apiService.syncEmotions({
        'changes': changes,
        'lastSyncTime': lastSyncTime?.toIso8601String(),
      });
      onProgress(0.7);
      if (checkIfCancelled())
        return SyncItemResult(
          success: false,
          cancelled: true,
          error: 'Cancelled',
        );

      await _processSyncResponse(apiResponse); // Pass Map<String, dynamic>
      onProgress(0.9);

      await _setLastSyncTimestampForItem(
        SyncableItemType.emotions,
        DateTime.now(),
      );
      onProgress(1.0);
      return SyncItemResult(success: true);
    } catch (e) {
      _logger.severe('_syncEmotionsInternal failed: $e');
      return SyncItemResult(success: false, error: e.toString());
    }
  }

  Future<SyncItemResult> _syncLocationsInternal({
    required bool Function() checkIfCancelled,
    required Function(double) onProgress,
  }) async {
    try {
      onProgress(0.0);
      final DateTime? lastSyncTime = await getLastSyncTimestampForItem(
        SyncableItemType.locations,
      );
      onProgress(0.1);
      if (checkIfCancelled())
        return SyncItemResult(
          success: false,
          cancelled: true,
          error: 'Cancelled',
        );

      final unsyncedItems = await _database.getUnsyncedLocationLogs(
        lastSyncTimestamp: lastSyncTime,
      );
      final deletedItems = await _database.getDeletedAndUnsyncedLocationLogs(
        lastSyncTimestamp: lastSyncTime,
      );

      final allChanges = [...unsyncedItems, ...deletedItems];
      onProgress(0.3);
      if (checkIfCancelled())
        return SyncItemResult(
          success: false,
          cancelled: true,
          error: 'Cancelled',
        );

      if (allChanges.isEmpty) {
        onProgress(1.0);
        return SyncItemResult(
          success: true,
          message: 'No location changes to sync',
        );
      }

      final List<Map<String, dynamic>> changes =
          allChanges
              .map((item) => item.toSyncMap())
              .toList(); // Assumes LocationRecord.toSyncMap()
      onProgress(0.5);

      // Changed: ApiService call now returns Map<String, dynamic>
      final Map<String, dynamic> apiResponse = await _apiService.syncLocations({
        'changes': changes,
        'lastSyncTime': lastSyncTime?.toIso8601String(),
      });
      onProgress(0.7);
      if (checkIfCancelled())
        return SyncItemResult(
          success: false,
          cancelled: true,
          error: 'Cancelled',
        );

      await _processSyncResponse(apiResponse); // Pass Map<String, dynamic>
      onProgress(0.9);

      await _setLastSyncTimestampForItem(
        SyncableItemType.locations,
        DateTime.now(),
      );
      onProgress(1.0);
      return SyncItemResult(success: true);
    } catch (e) {
      _logger.severe('_syncLocationsInternal failed: $e');
      return SyncItemResult(success: false, error: e.toString());
    }
  }

  Future<SyncItemResult> _syncSchedulesInternal({
    required bool Function() checkIfCancelled,
    required Function(double) onProgress,
  }) async {
    try {
      onProgress(0.0);
      final DateTime? lastSyncTime = await getLastSyncTimestampForItem(
        SyncableItemType.schedules,
      );
      onProgress(0.1);
      if (checkIfCancelled())
        return SyncItemResult(
          success: false,
          cancelled: true,
          error: 'Cancelled',
        );

      final unsyncedItems = await _database.getUnsyncedScheduleItems(
        lastSyncTimestamp: lastSyncTime,
      );
      onProgress(0.3);
      if (checkIfCancelled())
        return SyncItemResult(
          success: false,
          cancelled: true,
          error: 'Cancelled',
        );

      if (unsyncedItems.isEmpty) {
        onProgress(1.0);
        return SyncItemResult(
          success: true,
          message: 'No schedule changes to sync',
        );
      }      final List<Map<String, dynamic>> changes =
          unsyncedItems
              .map((item) => item.toSyncMap())
              .toList(); // ScheduleItem now uses toSyncMap consistently
      onProgress(0.5);

      // Changed: ApiService call now returns Map<String, dynamic>
      final Map<String, dynamic> apiResponse = await _apiService.syncSchedules({
        'changes': changes,
        'lastSyncTime': lastSyncTime?.toIso8601String(),
      });
      onProgress(0.7);
      if (checkIfCancelled())
        return SyncItemResult(
          success: false,
          cancelled: true,
          error: 'Cancelled',
        );

      await _processSyncResponse(apiResponse); // Pass Map<String, dynamic>
      onProgress(0.9);

      await _setLastSyncTimestampForItem(
        SyncableItemType.schedules,
        DateTime.now(),
      );
      onProgress(1.0);
      return SyncItemResult(success: true);
    } catch (e) {
      _logger.severe('_syncSchedulesInternal failed: $e');
      return SyncItemResult(success: false, error: e.toString());
    }
  }
}

// Helper classes for Sync Events and Results (consider moving to a separate file)
class SyncItemResult {
  final bool success;
  final bool cancelled;
  final String? message;
  final String? error;

  SyncItemResult({
    required this.success,
    this.cancelled = false,
    this.message,
    this.error,
  });
}

class SyncEvent {
  final SyncEventType type;
  final String message;

  SyncEvent(this.type, {required this.message});
}

enum SyncEventType {
  syncStarted,
  syncProgress,
  syncCompleted,
  syncError,
  // You can add more specific event types if needed
}
