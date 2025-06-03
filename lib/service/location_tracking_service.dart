import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../api/location_service.dart';
import '../data/sqflite_database.dart';

/// GPS 위치 추적 서비스
class LocationTrackingService {
  static LocationTrackingService? _instance;
  static LocationTrackingService get instance =>
      _instance ??= LocationTrackingService._();

  LocationTrackingService._();

  late LocationService _locationService;
  Timer? _trackingTimer;
  bool _isTracking = false;

  // 위치 최적화 관련 변수들
  double? _lastLatitude;
  double? _lastLongitude;
  DateTime? _lastLocationTime;
  int _stationaryCount = 0;
  bool _isStationary = false;

  // 설정 가능한 상수들
  static const double _stationaryThresholdMeters =
      10.0; // 50미터 미만 이동 시 정적 상태로 판단
  static const int _stationaryCheckCount = 3; // 3번 연속 정적 상태일 때 최적화 시작
  static const Duration _normalInterval = Duration(minutes: 1); // 정상 추적 간격
  static const Duration _stationaryInterval = Duration(
    minutes: 5,
  ); // 정적 상태 추적 간격

  // [추가] 위치 저장 이벤트 StreamController (broadcast)
  final StreamController<Position> _locationLogStreamController =
      StreamController<Position>.broadcast();
  Stream<Position> get locationLogStream => _locationLogStreamController.stream;

  void initialize() {
    _locationService = LocationService(SqfliteDatabase());
  }

  // [수정] dispose가 여러 번 호출되어도 안전하게 동작
  bool _disposed = false;
  void dispose() {
    if (!_disposed) {
      _locationLogStreamController.close();
      _disposed = true;
    }
  }

  /// 위치 추적 시작
  Future<bool> startTracking(String userId) async {
    debugPrint(
      '[LocationTrackingService] startTracking called: userId=$userId',
    );

    // GPS 서비스 사용 가능 여부 확인
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      debugPrint('위치 서비스가 비활성화되어 있습니다.');
      // 위치 서비스 설정 화면으로 이동할 수 있음
      return false;
    }

    // 위치 권한 확인
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        debugPrint('위치 권한이 거부되었습니다.');
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      debugPrint('위치 권한이 영구적으로 거부되었습니다. 설정에서 권한을 허용해주세요.');
      return false;
    }

    if (_isTracking) {
      debugPrint('이미 위치 추적이 진행 중입니다.');
      return true;
    }

    _isTracking = true;
    _resetLocationOptimization();

    // 초기에는 정상 간격으로 시작
    _startLocationTracking(userId, _normalInterval);

    debugPrint('위치 추적이 시작되었습니다.');
    return true;
  }

  /// 위치 추적 타이머 시작
  void _startLocationTracking(String userId, Duration interval) {
    _trackingTimer?.cancel();
    _trackingTimer = Timer.periodic(interval, (timer) async {
      await _handleLocationTrackingTick(userId, interval);
    });
  }

  /// 위치 추적 주기별 처리 (리팩토링)
  Future<void> _handleLocationTrackingTick(
    String userId,
    Duration interval,
  ) async {
    try {
      Position position = await _getCurrentPosition();
      final latitude = position.latitude;
      final longitude = position.longitude;

      final shouldTrack = _checkLocationChange(latitude, longitude);
      if (shouldTrack) {
        await _locationService.addLocationLog(userId, latitude, longitude);
        // [추가] 위치 저장 이벤트 발생
        _locationLogStreamController.add(position);
        debugPrint(
          '위치 로그 로컬 저장됨: $latitude, $longitude (간격: \\${interval.inMinutes}분, 정확도: \\${position.accuracy}m)',
        );
      }
      _adjustTrackingInterval(userId);
    } catch (e) {
      debugPrint('위치 로그 저장 실패: $e');
      _handleLocationError(e);
    }
  }

  /// 위치 관련 예외 처리 (더미 데이터 생성 삭제)
  void _handleLocationError(Object e) {
    if (e.toString().contains('PERMISSION_DENIED') ||
        e.toString().contains('LOCATION_SERVICES_DISABLED')) {
      debugPrint('GPS 권한 문제 또는 서비스 비활성화 감지됨');
    }
    // 더미 데이터 생성 및 저장 로직 완전 삭제
  }

  /// 현재 GPS 위치 가져오기
  Future<Position> _getCurrentPosition() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10, // 10미터 이상 이동했을 때만 업데이트
        ),
      );
      return position;
    } catch (e) {
      debugPrint('GPS 위치 가져오기 실패: $e');
      rethrow;
    }
  }

  /// 위치 변화 체크 및 정적 상태 감지
  bool _checkLocationChange(double latitude, double longitude) {
    final currentTime = DateTime.now();

    // 첫 번째 위치 기록
    if (_lastLatitude == null || _lastLongitude == null) {
      _lastLatitude = latitude;
      _lastLongitude = longitude;
      _lastLocationTime = currentTime;
      return true; // 첫 위치는 항상 기록
    }

    // 이전 위치와의 거리 계산
    final distance = _calculateDistance(
      _lastLatitude!,
      _lastLongitude!,
      latitude,
      longitude,
    );

    // 정적 상태 판단
    if (distance < _stationaryThresholdMeters) {
      _stationaryCount++;

      // 정적 상태가 연속으로 감지되면 추적 간격 늘리기
      if (_stationaryCount >= _stationaryCheckCount && !_isStationary) {
        _isStationary = true;
        debugPrint(
          '정적 상태 감지됨. 추적 간격을 ${_stationaryInterval.inMinutes}분으로 변경합니다.',
        );
      }

      // 정적 상태에서도 일정 시간마다 위치 기록 (완전히 끄지 않음)
      final timeSinceLastRecord = currentTime.difference(_lastLocationTime!);
      if (timeSinceLastRecord.inMinutes >= _stationaryInterval.inMinutes) {
        _lastLatitude = latitude;
        _lastLongitude = longitude;
        _lastLocationTime = currentTime;
        return true; // 정적 상태에서도 주기적으로 기록
      }

      return false; // 정적 상태에서 너무 자주 기록하지 않음
    } else {
      // 움직임 감지 시 정상 모드로 복구
      if (_isStationary) {
        _isStationary = false;
        _stationaryCount = 0;
        debugPrint('움직임 감지됨. 추적 간격을 ${_normalInterval.inMinutes}분으로 복구합니다.');
      }

      _lastLatitude = latitude;
      _lastLongitude = longitude;
      _lastLocationTime = currentTime;
      return true; // 움직임이 있을 때는 항상 기록
    }
  }

  /// 추적 간격 조정
  void _adjustTrackingInterval(String userId) {
    final currentInterval =
        _isStationary ? _stationaryInterval : _normalInterval;

    // 현재 타이머의 간격과 다르면 새로 시작
    if (_trackingTimer != null) {
      // Timer.periodic의 간격은 직접 비교할 수 없으므로 상태 기반으로 판단
      final needsAdjustment =
          (_isStationary && _stationaryCount == _stationaryCheckCount) ||
          (!_isStationary && _stationaryCount == 0);

      if (needsAdjustment) {
        _startLocationTracking(userId, currentInterval);
      }
    }
  }

  /// 두 지점 간의 거리 계산 (하버사인 공식, 미터 단위)
  double _calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const double earthRadius = 6371000; // 지구 반지름 (미터)

    final double dLat = _toRadians(lat2 - lat1);
    final double dLon = _toRadians(lon2 - lon1);

    final double a =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) *
            cos(_toRadians(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);

    final double c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return earthRadius * c;
  }

  /// 라디안 변환
  double _toRadians(double degrees) {
    return degrees * pi / 180;
  }

  /// 위치 최적화 상태 초기화
  void _resetLocationOptimization() {
    _lastLatitude = null;
    _lastLongitude = null;
    _lastLocationTime = null;
    _stationaryCount = 0;
    _isStationary = false;
  }

  /// 위치 추적 중지
  void stopTracking() {
    _trackingTimer?.cancel();
    _trackingTimer = null;
    _isTracking = false;
    _resetLocationOptimization();
    debugPrint('위치 추적이 중지되었습니다.');
  }

  /// 추적 상태 확인
  bool get isTracking => _isTracking;

  /// 정적 상태 확인
  bool get isStationary => _isStationary;

  /// 현재 추적 간격 확인 (분 단위)
  int get currentTrackingIntervalMinutes =>
      _isStationary ? _stationaryInterval.inMinutes : _normalInterval.inMinutes;

  /// 수동으로 현재 위치 저장
  Future<void> saveCurrentLocation(String userId) async {
    try {
      Position position = await _getCurrentPosition();

      await _locationService.addLocationLog(
        userId,
        position.latitude,
        position.longitude,
      );
      // [추가] 위치 저장 이벤트 발생
      _locationLogStreamController.add(position);
      debugPrint(
        '현재 위치 저장됨: \\${position.latitude}, \\${position.longitude} (정확도: \\${position.accuracy}m)',
      );
    } catch (e) {
      debugPrint('현재 위치 저장 실패: $e');
      rethrow;
    }
  }

  /// 위치 권한 상태 확인 (geolocator 사용)
  Future<LocationPermission> checkLocationPermission() async {
    return await Geolocator.checkPermission();
  }

  /// 위치 권한 요청 (geolocator 사용)
  Future<LocationPermission> requestLocationPermission() async {
    return await Geolocator.requestPermission();
  }

  /// GPS 서비스 활성화 상태 확인
  Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  /// 위치 서비스 설정 화면 열기
  Future<bool> openLocationSettings() async {
    return await Geolocator.openLocationSettings();
  }
}
