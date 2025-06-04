import 'dart:async';
import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geocoding/geocoding.dart';
import 'package:permission_handler/permission_handler.dart';
import '../api/location_service.dart';
import '../data/sqflite_database.dart';

/// GPS 위치 추적 서비스
@pragma('vm:entry-point')
class LocationTrackingService {
  static LocationTrackingService? _instance;
  static LocationTrackingService get instance =>
      _instance ??= LocationTrackingService._();

  LocationTrackingService._();
  late LocationService _locationService;
  Timer? _trackingTimer;
  bool _isTracking = false;
  bool _isBackgroundTracking = false;

  // 상수 정의
  static const String _isTrackingKey = 'is_tracking';
  static const String _userIdKey = 'user_id';
  static const Duration _normalInterval = Duration(minutes: 1);
  static const Duration _stationaryInterval = Duration(minutes: 5);
  static const Duration _backgroundTrackingInterval = Duration(minutes: 2);
  static const double _stationaryThresholdMeters = 10.0;
  static const int _stationaryCheckCount = 3;
  static const int _distanceFilter = 10;
  static const Duration _backgroundLocationTimeout = Duration(seconds: 30);
  static const String _notificationChannelId = 'recap_today_location';
  static const String _notificationTitle = 'Recap Today';
  static const String _notificationContent = '위치 추적 중...';
  static const int _foregroundServiceNotificationId = 888;

  // 위치 최적화 관련 변수들
  double? _lastLatitude;
  double? _lastLongitude;
  DateTime? _lastLocationTime;
  int _stationaryCount = 0;
  bool _isStationary = false;

  // [추가] 위치 저장 이벤트 StreamController (broadcast)
  final StreamController<Position> _locationLogStreamController =
      StreamController<Position>.broadcast();
  Stream<Position> get locationLogStream => _locationLogStreamController.stream;
  void initialize() {
    _locationService = LocationService(SqfliteDatabase());
  }

  /// 백그라운드 서비스 초기화
  static Future<void> initializeBackgroundService() async {
    final service = FlutterBackgroundService();

    await service.configure(
      iosConfiguration: IosConfiguration(
        autoStart: false,
        onForeground: _onBackgroundStart,
        onBackground: _onIosBackground,
      ),
      androidConfiguration: AndroidConfiguration(
        onStart: _onBackgroundStart,
        autoStart: false,
        isForegroundMode: true,
        notificationChannelId: _notificationChannelId,
        initialNotificationTitle: _notificationTitle,
        initialNotificationContent: _notificationContent,
        foregroundServiceNotificationId: _foregroundServiceNotificationId,
      ),
    );
  }

  @pragma('vm:entry-point')
  static void _onBackgroundStart(ServiceInstance service) async {
    DartPluginRegistrant.ensureInitialized();

    if (service is AndroidServiceInstance) {
      service.on('setAsForeground').listen((event) {
        service.setAsForegroundService();
      });

      service.on('setAsBackground').listen((event) {
        service.setAsBackgroundService();
      });
    }

    service.on('stopService').listen((event) {
      service.stopSelf();
    });
    // 백그라운드에서 설정된 간격마다 위치 수집
    Timer.periodic(_backgroundTrackingInterval, (timer) async {
      if (service is AndroidServiceInstance) {
        if (await service.isForegroundService()) {
          await _trackBackgroundLocation(service);
        }
      }
    });
  }

  @pragma('vm:entry-point')
  static Future<bool> _onIosBackground(ServiceInstance service) async {
    WidgetsFlutterBinding.ensureInitialized();
    DartPluginRegistrant.ensureInitialized();
    return true;
  }

  static Future<void> _trackBackgroundLocation(ServiceInstance service) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString(_userIdKey);

      if (userId == null) return;

      // 위치 권한 확인
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return;
      } // 현재 위치 가져오기
      Position position = await Geolocator.getCurrentPosition(
        locationSettings: LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: _distanceFilter,
          timeLimit: _backgroundLocationTimeout,
        ),
      );

      // 위치 저장
      final locationService = LocationService(SqfliteDatabase());
      await locationService.addLocationLog(
        userId,
        position.latitude,
        position.longitude,
      );

      // 알림 업데이트
      if (service is AndroidServiceInstance) {
        service.setForegroundNotificationInfo(
          title: "Recap Today",
          content:
              "마지막 위치 업데이트: ${DateTime.now().toString().substring(11, 16)}",
        );
      }

      debugPrint('백그라운드 위치 저장 완료: ${position.latitude}, ${position.longitude}');
    } catch (e) {
      debugPrint('백그라운드 위치 추적 오류: $e');
    }
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
        locationSettings: LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: _distanceFilter,
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
  int get currentTrackingIntervalMinutes {
    return _isStationary
        ? _stationaryInterval.inMinutes
        : _normalInterval.inMinutes;
  }

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

  /// 백그라운드 위치 추적 시작
  Future<bool> startBackgroundTracking(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // 사용자 ID 저장
      await prefs.setString(_userIdKey, userId);
      await prefs.setBool(_isTrackingKey, true);

      // 백그라운드 서비스는 메인 아이솔레이트에서만 제어
      try {
        final service = FlutterBackgroundService();
        bool isRunning = await service.isRunning();
        if (!isRunning) {
          await service.startService();
        }
      } catch (e) {
        debugPrint('백그라운드 서비스 시작 스킵 (아이솔레이트 제약): $e');
        // 메인 아이솔레이트가 아닌 경우는 설정만 저장하고 스킵
      }

      _isBackgroundTracking = true;
      debugPrint('백그라운드 위치 추적 시작: $userId');
      return true;
    } catch (e) {
      debugPrint('백그라운드 추적 시작 오류: $e');
      return false;
    }
  }

  /// 백그라운드 위치 추적 중지
  Future<bool> stopBackgroundTracking() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_isTrackingKey, false);

      // 백그라운드 서비스는 메인 아이솔레이트에서만 제어
      try {
        final service = FlutterBackgroundService();
        bool isRunning = await service.isRunning();
        if (isRunning) {
          service.invoke('stopService');
        }
      } catch (e) {
        debugPrint('백그라운드 서비스 중지 스킵 (아이솔레이트 제약): $e');
        // 메인 아이솔레이트가 아닌 경우는 설정만 저장하고 스킵
      }

      _isBackgroundTracking = false;
      debugPrint('백그라운드 위치 추적 중지');
      return true;
    } catch (e) {
      debugPrint('백그라운드 추적 중지 오류: $e');
      return false;
    }
  }

  /// 백그라운드 추적 상태 확인
  Future<bool> isBackgroundTrackingActive() async {
    final prefs = await SharedPreferences.getInstance();
    bool isTracking = prefs.getBool(_isTrackingKey) ?? false;

    // 백그라운드 서비스는 메인 아이솔레이트에서만 확인
    bool isServiceRunning = false;
    try {
      final service = FlutterBackgroundService();
      isServiceRunning = await service.isRunning();
    } catch (e) {
      debugPrint('백그라운드 서비스 상태 확인 스킵 (아이솔레이트 제약): $e');
      // 메인 아이솔레이트가 아닌 경우는 설정값만으로 판단
      return isTracking;
    }

    return isTracking && isServiceRunning;
  }

  /// 백그라운드 추적 상태 (동기)
  bool get isBackgroundTracking => _isBackgroundTracking;

  // ==================== 추가된 기능들 ====================

  /// 현재 위치 가져오기 (향상된 버전)
  Future<Position> getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('위치 서비스가 비활성화되어 있습니다.');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('위치 권한이 거부되었습니다.');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('위치 권한이 영구적으로 거부되었습니다.');
    }

    return await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    );
  }

  /// 좌표를 주소로 변환
  Future<String> getCurrentAddress(double lat, double lon) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(lat, lon);
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        return '${place.administrativeArea ?? ''} ${place.subLocality ?? ''} ${place.thoroughfare ?? ''}'
            .trim();
      }
      return '주소를 찾을 수 없습니다';
    } catch (e) {
      debugPrint('주소 변환 오류: $e');
      return '주소를 찾을 수 없습니다';
    }
  }

  /// 향상된 위치 권한 요청 (백그라운드 포함)
  Future<bool> requestLocationPermissions() async {
    try {
      // 기본 위치 권한 확인
      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.deniedForever) {
        return false;
      }

      // 백그라운드 위치 권한 요청 (Android 10+)
      PermissionStatus backgroundStatus =
          await Permission.locationAlways.status;

      if (backgroundStatus.isDenied) {
        backgroundStatus = await Permission.locationAlways.request();
      }

      return permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always;
    } catch (e) {
      debugPrint('위치 권한 요청 오류: $e');
      return false;
    }
  }

  /// 백그라운드 위치 권한 확인
  Future<bool> hasBackgroundLocationPermission() async {
    try {
      PermissionStatus status = await Permission.locationAlways.status;
      return status.isGranted;
    } catch (e) {
      debugPrint('백그라운드 위치 권한 확인 오류: $e');
      return false;
    }
  }

  /// 권한 요청 다이얼로그 표시
  Future<void> showPermissionDialog(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('위치 권한 필요'),
          content: const Text(
            '백그라운드 위치 추적을 위해서는 다음 권한이 필요합니다:\n\n'
            '1. 위치 정보 접근 권한\n'
            '2. 백그라운드 위치 접근 권한\n\n'
            '설정에서 권한을 허용해주세요.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('취소'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                openAppSettings();
              },
              child: const Text('설정으로 이동'),
            ),
          ],
        );
      },
    );
  }

  /// 배터리 최적화 권한 확인
  Future<bool> checkBatteryOptimization() async {
    try {
      PermissionStatus status =
          await Permission.ignoreBatteryOptimizations.status;

      if (status.isDenied) {
        status = await Permission.ignoreBatteryOptimizations.request();
      }

      return status.isGranted;
    } catch (e) {
      debugPrint('배터리 최적화 권한 확인 오류: $e');
      return false;
    }
  }
}
