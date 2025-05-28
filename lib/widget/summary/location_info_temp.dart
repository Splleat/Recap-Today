import 'package:flutter/material.dart';
import 'package:kakao_map_plugin/kakao_map_plugin.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import '../../model/location_model.dart';
import '../../api/location_service.dart';
import '../../data/sqflite_database.dart';
import '../../repository/auth_repository.dart' as auth;
import '../../service/location_tracking_service.dart';

class LocationInfo extends StatefulWidget {
  final DateTime date;
  final String? userId; // 선택적 매개변수로 변경

  const LocationInfo({
    super.key,
    required this.date,
    this.userId, // 기본값 제거
  });

  @override
  State<LocationInfo> createState() => _LocationInfoState();
}

class _LocationInfoState extends State<LocationInfo> {
  KakaoMapController? mapController;
  bool _isMapReady = false;
  bool _isLoading = true;
  bool _hasPermission = false;
  DailyLocationData? _locationData;
  List<Marker> _markers = [];
  List<Polyline> _polylines = [];
  late LocationService _locationService;
  late LocationTrackingService _trackingService;
  String? _currentUserId;
  int _currentZoomLevel = 5;

  @override
  void initState() {
    super.initState();
    _locationService = LocationService(SqfliteDatabase());
    _trackingService = LocationTrackingService.instance;
    _initialize();
  }

  Future<void> _initialize() async {
    await _getCurrentUserId();
    await _checkPermissionAndLoadData();
  }

  Future<void> _getCurrentUserId() async {
    if (widget.userId != null) {
      _currentUserId = widget.userId;
      return;
    }

    try {
      final authRepository = Provider.of<auth.AuthRepository>(
        context,
        listen: false,
      );
      _currentUserId = authRepository.getCurrentUserId();

      if (_currentUserId == null) {
        debugPrint('사용자 ID를 찾을 수 없습니다. 로그인이 필요합니다.');
      }
    } catch (e) {
      debugPrint('사용자 ID 가져오기 실패: $e');
    }
  }

  Future<void> _checkPermissionAndLoadData() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // GPS 권한 확인
      _hasPermission = await _checkLocationPermission();

      if (_hasPermission && _currentUserId != null) {
        await _loadLocationData();
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('권한 확인 및 데이터 로드 실패: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<bool> _checkLocationPermission() async {
    try {
      LocationPermission permission =
          await _trackingService.checkLocationPermission();
      return permission == LocationPermission.always ||
          permission == LocationPermission.whileInUse;
    } catch (e) {
      debugPrint('위치 권한 확인 실패: $e');
      return false;
    }
  }

  Future<void> _requestLocationPermission() async {
    try {
      LocationPermission permission =
          await _trackingService.requestLocationPermission();
      bool hasPermission =
          permission == LocationPermission.always ||
          permission == LocationPermission.whileInUse;

      setState(() {
        _hasPermission = hasPermission;
      });

      if (hasPermission && _currentUserId != null) {
        await _loadLocationData();
      }
    } catch (e) {
      debugPrint('위치 권한 요청 실패: $e');
    }
  }

  Future<void> _openLocationSettings() async {
    try {
      await _trackingService.openLocationSettings();
      // 설정에서 돌아온 후 권한 다시 확인
      if (mounted) {
        await _checkPermissionAndLoadData();
      }
    } catch (e) {
      debugPrint('위치 설정 열기 실패: $e');
    }
  }

  Future<void> _loadLocationData() async {
    if (_currentUserId == null) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    try {
      setState(() {
        _isLoading = true;
      });

      final dateString = DateFormat('yyyy-MM-dd').format(widget.date);

      // 로컬 우선 방식으로 위치 데이터 가져오기 (즉시 응답)
      final locationData = await _locationService.fetchLocationDataForDate(
        _currentUserId!,
        dateString,
      );

      if (mounted) {
        setState(() {
          _locationData = locationData;
          _isLoading = false;
        });
      }

      if (_isMapReady && mounted) {
        _updateMapWithLocationData();
      }

      // 백그라운드에서 동기화 대기열 처리 (사용자 경험에 영향 없음)
      _locationService.processPendingSyncQueue();
    } catch (e) {
      debugPrint('위치 데이터 로드 실패: $e');

      if (mounted) {
        setState(() {
          _locationData = DailyLocationData(
            date: DateFormat('yyyy-MM-dd').format(widget.date),
            locations: [],
          );
          _isLoading = false;
        });

        if (_isMapReady) {
          _updateMapWithLocationData();
        }
      }
    }
  }

  void _updateMapWithLocationData() {
    if (mapController == null) return;

    // _locationData가 null이거나 locations가 비어있을 경우 처리
    if (_locationData == null || _locationData!.locations.isEmpty) {
      setState(() {
        _markers = [];
        _polylines = [];
      });
      // 기본 위치 및 줌 레벨로 지도 설정
      mapController!.setCenter(LatLng(37.5665, 126.9780)); // 서울 시청
      mapController!.setLevel(7); // 적절한 기본 줌 레벨
      debugPrint("No location data. Resetting map to default view.");
      return;
    }

    final locations = _locationData!.locations;
    // 마커 생성 (삭제 - 동선 확인에 방해됨)
    _markers = [];

    // 동선 라인 생성
    final points =
        locations.map((loc) => LatLng(loc.latitude, loc.longitude)).toList();

    if (points.length > 1) {
      _polylines = [
        Polyline(
          polylineId: 'daily_route',
          points: points,
          strokeColor: Colors.blue,
          strokeWidth: 3,
          strokeOpacity: 0.8,
        ),
      ];
    } else {
      // 위치가 하나만 있거나 없을 경우 폴리라인 초기화
      _polylines = [];
    }

    // 지도 뷰 조정
    if (mapController != null) {
      if (points.length == 1) {
        // 위치가 하나일 경우 해당 위치로 중앙 이동 및 현재 줌 레벨 사용
        final firstLocation = points.first;
        mapController!.setCenter(firstLocation);
        mapController!.setLevel(_currentZoomLevel);
      } else if (points.length > 1) {
        // 위치가 여러 개일 경우 모든 위치를 포함하도록 지도 범위 조정
        try {
          mapController!.fitBounds(points);
        } catch (e) {
          print("Error calling fitBounds(points): $e");
          // Fallback: center on the first point with a default zoom
          if (points.isNotEmpty) {
            mapController!.setCenter(points.first);
            mapController!.setLevel(5);
          } else {
            mapController!.setCenter(LatLng(37.5665, 126.9780));
            mapController!.setLevel(7);
          }
        }
      }
    }

    if (mounted) {
      setState(() {});
    }
  }

  void _zoomIn() {
    if (mapController != null) {
      int newZoomLevel = (_currentZoomLevel - 1).clamp(1, 14);
      if (_currentZoomLevel != newZoomLevel) {
        mapController!.setLevel(newZoomLevel);
        setState(() {
          _currentZoomLevel = newZoomLevel;
        });
      }
    }
  }

  void _zoomOut() {
    if (mapController != null) {
      int newZoomLevel = (_currentZoomLevel + 1).clamp(1, 14);
      if (_currentZoomLevel != newZoomLevel) {
        mapController!.setLevel(newZoomLevel);
        setState(() {
          _currentZoomLevel = newZoomLevel;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return SizedBox(
        height: 300,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('위치 데이터 로드 중...'),
            ],
          ),
        ),
      );
    }

    if (_currentUserId == null) {
      return _buildLoginRequiredMessage();
    }

    if (!_hasPermission) {
      return _buildPermissionRequest();
    }

    return _buildLocationMap();
  }

  Widget _buildLoginRequiredMessage() {
    return SizedBox(
      height: 300,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.login, size: 48, color: Colors.orange),
            SizedBox(height: 16),
            Text(
              '위치 정보를 보려면 로그인이 필요합니다.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPermissionRequest() {
    return SizedBox(
      height: 300,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.location_off, size: 48, color: Colors.orange),
              SizedBox(height: 16),
              Text(
                '위치 정보를 보려면 GPS 권한이 필요합니다.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                '위치 추적을 허용하면 하루 동선을 확인할 수 있습니다.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              SizedBox(height: 16),
              Text(
                '📱 배터리 최적화 설정 팁',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
              SizedBox(height: 8),
              Text(
                '정확한 위치 추적을 위해 앱이 자동으로 종료되지 않도록 배터리 최적화에서 제외해주세요.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              SizedBox(height: 24),
              Column(
                children: [
                  ElevatedButton.icon(
                    onPressed: _requestLocationPermission,
                    icon: Icon(Icons.gps_fixed),
                    label: Text('위치 권한 허용'),
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                  ),
                  SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: _openLocationSettings,
                    icon: Icon(Icons.settings),
                    label: Text('설정에서 권한 관리'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLocationMap() {
    return SizedBox(
      height: 300,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '하루 동선',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                if (_locationData != null &&
                    _locationData!.locations.isNotEmpty)
                  Text(
                    '${_locationData!.locations.length}개 위치',
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: Colors.black87),
                  ),
              ],
            ),
          ),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12.0),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12.0),
                child: Stack(
                  children: [
                    KakaoMap(
                      onMapCreated: (KakaoMapController controller) {
                        if (mounted) {
                          setState(() {
                            mapController = controller;
                            _isMapReady = true;
                          });
                          _updateMapWithLocationData();
                        }
                      },
                      onMapTap: (LatLng position) {
                        // 지도 탭 처리 (선택사항)
                      },
                      center: LatLng(37.5665, 126.9780), // Seoul coordinates
                      markers: _markers,
                      polylines: _polylines,
                      onCameraIdle: (LatLng latLng, int zoomLevel) {
                        if (mounted) {
                          int newZoomLevel = zoomLevel.clamp(1, 14);
                          if (_currentZoomLevel != newZoomLevel) {
                            setState(() {
                              _currentZoomLevel = newZoomLevel;
                            });
                          }
                        }
                      },
                    ),
                    // 줌 컨트롤 버튼들
                    Positioned(
                      top: 16,
                      right: 16,
                      child: Column(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                InkWell(
                                  onTap: _zoomIn,
                                  borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(8),
                                  ),
                                  child: Container(
                                    width: 44,
                                    height: 44,
                                    decoration: const BoxDecoration(
                                      borderRadius: BorderRadius.vertical(
                                        top: Radius.circular(8),
                                      ),
                                    ),
                                    child: const Icon(
                                      Icons.add,
                                      size: 20,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ),
                                Container(
                                  width: 44,
                                  height: 1,
                                  color: Colors.grey.shade300,
                                ),
                                InkWell(
                                  onTap: _zoomOut,
                                  borderRadius: const BorderRadius.vertical(
                                    bottom: Radius.circular(8),
                                  ),
                                  child: Container(
                                    width: 44,
                                    height: 44,
                                    decoration: const BoxDecoration(
                                      borderRadius: BorderRadius.vertical(
                                        bottom: Radius.circular(8),
                                      ),
                                    ),
                                    child: const Icon(
                                      Icons.remove,
                                      size: 20,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (!_isMapReady)
                      Positioned.fill(
                        child: Container(
                          color: Colors.grey.shade100,
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const CircularProgressIndicator(),
                                const SizedBox(height: 16),
                                Text(
                                  '카카오맵을 로딩 중...',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    if (_isMapReady &&
                        (_locationData?.locations.isEmpty ?? true))
                      Positioned.fill(
                        child: Container(
                          color: Colors.grey.shade50,
                          child: const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.location_off,
                                  size: 48,
                                  color: Colors.black54,
                                ),
                                SizedBox(height: 16),
                                Text(
                                  '이 날의 위치 데이터가 없습니다',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
