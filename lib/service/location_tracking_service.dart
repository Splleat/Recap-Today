import 'package:recap_today/dao/location_dao.dart';

class LocationService {
  final LocationDao _dao;
  LocationService(this._dao);

  Future<void> addLocationLog(String userId, double lat, double lng) async {
    await _dao.insert({
      'userId': userId,
      'latitude': lat,
      'longitude': lng,
      'timestamp': DateTime.now().toIso8601String(),
      'isSynced': 0,
    });
  }

  Future<List<Map<String, dynamic>>> getAllLocationDataForUser(String userId) async {
    return await _dao.getByUser(userId);
  }

  Future<void> processPendingBackupQueue() async {
    final unsynced = await _dao.getUnsyncedLogs();
    // TODO: 서버 백업 로직
    final ids = unsynced.map((e) => e['id'] as int).toList();
    await _dao.markAsSynced(ids);
  }

  Future<bool> hasLocalUserData() async {
    final localLogs = await _dao.getByUser('local_user');
    return localLogs.isNotEmpty;
  }

  Future<bool> migrateLocalUserDataToRealUser(String realUserId) async {
    final localLogs = await _dao.getByUser('local_user');
    if (localLogs.isEmpty) return false;

    for (final log in localLogs) {
      log['userId'] = realUserId;
      log.remove('id');
      await _dao.insert(log);
    }
    await _dao.deleteAllByUser('local_user');
    return true;
  }
}