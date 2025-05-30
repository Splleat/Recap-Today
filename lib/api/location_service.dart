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

  /// 특정 날짜의 위치 데이터 조회 (로컬 전용)
  Future<DailyLocationData> fetchLocationDataForDate(
    String userId,
    String date,
  ) async {
    // 로컬 데이터만 반환 (자동 동기화 제거)
    final localData = await getLocalLocationDataForDate(userId, date);
    return localData;
  }

  /// 사용자 요청에 의한 수동 서버 백업
  Future<bool> backupLocationDataToServer(String userId) async {
    try {
      developer.log('사용자 요청으로 위치 데이터 백업 시작: $userId', name: 'LocationService');

      if (!await _checkNetworkConnection()) {
        developer.log('네트워크 연결 없음 - 백업 실패', name: 'LocationService');
        return false;
      }

      // 해당 사용자의 모든 로컬 위치 데이터 조회
      final localData = await _database.getAllLocationLogsForUser(userId);

      if (localData.isEmpty) {
        developer.log('백업할 위치 데이터가 없습니다.', name: 'LocationService');
        return true;
      }

      // 서버에서 기존 데이터 확인하여 중복 제거
      final response = await DioClient.dio.get('/location/sync/$userId');
      final serverData = response.data as List;
      final serverIds = serverData.map((item) => item['id']).toSet();

      // 서버에 없는 로컬 데이터만 필터링
      final newData =
          localData.where((data) => !serverIds.contains(data['id'])).toList();

      if (newData.isEmpty) {
        developer.log('백업할 새로운 데이터가 없습니다.', name: 'LocationService');
        return true;
      }

      developer.log(
        '${newData.length}개의 위치 데이터를 서버에 백업합니다.',
        name: 'LocationService',
      );

      // 배치로 서버에 백업
      const batchSize = 20;
      int successCount = 0;

      for (int i = 0; i < newData.length; i += batchSize) {
        final batch = newData.skip(i).take(batchSize).toList();

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

          successCount += batch.length;
          developer.log('배치 백업 완료: ${batch.length}개', name: 'LocationService');
        } catch (batchError) {
          developer.log(
            '배치 백업 실패, 개별 처리: $batchError',
            name: 'LocationService',
          );

          // 배치 실패 시 개별 처리
          for (final data in batch) {
            try {
              await DioClient.dio.post(
                '/location/sync',
                data: {
                  'userId': data['userId'],
                  'latitude': data['latitude'],
                  'longitude': data['longitude'],
                  'timestamp': data['timestamp'],
                },
              );
              successCount++;
            } catch (e) {
              developer.log(
                '개별 백업 실패: ${data['id']} - $e',
                name: 'LocationService',
              );
            }
          }
        }
      }

      developer.log(
        '위치 데이터 백업 완료: $successCount/${newData.length}개',
        name: 'LocationService',
      );
      return successCount == newData.length;
    } catch (e) {
      developer.log('위치 데이터 백업 실패: $e', name: 'LocationService');
      return false;
    }
  }

  /// 서버에서 위치 데이터 다운로드 (수동 동기화)
  Future<bool> downloadLocationDataFromServer(String userId) async {
    try {
      developer.log('서버에서 위치 데이터 다운로드 시작: $userId', name: 'LocationService');

      if (!await _checkNetworkConnection()) {
        developer.log('네트워크 연결 없음 - 다운로드 실패', name: 'LocationService');
        return false;
      }

      final response = await DioClient.dio.get('/location/sync/$userId');
      final serverData = response.data as List;
      final serverLocations =
          serverData.map((item) => LocationModel.fromJson(item)).toList();

      if (serverLocations.isEmpty) {
        developer.log('다운로드할 서버 데이터가 없습니다.', name: 'LocationService');
        return true;
      }

      // 로컬에 없는 서버 데이터만 추가
      final localData = await _database.getAllLocationLogsForUser(userId);
      final localIds = localData.map((m) => m['id']).toSet();

      int downloadCount = 0;
      for (final location in serverLocations) {
        if (!localIds.contains(location.id)) {
          await _database.insertLocationLog(location.toMap());
          downloadCount++;
        }
      }

      developer.log('위치 데이터 다운로드 완료: $downloadCount개', name: 'LocationService');
      return true;
    } catch (e) {
      developer.log('위치 데이터 다운로드 실패: $e', name: 'LocationService');
      return false;
    }
  }

  /// 위치 데이터 로컬 저장 전용 (자동 동기화 제거)
  Future<void> saveLocationDataLocally(LocationModel location) async {
    try {
      // 로컬 데이터베이스에만 저장 (서버 동기화 제거)
      await _database.insertLocationLog(location.toMap());
      developer.log('위치 데이터 로컬 저장 완료: ${location.id}', name: 'LocationService');
    } catch (e) {
      developer.log('로컬 위치 데이터 저장 실패: $e', name: 'LocationService');
      throw Exception('위치 데이터를 로컬에 저장하지 못했습니다: $e');
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

  /// 사용자 요청에 의한 수동 백업 실행 (대기열 데이터 처리)
  Future<bool> processPendingBackupQueue() async {
    try {
      if (!await _checkNetworkConnection()) {
        developer.log('네트워크 연결 없음 - 백업 대기열 처리 실패', name: 'LocationService');
        return false;
      }

      final pendingData = await _database.getPendingSyncLocations();
      if (pendingData.isEmpty) {
        developer.log('처리할 백업 대기열 데이터 없음', name: 'LocationService');
        return true;
      }

      developer.log(
        '처리할 백업 대기열 데이터: ${pendingData.length}개',
        name: 'LocationService',
      );

      // 작은 배치로 처리 (한번에 최대 10개)
      const batchSize = 10;
      int totalSuccess = 0;

      for (int i = 0; i < pendingData.length; i += batchSize) {
        final batch = pendingData.skip(i).take(batchSize).toList();
        final successCount = await _processBatch(batch);
        totalSuccess += successCount;
      }

      final isAllSuccess = totalSuccess == pendingData.length;
      developer.log(
        '백업 대기열 처리 완료: $totalSuccess/${pendingData.length}개 성공',
        name: 'LocationService',
      );
      return isAllSuccess;
    } catch (e) {
      developer.log('백업 대기열 처리 실패: $e', name: 'LocationService');
      return false;
    }
  }

  /// 배치 단위로 백업 처리
  Future<int> _processBatch(List<Map<String, dynamic>> batch) async {
    int successCount = 0;

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

        successCount = batch.length;
        developer.log('배치 백업 완료: ${batch.length}개', name: 'LocationService');
        return successCount;
      } catch (batchError) {
        developer.log(
          '배치 백업 실패, 개별 처리로 전환: $batchError',
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
          successCount++;
          developer.log('개별 백업 완료: ${location.id}', name: 'LocationService');
        } catch (e) {
          developer.log(
            '개별 백업 실패: ${location.id} - $e',
            name: 'LocationService',
          );
        }
      }
    } catch (e) {
      developer.log('배치 처리 실패: $e', name: 'LocationService');
    }

    return successCount;
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

  /// 수동으로 전체 백업 실행
  Future<bool> forceSyncAll() async {
    developer.log('전체 백업 시작', name: 'LocationService');
    final result = await processPendingBackupQueue();
    developer.log('전체 백업 완료', name: 'LocationService');
    return result;
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
      ); // 마이그레이션된 데이터를 서버에 백업 (사용자 요청 시에만)
      // await processPendingBackupQueue(); // 필요 시 수동으로 백업 호출

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

  /// 백업 대기 중인 데이터 개수 확인
  Future<int> getPendingBackupCount() async {
    try {
      final pendingData = await _database.getPendingSyncLocations();
      return pendingData.length;
    } catch (e) {
      developer.log('백업 대기 개수 확인 실패: $e', name: 'LocationService');
      return 0;
    }
  }

  /// 백업이 필요한 로컬 전용 데이터 개수 확인
  Future<int> getLocalOnlyDataCount(String userId) async {
    try {
      if (!await _checkNetworkConnection()) {
        developer.log(
          '네트워크 연결 없음 - 로컬 전용 데이터 개수 확인 불가',
          name: 'LocationService',
        );
        return -1; // 네트워크 오류 표시
      }

      // 로컬 데이터 조회
      final localData = await _database.getAllLocationLogsForUser(userId);

      // 서버 데이터 조회
      final response = await DioClient.dio.get('/location/sync/$userId');
      final serverData = response.data as List;
      final serverIds = serverData.map((item) => item['id']).toSet();

      // 서버에 없는 로컬 데이터 개수 계산
      final localOnlyCount =
          localData.where((data) => !serverIds.contains(data['id'])).length;

      return localOnlyCount;
    } catch (e) {
      developer.log('로컬 전용 데이터 개수 확인 실패: $e', name: 'LocationService');
      return -1;
    }
  }

  /// 마지막 백업 시간 확인 (서버의 최신 데이터 기준)
  Future<DateTime?> getLastBackupTime(String userId) async {
    try {
      if (!await _checkNetworkConnection()) {
        return null;
      }

      final response = await DioClient.dio.get(
        '/location/sync/$userId',
        queryParameters: {'limit': '1', 'orderBy': 'timestamp_desc'},
      );

      final serverData = response.data as List;
      if (serverData.isEmpty) {
        return null;
      }

      final latestData = serverData.first;
      return DateTime.parse(latestData['timestamp']);
    } catch (e) {
      developer.log('마지막 백업 시간 확인 실패: $e', name: 'LocationService');
      return null;
    }
  }
}
