import 'package:recap_today/model/location_model.dart';

abstract class AbstractLocationRepository {
  Future<void> saveLocationLog(LocationRecord log);
  Future<LocationRecord?> getLocationLogById(String id);
  Future<List<LocationRecord>> getLocationLogsForDate(DateTime date);
  Future<List<LocationRecord>> getUnsyncedLocationLogs();
  Future<void> markLocationLogsAsSynced(List<String> ids, DateTime syncTime);
  Future<void> deleteLocationLog(String id); // Soft delete
  Future<void> hardDeleteLocationLog(String id); // Hard delete

  // Methods needed by LocationService
  Future<List<LocationRecord>> getLocationRecordsForUserAndDate(
    String userId,
    DateTime date,
  );
  Future<List<LocationRecord>> getAllLocationRecordsForUser(String userId);
  Future<void> insertLocationRecord(LocationRecord record);
  Future<List<LocationRecord>> getPendingSyncLocationRecords();
  Future<List<LocationRecord>> getLocationRecordsForUserInRange(
    String userId,
    DateTime startDate,
    DateTime endDate,
  );
  Future<void> deleteLocationRecordsInRange(
    String userId,
    DateTime startDate,
    DateTime endDate,
  );
  Future<void> deleteAllLocationRecordsForUser(String userId);
}
