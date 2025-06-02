import '../model/location/location_model.dart';
import 'package:uuid/uuid.dart';
import 'dart:developer' as developer;
import '../dao/location_dao.dart';

class LocationService {
  final LocationDao _locationDao;
  final Uuid _uuid = const Uuid();

  LocationService(this._locationDao);

  Future<List<LocationModel>> getLocationDataForDate(String userId, String date) async {
    try {
      final data = await _locationDao.getByUserAndDate(userId, date);
      return data.map((map) => LocationModelExt.fromMap(map)).toList();
    } catch (e) {
      developer.log('로컬 위치 데이터 조회 실패: $e', name: 'LocationService');
      return [];
    }
  }

  Future<List<LocationModel>> getLocationDataForRange(String userId, DateTime start, DateTime end) async {
    try {
      final data = await _locationDao.getByUserInRange(userId, start, end);
      return data.map((map) => LocationModelExt.fromMap(map)).toList();
    } catch (e) {
      developer.log('날짜 범위 위치 데이터 조회 실패: $e', name: 'LocationService');
      return [];
    }
  }

  Future<void> saveLocation(LocationModel location) async {
    try {
      await _locationDao.insert(location.toMap());
      developer.log('위치 저장 완료: ${location.id}', name: 'LocationService');
    } catch (e) {
      developer.log('위치 저장 실패: $e', name: 'LocationService');
      throw Exception('위치 저장 실패: $e');
    }
  }

  Future<void> addLocation(String userId, double lat, double lng) async {
    final location = LocationModel(
      id: _uuid.v4(),
      userId: userId,
      latitude: lat,
      longitude: lng,
      timestamp: DateTime.now(),
    );
    await saveLocation(location);
  }

  Future<void> deleteLocationsInRange(String userId, DateTime start, DateTime end) async {
    try {
      await _locationDao.deleteInRange(userId, start, end);
      developer.log('위치 삭제 완료: $userId ($start ~ $end)', name: 'LocationService');
    } catch (e) {
      developer.log('위치 삭제 실패: $e', name: 'LocationService');
    }
  }

  Future<List<LocationModel>> getAllLocations(String userId) async {
    try {
      final data = await _locationDao.getByUser(userId);
      return data.map((map) => LocationModelExt.fromMap(map)).toList();
    } catch (e) {
      developer.log('위치 전체 조회 실패: $e', name: 'LocationService');
      return [];
    }
  }
}