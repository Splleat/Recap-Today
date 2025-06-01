import 'package:recap_today/data/abstract_database.dart';
import 'package:recap_today/model/location_model.dart';
import 'package:recap_today/repository/abstract_location_repository.dart';
import 'package:uuid/uuid.dart';

class LocationRepository implements AbstractLocationRepository {
  final AbstractDatabase _db;
  final Uuid _uuid = const Uuid();

  LocationRepository(this._db);

  @override
  Future<void> saveLocationLog(LocationRecord log) async {
    LocationRecord recordToSave = log;
    if (recordToSave.id == null) {
      // Now correctly checks for null
      recordToSave = recordToSave.copyWith(id: _uuid.v4());
    }
    await _db.saveLocationLog(recordToSave);
  }

  @override
  Future<LocationRecord?> getLocationLogById(String id) async {
    return _db.getLocationLogById(id);
  }

  @override
  Future<List<LocationRecord>> getLocationLogsForDate(DateTime date) async {
    // This method in AbstractLocationRepository might be too generic if userId is needed.
    // For now, it calls the AbstractDatabase method which also doesn't take userId.
    // This might need to be re-evaluated based on usage.
    return _db.getLocationLogsForDate(date);
  }

  @override
  Future<List<LocationRecord>> getUnsyncedLocationLogs() async {
    return _db.getUnsyncedLocationLogs();
  }
  @override
  Future<void> markLocationLogsAsSynced(
    List<String> ids,
    DateTime syncTime,
  ) async {
    // await _db.markLocationLogsAsSynced(ids, syncTime);
    await _db.markLocationLogsAsSynced(
      ids,
      syncTime, // Pass the syncTime parameter instead of hardcoded string
    ); // Fixed to use the correct parameter type
  }

  @override
  Future<void> deleteLocationLog(String id) async {
    // Soft delete
    await _db.deleteLocationLog(id);
  }

  @override
  Future<void> hardDeleteLocationLog(String id) async {
    // Hard delete
    await _db.hardDeleteLocationLog(id);
  }

  // Pending Sync Queue Methods - REMOVED as pending_sync_locations table is dropped
  /* 
  @override
  Future<void> addLocationToSyncQueue({
    required String id,
    required String userId,
    required double latitude,
    required double longitude,
    required DateTime timestamp,
  }) async {
    await _db.addLocationToSyncQueue(
      id: id,
      userId: userId,
      latitude: latitude,
      longitude: longitude,
      timestamp: timestamp,
    );
  }

  @override
  Future<void> removeLocationFromSyncQueue(String id) async {
    await _db.removeLocationFromSyncQueue(id);
  }

  @override
  Future<List<Map<String, dynamic>>> getAllLocationSyncQueueItems() async {
    return _db.getAllLocationSyncQueueItems();
  }

  @override
  Future<void> clearLocationSyncQueue() async {
    await _db.clearLocationSyncQueue();
  }
  */

  // Implementations for methods needed by LocationService
  @override
  Future<List<LocationRecord>> getLocationRecordsForUserAndDate(
    String userId,
    DateTime date,
  ) async {
    return _db.getLocationLogsForUserAndDate(userId, date);
  }

  @override
  Future<List<LocationRecord>> getAllLocationRecordsForUser(
    String userId,
  ) async {
    return _db.getAllLocationLogsForUser(userId);
  }

  @override
  Future<void> insertLocationRecord(LocationRecord record) async {
    LocationRecord recordToSave = record;
    if (recordToSave.id == null) {
      // Now correctly checks for null
      recordToSave = recordToSave.copyWith(id: _uuid.v4());
    }
    await _db.saveLocationLog(
      recordToSave,
    ); // saveLocationLog handles insert/update
  }

  /*
  @override
  Future<void> removePendingSyncLocationRecord(String id) async {
    // This is effectively the same as removing from the specific sync queue table.
    // await _db.removeLocationFromSyncQueue(id); // REMOVED
  }
  */

  @override
  Future<List<LocationRecord>> getPendingSyncLocationRecords() async {
    // This method needs to fetch items from the pending_sync_locations table
    // and then retrieve the full LocationRecord details from the location_logs table.
    // This is a more complex query or a two-step process.
    // For now, returning unsynced logs as a stand-in, as per previous logic.
    // This should be refined to accurately reflect items in the dedicated pending sync queue.
    // A more accurate implementation would be:
    // 1. Get all items from _db.getAllLocationSyncQueueItems().
    // 2. For each item, get the full LocationRecord using _db.getLocationLogById(item['id']).
    // This can be inefficient if the queue is large.
    // A direct DAO method to join and fetch these would be better.
    // For now, using getUnsyncedLocationLogs() which fetches based on lastSynced == null.
    // This might be acceptable if items added to sync queue are always unsynced.
    return _db.getUnsyncedLocationLogs();
  }

  @override
  Future<List<LocationRecord>> getLocationRecordsForUserInRange(
    String userId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    return _db.getLocationLogsForUserInRange(userId, startDate, endDate);
  }

  @override
  Future<void> deleteLocationRecordsInRange(
    String userId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    // This should be a soft delete, handled by the database layer.
    await _db.deleteLocationLogsInRange(userId, startDate, endDate);
  }

  @override
  Future<void> deleteAllLocationRecordsForUser(String userId) async {
    // This should be a soft delete, handled by the database layer.
    await _db.deleteAllLocationLogsForUser(userId);
  }
}
