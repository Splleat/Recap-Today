import '../model/location_model.dart'; // Exports LocationRecord
import '../repository/abstract_location_repository.dart';
import 'dio_client.dart';
import 'package:uuid/uuid.dart';
import 'dart:developer' as developer;

class LocationService {
  final AbstractLocationRepository _locationRepository;
  final Uuid _uuid = const Uuid();
  bool _isOnline = true;

  LocationService(this._locationRepository);

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
    DateTime date, // Changed from String to DateTime
  ) async {
    try {
      // Assuming _locationRepository.getLocationRecordsForUserAndDate returns List<LocationRecord>
      final locations = await _locationRepository
          .getLocationRecordsForUserAndDate(userId, date);
      // No mapping needed if repository returns List<LocationRecord>
      return DailyLocationData(
        date: date.toIso8601String().substring(0, 10),
        locations: locations,
      );
    } catch (e) {
      developer.log('로컬 위치 데이터 조회 실패: $e', name: 'LocationService');
      return DailyLocationData(
        date: date.toIso8601String().substring(0, 10),
        locations: [],
      );
    }
  }

  /// 특정 날짜의 위치 데이터 조회 (로컬 전용)
  Future<DailyLocationData> fetchLocationDataForDate(
    String userId,
    DateTime date, // Changed from String to DateTime
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
      final localRecords = await _locationRepository
          .getAllLocationRecordsForUser(userId);

      if (localRecords.isEmpty) {
        developer.log('백업할 위치 데이터가 없습니다.', name: 'LocationService');
        return true;
      }

      // 서버에서 기존 데이터 확인하여 중복 제거
      final response = await DioClient.dio.get('/location/sync/$userId');
      final serverData = response.data as List;
      final serverIds = serverData.map((item) => item['id']).toSet();

      // 서버에 없는 로컬 데이터만 필터링
      final newRecords =
          localRecords
              .where((record) => !serverIds.contains(record.id))
              .toList();

      if (newRecords.isEmpty) {
        developer.log('백업할 새로운 데이터가 없습니다.', name: 'LocationService');
        return true;
      }

      developer.log(
        '${newRecords.length}개의 위치 데이터를 서버에 백업합니다.',
        name: 'LocationService',
      );

      // 배치로 서버에 백업
      const batchSize = 20;
      int successCount = 0;

      for (int i = 0; i < newRecords.length; i += batchSize) {
        final batch = newRecords.skip(i).take(batchSize).toList();

        try {
          final batchData =
              batch
                  .map(
                    (record) => {
                      'id':
                          record
                              .id, // Ensure ID is sent for potential server-side checks
                      'userId': record.userId,
                      'latitude': record.latitude,
                      'longitude': record.longitude,
                      'timestamp': record.timestamp.toIso8601String(),
                      'lastSynced': record.lastSynced?.toIso8601String(),
                      'isDeleted': record.isDeleted,
                    },
                  )
                  .toList();

          await DioClient.dio.post(
            '/location/sync/batch',
            data: {'locations': batchData},
          );

          // Mark as synced in local DB
          final syncedIds = batch.map((r) => r.id!).toList();
          await _locationRepository.markLocationLogsAsSynced(
            syncedIds,
            DateTime.now(),
          );

          successCount += batch.length;
          developer.log('배치 백업 완료: ${batch.length}개', name: 'LocationService');
        } catch (batchError) {
          developer.log(
            '배치 백업 실패, 개별 처리: $batchError',
            name: 'LocationService',
          );

          // 배치 실패 시 개별 처리
          for (final record in batch) {
            try {
              await DioClient.dio.post(
                '/location/sync',
                data: {
                  'id': record.id,
                  'userId': record.userId,
                  'latitude': record.latitude,
                  'longitude': record.longitude,
                  'timestamp': record.timestamp.toIso8601String(),
                  'lastSynced': record.lastSynced?.toIso8601String(),
                  'isDeleted': record.isDeleted,
                },
              );
              await _locationRepository.markLocationLogsAsSynced([
                record.id!,
              ], DateTime.now());
              successCount++;
            } catch (e) {
              developer.log(
                '개별 백업 실패: ${record.id} - $e',
                name: 'LocationService',
              );
            }
          }
        }
      }

      developer.log(
        '위치 데이터 백업 완료: $successCount/${newRecords.length}개',
        name: 'LocationService',
      );
      return successCount == newRecords.length;
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
      // Assuming LocationRecord.fromJson exists and handles the new fields
      final serverLocations =
          serverData.map((item) => LocationRecord.fromJson(item)).toList();

      if (serverLocations.isEmpty) {
        developer.log('다운로드할 서버 데이터가 없습니다.', name: 'LocationService');
        return true;
      }

      // 로컬에 없는 서버 데이터만 추가
      final localRecords = await _locationRepository
          .getAllLocationRecordsForUser(userId);
      final localIds = localRecords.map((record) => record.id).toSet();

      int downloadCount = 0;
      for (final locationRecordFromServer in serverLocations) {
        // Server data should be the source of truth for lastSynced and isDeleted
        // If local record exists, update it. Otherwise, insert.
        final existingLocalRecord = localRecords.firstWhere(
          (lr) => lr.id == locationRecordFromServer.id,
          orElse:
              () => locationRecordFromServer.copyWith(
                id: locationRecordFromServer.id,
              ),
        );

        LocationRecord recordToSave = existingLocalRecord.copyWith(
          userId: locationRecordFromServer.userId,
          latitude: locationRecordFromServer.latitude,
          longitude: locationRecordFromServer.longitude,
          timestamp: locationRecordFromServer.timestamp,
          lastSynced:
              locationRecordFromServer.lastSynced ??
              DateTime.now(), // Assume synced if from server
          isDeleted: locationRecordFromServer.isDeleted,
        );

        await _locationRepository.insertLocationRecord(
          recordToSave,
        ); // insert handles upsert via saveLocationLog
        if (!localIds.contains(locationRecordFromServer.id)) {
          downloadCount++;
        }
      }

      developer.log(
        '위치 데이터 다운로드 완료: $downloadCount개 새로 추가됨',
        name: 'LocationService',
      );
      return true;
    } catch (e) {
      developer.log('위치 데이터 다운로드 실패: $e', name: 'LocationService');
      return false;
    }
  }

  /// 위치 데이터 로컬 저장 전용 (자동 동기화 제거)
  Future<void> saveLocationDataLocally(LocationRecord location) async {
    // Changed LocationModel to LocationRecord
    try {
      // Ensure ID is generated if null
      LocationRecord recordToSave = location;
      if (location.id == null) {
        recordToSave = location.copyWith(id: _uuid.v4());
      }
      await _locationRepository.insertLocationRecord(recordToSave);
      developer.log(
        '위치 데이터 로컬 저장 완료: ${recordToSave.id}',
        name: 'LocationService',
      );
    } catch (e) {
      developer.log('로컬 위치 데이터 저장 실패: $e', name: 'LocationService');
      throw Exception('위치 데이터를 로컬에 저장하지 못했습니다: $e');
    }
  }

  /// 사용자 요청에 의한 수동 백업 실행 (대기열 데이터 처리)
  Future<bool> processPendingBackupQueue() async {
    try {
      if (!await _checkNetworkConnection()) {
        developer.log('네트워크 연결 없음 - 백업 대기열 처리 실패', name: 'LocationService');
        return false;
      }

      // getUnsyncedLocationLogs will be used as a proxy for pending items
      // as getPendingSyncLocationRecords was a placeholder for it.
      final pendingRecords =
          await _locationRepository.getUnsyncedLocationLogs();
      if (pendingRecords.isEmpty) {
        developer.log(
          '처리할 백업 대기열 데이터 없음 (unsynced logs)',
          name: 'LocationService',
        );
        return true;
      }

      developer.log(
        '처리할 백업 대기열 데이터 (unsynced logs): ${pendingRecords.length}개',
        name: 'LocationService',
      );

      // 작은 배치로 처리 (한번에 최대 10개)
      const batchSize = 10;
      int totalSuccess = 0;

      for (int i = 0; i < pendingRecords.length; i += batchSize) {
        final batch = pendingRecords.skip(i).take(batchSize).toList();
        final successCount = await _processBatch(
          batch,
        ); // Pass List<LocationRecord>
        totalSuccess += successCount;
      }

      final isAllSuccess = totalSuccess == pendingRecords.length;
      developer.log(
        '백업 대기열 처리 완료: $totalSuccess/${pendingRecords.length}개 성공',
        name: 'LocationService',
      );
      return isAllSuccess;
    } catch (e) {
      developer.log('백업 대기열 처리 실패: $e', name: 'LocationService');
      return false;
    }
  }

  /// 배치 단위로 백업 처리
  Future<int> _processBatch(List<LocationRecord> batch) async {
    // Changed to List<LocationRecord>
    int successCount = 0;

    try {
      final batchData =
          batch
              .map(
                (record) => {
                  'id': record.id,
                  'userId': record.userId,
                  'latitude': record.latitude,
                  'longitude': record.longitude,
                  'timestamp': record.timestamp.toIso8601String(),
                  'lastSynced': record.lastSynced?.toIso8601String(),
                  'isDeleted': record.isDeleted,
                },
              )
              .toList();

      await DioClient.dio.post(
        '/location/sync/batch',
        data: {'locations': batchData},
      );

      final syncedIds = batch.map((r) => r.id!).toList();
      await _locationRepository.markLocationLogsAsSynced(
        syncedIds,
        DateTime.now(),
      );
      // Also remove from explicit pending sync queue if it were used separately
      // for (final record in batch) {
      //   await _removeFromSyncQueue(record.id!);
      // }

      successCount = batch.length;
      developer.log('배치 백업 완료: ${batch.length}개', name: 'LocationService');
      return successCount;
    } catch (batchError) {
      developer.log(
        '배치 백업 실패, 개별 처리로 전환: $batchError',
        name: 'LocationService',
      );
      for (final record in batch) {
        try {
          await DioClient.dio.post(
            '/location/sync',
            data: {
              'id': record.id,
              'userId': record.userId,
              'latitude': record.latitude,
              'longitude': record.longitude,
              'timestamp': record.timestamp.toIso8601String(),
              'lastSynced': record.lastSynced?.toIso8601String(),
              'isDeleted': record.isDeleted,
            },
          );
          await _locationRepository.markLocationLogsAsSynced([
            record.id!,
          ], DateTime.now());
          // await _removeFromSyncQueue(record.id!);
          successCount++;
          developer.log('개별 백업 완료: ${record.id}', name: 'LocationService');
        } catch (e) {
          developer.log('개별 백업 실패: ${record.id} - $e', name: 'LocationService');
        }
      }
    }
    return successCount;
  }

  /// 새 위치 데이터 생성 및 로컬 저장
  Future<void> addLocationLog(
    String userId,
    double latitude,
    double longitude,
  ) async {
    final locationRecord = LocationRecord(
      id:
          _uuid
              .v4(), // ID generation responsibility might shift to repository later
      userId: userId,
      latitude: latitude,
      longitude: longitude,
      timestamp: DateTime.now(),
      lastSynced: null, // Added field
      isDeleted: false, // Added field
    );

    await saveLocationDataLocally(locationRecord);
  }

  /// 특정 사용자의 모든 위치 데이터 조회 (로컬 전용)
  Future<List<LocationRecord>> getAllLocationDataForUser(String userId) async {
    // Return List<LocationRecord>
    try {
      // Assuming repository returns List<LocationRecord>
      final localRecords = await _locationRepository
          .getAllLocationRecordsForUser(userId);
      return localRecords;
    } catch (e) {
      developer.log('사용자 위치 데이터 조회 실패: $e', name: 'LocationService');
      return [];
    }
  }

  /// 특정 날짜 범위의 위치 데이터 조회 (로컬 전용)
  Future<List<LocationRecord>> getLocationDataForDateRange(
    // Return List<LocationRecord>
    String userId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      // Assuming repository returns List<LocationRecord>
      final localRecords = await _locationRepository
          .getLocationRecordsForUserInRange(userId, startDate, endDate);
      return localRecords;
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
      await _locationRepository.deleteLocationRecordsInRange(
        userId,
        start,
        end,
      ); // Updated method
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
  Future<bool> forceSyncAll(String userId) async {
    // Added userId parameter
    developer.log('전체 백업 시작 for $userId', name: 'LocationService');
    // First, process any items that might be in a conceptual "pending queue"
    // (represented by unsynced items)
    bool pendingQueueSuccess = await processPendingBackupQueue();
    // Then, ensure all other local data is backed up
    bool fullBackupSuccess = await backupLocationDataToServer(userId);
    developer.log('전체 백업 완료 for $userId', name: 'LocationService');
    return pendingQueueSuccess && fullBackupSuccess;
  }

  /// 로컬 사용자 데이터를 실제 사용자 계정으로 마이그레이션
  Future<bool> migrateLocalUserDataToRealUser(String realUserId) async {
    try {
      const String localUserId = 'local_user';

      // 로컬 사용자의 모든 위치 데이터 조회
      final localRecords = await _locationRepository
          .getAllLocationRecordsForUser(localUserId);

      if (localRecords.isEmpty) {
        developer.log('마이그레이션할 로컬 데이터가 없습니다.', name: 'LocationService');
        return true; // 데이터가 없어도 성공으로 처리
      }

      developer.log(
        '${localRecords.length}개의 로컬 위치 데이터를 $realUserId로 마이그레이션 시작',
        name: 'LocationService',
      );

      // 각 로컬 데이터를 실제 사용자 ID로 변경하여 저장
      int migratedCount = 0;
      for (final record in localRecords) {
        // Changed from locationMap to record
        // 새로운 사용자 ID로 위치 데이터 저장
        final newLocationRecord = LocationRecord(
          // Changed to LocationRecord
          id: _uuid.v4(), // 새로운 ID 생성
          userId: realUserId, // 실제 사용자 ID로 변경
          latitude: record.latitude,
          longitude: record.longitude,
          timestamp: record.timestamp,
          lastSynced: null, // Ensure new fields are handled
          isDeleted: false,
        );

        await _locationRepository.insertLocationRecord(
          newLocationRecord,
        ); // Updated method
        migratedCount++;
      }

      // 로컬 사용자의 원본 데이터 삭제
      await _locationRepository.deleteAllLocationRecordsForUser(
        localUserId,
      ); // Updated method

      developer.log(
        '$migratedCount개의 위치 데이터 마이그레이션 완료',
        name: 'LocationService',
      );
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
      final localRecords = await _locationRepository
          .getAllLocationRecordsForUser(localUserId);
      return localRecords.isNotEmpty;
    } catch (e) {
      developer.log('로컬 데이터 확인 실패: $e', name: 'LocationService');
      return false;
    }
  }

  /// 백업 대기 중인 데이터 개수 확인
  Future<int> getPendingBackupCount() async {
    try {
      // Using getUnsyncedLocationLogs as the source for this count
      final pendingRecords =
          await _locationRepository.getUnsyncedLocationLogs();
      return pendingRecords.length;
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
      final localRecords = await _locationRepository
          .getAllLocationRecordsForUser(userId);

      // 서버 데이터 조회
      final response = await DioClient.dio.get('/location/sync/$userId');
      final serverData = response.data as List;
      final serverIds = serverData.map((item) => item['id']).toSet();

      // 서버에 없는 로컬 데이터 개수 계산
      final localOnlyCount =
          localRecords.where((record) => !serverIds.contains(record.id)).length;

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
      // Ensure server 'timestamp' is a valid ISO 8601 string
      return DateTime.parse(latestData['timestamp']);
    } catch (e) {
      developer.log('마지막 백업 시간 확인 실패: $e', name: 'LocationService');
      return null;
    }
  }
}
