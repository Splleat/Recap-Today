import '../model/location_model.dart';
import '../data/abstract_database.dart';
import 'dio_client.dart';
import 'package:uuid/uuid.dart';
import 'dart:developer' as developer;

class LocationService {
  final AbstractDatabase _database;
  final Uuid _uuid = const Uuid();
  bool _isOnline = true;

  LocationService(this._database);

  /// 네트워크 상태 확인
  Future<bool> _checkNetworkConnection() async {
    try {
      final response = await DioClient.dio.get('/health');
      _isOnline = response.statusCode == 200;
      return _isOnline;
    } catch (e) {
      _isOnline = false;
      return false;
    }
  }

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
          localData.map((map) => LocationModel.fromMap(map)).toList();

      return DailyLocationData(date: date, locations: locations);
    } catch (e) {
      developer.log('로컬 위치 데이터 조회 실패: $e', name: 'LocationService');
      return DailyLocationData(date: date, locations: []);
    }
  }

  /// 특정 날짜의 위치 데이터 조회 (로컬 우선, 백그라운드 동기화)
  Future<DailyLocationData> fetchLocationDataForDate(
    String userId,
    String date,
  ) async {
    // 먼저 로컬 데이터 반환 (즉시 응답)
    final localData = await getLocalLocationDataForDate(userId, date);

    // 백그라운드에서 서버 동기화 시도 (사용자 경험에 영향 없음)
    _syncLocationDataInBackground(userId, date);

    return localData;
  }

  /// 백그라운드에서 서버와 동기화
  Future<void> _syncLocationDataInBackground(String userId, String date) async {
    try {
      if (!await _checkNetworkConnection()) {
        developer.log('네트워크 연결 없음 - 동기화 스킵', name: 'LocationService');
        return;
      }

      // 서버에서 최신 데이터 가져와서 로컬과 비교/병합
      final response = await DioClient.dio.get(
        '/location/sync/$userId',
        queryParameters: {
          'since': '${date}T00:00:00Z', // 해당 날짜 이후 데이터만 조회
          'limit': '200',
        },
      );

      final serverData = response.data as List;
      final serverLocations =
          serverData.map((item) => LocationModel.fromJson(item)).toList();

      // 로컬에 없는 서버 데이터만 추가
      final localData = await _database.getLocationLogsForUserAndDate(
        userId,
        date,
      );
      final localIds = localData.map((m) => m['id']).toSet();

      for (final location in serverLocations) {
        if (!localIds.contains(location.id)) {
          await _database.insertLocationLog(location.toMap());
          developer.log(
            '서버에서 위치 데이터 동기화: ${location.id}',
            name: 'LocationService',
          );
        }
      }
    } catch (e) {
      developer.log('백그라운드 동기화 실패: $e', name: 'LocationService');
    }
  }

  /// 위치 데이터 로컬 저장 (즉시) + 서버 동기화 (백그라운드)
  Future<void> saveLocationDataLocally(LocationModel location) async {
    try {
      // 로컬 데이터베이스에 즉시 저장
      await _database.insertLocationLog(location.toMap());
      developer.log('위치 데이터 로컬 저장 완료: ${location.id}', name: 'LocationService');

      // 백그라운드에서 서버 동기화 시도
      _syncLocationToServerInBackground(location);
    } catch (e) {
      developer.log('로컬 위치 데이터 저장 실패: $e', name: 'LocationService');
      throw Exception('위치 데이터를 로컬에 저장하지 못했습니다: $e');
    }
  }

  /// 백그라운드에서 서버로 위치 데이터 동기화
  Future<void> _syncLocationToServerInBackground(LocationModel location) async {
    try {
      if (!await _checkNetworkConnection()) {
        // 네트워크 연결이 없으면 동기화 대기열에 추가
        await _addToSyncQueue(location);
        return;
      }

      await DioClient.dio.post(
        '/location/sync', // 동기화 전용 엔드포인트 사용
        data: {
          'userId': location.userId,
          'latitude': location.latitude,
          'longitude': location.longitude,
          'timestamp': location.timestamp.toIso8601String(),
        },
      );

      // 동기화 성공 시 대기열에서 제거
      await _removeFromSyncQueue(location.id);
      developer.log('서버 동기화 완료: ${location.id}', name: 'LocationService');
    } catch (e) {
      // 동기화 실패 시 대기열에 추가
      await _addToSyncQueue(location);
      developer.log(
        '서버 동기화 실패, 대기열 추가: ${location.id} - $e',
        name: 'LocationService',
      );
    }
  }

  /// 동기화 대기열에 추가
  Future<void> _addToSyncQueue(LocationModel location) async {
    try {
      await _database.insertPendingSyncLocation(location.toMap());
    } catch (e) {
      developer.log('동기화 대기열 추가 실패: $e', name: 'LocationService');
    }
  }

  /// 동기화 대기열에서 제거
  Future<void> _removeFromSyncQueue(String locationId) async {
    try {
      await _database.removePendingSyncLocation(locationId);
    } catch (e) {
      developer.log('동기화 대기열 제거 실패: $e', name: 'LocationService');
    }
  }

  /// 대기 중인 동기화 데이터 처리 (배치 처리로 최적화)
  Future<void> processPendingSyncQueue() async {
    try {
      if (!await _checkNetworkConnection()) {
        developer.log('네트워크 연결 없음 - 대기열 처리 스킵', name: 'LocationService');
        return;
      }

      final pendingData = await _database.getPendingSyncLocations();
      if (pendingData.isEmpty) {
        developer.log('처리할 대기열 데이터 없음', name: 'LocationService');
        return;
      }

      developer.log(
        '처리할 대기열 데이터: ${pendingData.length}개',
        name: 'LocationService',
      );

      // 작은 배치로 처리 (한번에 최대 10개)
      const batchSize = 10;
      for (int i = 0; i < pendingData.length; i += batchSize) {
        final batch = pendingData.skip(i).take(batchSize).toList();
        await _processBatch(batch);
      }
    } catch (e) {
      developer.log('대기열 처리 실패: $e', name: 'LocationService');
    }
  }

  /// 배치 단위로 동기화 처리
  Future<void> _processBatch(List<Map<String, dynamic>> batch) async {
    try {
      // 배치 API 사용 시도
      try {
        final batchData =
            batch
                .map(
                  (data) => {
                    'userId': data['userId'],
                    'latitude': data['latitude'],
                    'longitude': data['longitude'],
                    'timestamp': data['timestamp'],
                  },
                )
                .toList();

        await DioClient.dio.post(
          '/location/sync/batch',
          data: {'locations': batchData},
        );

        // 배치 동기화 성공 시 모든 아이템을 대기열에서 제거
        for (final data in batch) {
          await _removeFromSyncQueue(data['id']);
        }

        developer.log('배치 동기화 완료: ${batch.length}개', name: 'LocationService');
        return;
      } catch (batchError) {
        developer.log(
          '배치 동기화 실패, 개별 처리로 전환: $batchError',
          name: 'LocationService',
        );
      }

      // 배치 실패 시 개별 처리
      for (final data in batch) {
        final location = LocationModel.fromMap(data);
        try {
          await DioClient.dio.post(
            '/location/sync',
            data: {
              'userId': location.userId,
              'latitude': location.latitude,
              'longitude': location.longitude,
              'timestamp': location.timestamp.toIso8601String(),
            },
          );

          await _removeFromSyncQueue(location.id);
          developer.log('개별 동기화 완료: ${location.id}', name: 'LocationService');
        } catch (e) {
          developer.log(
            '개별 동기화 실패: ${location.id} - $e',
            name: 'LocationService',
          );
        }
      }
    } catch (e) {
      developer.log('배치 처리 실패: $e', name: 'LocationService');
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
      return localData.map((map) => LocationModel.fromMap(map)).toList();
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
      return localData.map((map) => LocationModel.fromMap(map)).toList();
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

  /// 네트워크 상태 확인
  bool get isOnline => _isOnline;

  /// 수동으로 전체 동기화 실행
  Future<void> forceSyncAll() async {
    developer.log('전체 동기화 시작', name: 'LocationService');
    await processPendingSyncQueue();
    developer.log('전체 동기화 완료', name: 'LocationService');
  }

  /// 로컬 사용자 데이터를 실제 사용자 계정으로 마이그레이션
  Future<bool> migrateLocalUserDataToRealUser(String realUserId) async {
    try {
      const String localUserId = 'local_user';

      // 로컬 사용자의 모든 위치 데이터 조회
      final localData = await _database.getAllLocationLogsForUser(localUserId);

      if (localData.isEmpty) {
        developer.log('마이그레이션할 로컬 데이터가 없습니다.', name: 'LocationService');
        return true; // 데이터가 없어도 성공으로 처리
      }

      developer.log(
        '${localData.length}개의 로컬 위치 데이터를 $realUserId로 마이그레이션 시작',
        name: 'LocationService',
      );

      // 각 로컬 데이터를 실제 사용자 ID로 변경하여 저장
      int migratedCount = 0;
      for (final locationMap in localData) {
        final location = LocationModel.fromMap(locationMap);

        // 새로운 사용자 ID로 위치 데이터 저장
        final newLocation = LocationModel(
          id: _uuid.v4(), // 새로운 ID 생성
          userId: realUserId, // 실제 사용자 ID로 변경
          latitude: location.latitude,
          longitude: location.longitude,
          timestamp: location.timestamp,
        );

        await _database.insertLocationLog(newLocation.toMap());
        migratedCount++;
      }

      // 로컬 사용자의 원본 데이터 삭제
      await _database.deleteAllLocationLogsForUser(localUserId);

      developer.log(
        '$migratedCount개의 위치 데이터 마이그레이션 완료',
        name: 'LocationService',
      );

      // 마이그레이션된 데이터를 서버에 동기화
      await processPendingSyncQueue();

      return true;
    } catch (e) {
      developer.log('데이터 마이그레이션 실패: $e', name: 'LocationService');
      return false;
    }
  }

  /// 로컬 사용자 데이터 존재 여부 확인
  Future<bool> hasLocalUserData() async {
    try {
      const String localUserId = 'local_user';
      final localData = await _database.getAllLocationLogsForUser(localUserId);
      return localData.isNotEmpty;
    } catch (e) {
      developer.log('로컬 데이터 확인 실패: $e', name: 'LocationService');
      return false;
    }
  }
}
