import '../model/freezed/location_model.dart';
import '../data/abstract_database.dart';
import 'package:uuid/uuid.dart';
import 'dart:developer' as developer;

class LocationService {
  final AbstractDatabase _database;
  final Uuid _uuid = const Uuid();

  LocationService(this._database);

  /// 로컬 데이터베이스에서만 위치 데이터 조회 (순수 로컬)
  Future<DailyLocationData> getLocalLocationDataForDate(
    String userId,
    String date,
  ) async {
    try {
      final localData = await _database.getLocationLogsForUserAndDate(
        userId,
        date,
      );
      final locations =
          localData.map((map) => LocationModelX.fromMap(map)).toList();

      return DailyLocationData(userId: userId, date: date, locations: locations);
    } catch (e) {
      developer.log('로컬 위치 데이터 조회 실패: $e', name: 'LocationService');
      return DailyLocationData(userId: userId,date: date, locations: []);
    }
  }

  /// 특정 날짜의 위치 데이터 조회 (로컬 전용)
  Future<DailyLocationData> fetchLocationDataForDate(
    String userId,
    String date,
  ) async {
    final localData = await getLocalLocationDataForDate(userId, date);
    return localData;
  }

  /// 위치 데이터 로컬 저장 전용
  Future<void> saveLocationDataLocally(LocationModel location) async {
    try {
      await _database.insertLocationLog(location.toMap());
      developer.log('위치 데이터 로컬 저장 완료: ${location.id}', name: 'LocationService');
    } catch (e) {
      developer.log('로컬 위치 데이터 저장 실패: $e', name: 'LocationService');
      throw Exception('위치 데이터를 로컬에 저장하지 못했습니다: $e');
    }
  }

  /// 새 위치 데이터 생성 및 로컬 저장
  Future<void> addLocationLog(
    String userId,
    double latitude,
    double longitude,
  ) async {
    final location = LocationModel(
      id: _uuid.v4(),
      userId: userId,
      latitude: latitude,
      longitude: longitude,
      timestamp: DateTime.now(),
    );

    await saveLocationDataLocally(location);
  }

  /// 특정 사용자의 모든 위치 데이터 조회 (로컬 전용)
  Future<List<LocationModel>> getAllLocationDataForUser(String userId) async {
    try {
      final localData = await _database.getLocationLogsForUser(userId);
      return localData.map((map) => LocationModelX.fromMap(map)).toList();
    } catch (e) {
      developer.log('사용자 위치 데이터 조회 실패: $e', name: 'LocationService');
      return [];
    }
  }

  /// 특정 날짜 범위의 위치 데이터 조회 (로컬 전용)
  Future<List<LocationModel>> getLocationDataForDateRange(
    String userId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final localData = await _database.getLocationLogsForUserInRange(
        userId,
        startDate,
        endDate,
      );
      return localData.map((map) => LocationModelX.fromMap(map)).toList();
    } catch (e) {
      developer.log('날짜 범위 위치 데이터 조회 실패: $e', name: 'LocationService');
      return [];
    }
  }

  /// 위치 데이터 정리 (특정 기간)
  Future<void> cleanupLocationData(
    String userId,
    DateTime start,
    DateTime end,
  ) async {
    try {
      await _database.deleteLocationLogsInRange(userId, start, end);
      developer.log(
        '위치 데이터 정리 완료: $userId ($start ~ $end)',
        name: 'LocationService',
      );
    } catch (e) {
      developer.log('위치 데이터 정리 실패: $e', name: 'LocationService');
    }
  }
}