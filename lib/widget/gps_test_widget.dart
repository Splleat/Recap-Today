import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import '../service/location_tracking_service.dart';
import '../repository/auth_repository.dart' as auth;

/// GPS 테스트를 위한 개선된 위젯 (애뮬레이터 지원 포함)
class GPSTestWidget extends StatefulWidget {
  const GPSTestWidget({super.key});

  @override
  State<GPSTestWidget> createState() => _GPSTestWidgetState();
}

class _GPSTestWidgetState extends State<GPSTestWidget> {
  final LocationTrackingService _trackingService =
      LocationTrackingService.instance;
  String _statusText = 'GPS 테스트 준비됨';
  bool _isTracking = false;
  String? _currentUserId;
  @override
  void initState() {
    super.initState();
    _trackingService.initialize();
    _getCurrentUserId();
    _checkGPSStatus();
  }

  Future<void> _getCurrentUserId() async {
    try {
      final authRepository = Provider.of<auth.AuthRepository>(
        context,
        listen: false,
      );
      _currentUserId = authRepository.getCurrentUserId();

      // 로컬 first 앱이므로 로그인이 없어도 로컬 사용자 ID 생성
      if (_currentUserId == null) {
        _currentUserId = 'local_user'; // 로컬 사용자 기본 ID
        debugPrint('GPS 테스트 - 로컬 사용자 ID 사용: $_currentUserId');
      } else {
        debugPrint('GPS 테스트 - 현재 사용자 ID: $_currentUserId');
      }
    } catch (e) {
      debugPrint('사용자 ID 가져오기 실패, 로컬 ID 사용: $e');
      _currentUserId = 'local_user'; // 오류 시에도 로컬 ID 사용
    }
  }

  Future<void> _checkGPSStatus() async {
    try {
      bool serviceEnabled = await _trackingService.isLocationServiceEnabled();
      LocationPermission permission =
          await _trackingService.checkLocationPermission();

      setState(() {
        _statusText =
            'GPS 서비스: ${serviceEnabled ? "활성화" : "비활성화"}\n'
            'GPS 권한: ${_getPermissionText(permission)}';
      });
    } catch (e) {
      setState(() {
        _statusText = 'GPS 상태 확인 실패: $e';
      });
    }
  }

  String _getPermissionText(LocationPermission permission) {
    switch (permission) {
      case LocationPermission.always:
        return '항상 허용';
      case LocationPermission.whileInUse:
        return '앱 사용 중 허용';
      case LocationPermission.denied:
        return '거부됨';
      case LocationPermission.deniedForever:
        return '영구 거부됨';
      case LocationPermission.unableToDetermine:
        return '확인 불가';
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      setState(() {
        _statusText = '현재 위치 가져오는 중...';
      });

      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 0,
        ),
      );
      setState(() {
        _statusText =
            '현재 위치 획득 성공!\n'
            '위도: ${position.latitude.toStringAsFixed(6)}\n'
            '경도: ${position.longitude.toStringAsFixed(6)}\n'
            '정확도: ${position.accuracy.toStringAsFixed(1)}m\n'
            '시간: ${DateTime.fromMillisecondsSinceEpoch(position.timestamp.millisecondsSinceEpoch)}';
      });
    } catch (e) {
      setState(() {
        _statusText = '위치 가져오기 실패: $e';
      });
    }
  }

  Future<void> _startTracking() async {
    // 로컬 first 앱이므로 _currentUserId는 항상 설정되어 있음
    try {
      bool success = await _trackingService.startTracking(_currentUserId!);
      setState(() {
        _isTracking = success;
        _statusText = success ? '위치 추적 시작됨' : '위치 추적 시작 실패';
      });
    } catch (e) {
      setState(() {
        _statusText = '추적 시작 실패: $e';
      });
    }
  }

  void _stopTracking() {
    _trackingService.stopTracking();
    setState(() {
      _isTracking = false;
      _statusText = '위치 추적 중지됨';
    });
  }

  Future<void> _saveCurrentLocation() async {
    // 로컬 first 앱이므로 _currentUserId는 항상 설정되어 있음
    try {
      await _trackingService.saveCurrentLocation(_currentUserId!);
      setState(() {
        _statusText = '현재 위치 저장 완료';
      });
    } catch (e) {
      setState(() {
        _statusText = '위치 저장 실패: $e';
      });
    }
  }

  Future<void> _requestPermission() async {
    try {
      LocationPermission permission =
          await _trackingService.requestLocationPermission();
      setState(() {
        _statusText = '권한 요청 결과: ${_getPermissionText(permission)}';
      });
    } catch (e) {
      setState(() {
        _statusText = '권한 요청 실패: $e';
      });
    }
  }

  Future<void> _openLocationSettings() async {
    try {
      bool opened = await _trackingService.openLocationSettings();
      setState(() {
        _statusText = opened ? '위치 설정 화면이 열렸습니다' : '위치 설정 화면 열기 실패';
      });
    } catch (e) {
      setState(() {
        _statusText = '설정 화면 열기 실패: $e';
      });
    }
  }

  /// 에뮬레이터용 위치 시뮬레이션 도움말 표시
  void _showEmulatorGuide() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('🚀 에뮬레이터 GPS 시뮬레이션'),
          content: const SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '에뮬레이터에서 GPS 테스트 방법:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 12),
                Text('1. Extended Controls 사용:'),
                Text('   • Ctrl + Shift + P 단축키'),
                Text('   • Location 탭 선택'),
                Text('   • 위도/경도 입력 후 SEND'),
                SizedBox(height: 8),
                Text('2. 테스트 시나리오:'),
                Text('   • 명동: 37.5665, 126.9780'),
                Text('   • 강남: 37.4979, 127.0276'),
                Text('   • 정적 상태: 같은 위치 3번 설정'),
                Text('   • 움직임: 50m 이상 떨어진 위치'),
                SizedBox(height: 8),
                Text('3. ADB 명령어:'),
                Text('   adb emu geo fix 126.9780 37.5665'),
                SizedBox(height: 8),
                Text(
                  '💡 에뮬레이터는 실제보다 더 정확하고 반복 가능한 테스트를 제공합니다!',
                  style: TextStyle(
                    color: Colors.blue,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('확인'),
            ),
          ],
        );
      },
    );
  }

  /// 자동 시뮬레이션 테스트 실행
  Future<void> _runAutoSimulation() async {
    final locations = [
      {'name': '명동', 'lat': 37.5665, 'lng': 126.9780},
      {'name': '서울역', 'lat': 37.5547, 'lng': 126.9707},
      {'name': '강남역', 'lat': 37.4979, 'lng': 127.0276},
      {'name': '여의도', 'lat': 37.5194, 'lng': 126.9244},
    ];

    setState(() {
      _statusText = '자동 시뮬레이션 시작...\n아래 ADB 명령어를 터미널에서 실행하세요:';
    });

    String commands = '';
    for (var location in locations) {
      commands += 'adb emu geo fix ${location['lng']} ${location['lat']}\n';
    }

    setState(() {
      _statusText = '자동 시뮬레이션 가이드:\n\n$commands\n각 명령어 사이에 10초 대기하세요.';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('GPS 테스트'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          // Wrap with SingleChildScrollView
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 상태 표시
              Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8.0),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'GPS 상태',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(_statusText),
                    const SizedBox(
                      height: 16,
                    ), // 사용자 로그인 상태 표시 (로컬 앱이므로 항상 사용 가능)
                    Row(
                      children: [
                        Icon(Icons.person, color: Colors.green),
                        const SizedBox(width: 8),
                        Text(
                          '사용자: ${_currentUserId ?? "로컬 사용자"}',
                          style: TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Icon(
                          _isTracking ? Icons.gps_fixed : Icons.gps_not_fixed,
                          color: _isTracking ? Colors.green : Colors.red,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '추적 상태: ${_isTracking ? "활성" : "비활성"}',
                          style: TextStyle(
                            color: _isTracking ? Colors.green : Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    if (_trackingService.isTracking) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            _trackingService.isStationary
                                ? Icons.pause_circle
                                : Icons.directions_walk,
                            color:
                                _trackingService.isStationary
                                    ? Colors.orange
                                    : Colors.blue,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '모드: ${_trackingService.isStationary ? "정적 상태" : "움직임 감지"}',
                            style: TextStyle(
                              color:
                                  _trackingService.isStationary
                                      ? Colors.orange
                                      : Colors.blue,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '추적 간격: ${_trackingService.currentTrackingIntervalMinutes}분',
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // 버튼들
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ElevatedButton.icon(
                    onPressed: _checkGPSStatus,
                    icon: const Icon(Icons.refresh),
                    label: const Text('상태 확인'),
                  ),
                  ElevatedButton.icon(
                    onPressed: _requestPermission,
                    icon: const Icon(Icons.security),
                    label: const Text('권한 요청'),
                  ),
                  ElevatedButton.icon(
                    onPressed: _openLocationSettings,
                    icon: const Icon(Icons.settings),
                    label: const Text('설정 열기'),
                  ),
                  ElevatedButton.icon(
                    onPressed: _showEmulatorGuide,
                    icon: const Icon(Icons.help_outline),
                    label: const Text('에뮬레이터 가이드'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 시뮬레이션 버튼
              ElevatedButton.icon(
                onPressed: _runAutoSimulation,
                icon: const Icon(Icons.route),
                label: const Text('자동 시뮬레이션 가이드'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  foregroundColor: Colors.white,
                ),
              ),
              const SizedBox(height: 16),

              ElevatedButton.icon(
                onPressed: _getCurrentLocation,
                icon: const Icon(Icons.my_location),
                label: const Text('현재 위치 가져오기'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: _saveCurrentLocation,
                icon: const Icon(Icons.save),
                label: Text('현재 위치 저장'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
              ),
              const SizedBox(height: 16), // 추적 제어 버튼
              if (!_isTracking)
                ElevatedButton.icon(
                  onPressed: _startTracking,
                  icon: const Icon(Icons.play_arrow),
                  label: Text('위치 추적 시작'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                )
              else
                ElevatedButton.icon(
                  onPressed: _stopTracking,
                  icon: const Icon(Icons.stop),
                  label: const Text('위치 추적 중지'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
