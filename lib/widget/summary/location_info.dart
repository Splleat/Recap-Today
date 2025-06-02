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
  final Key? mapKey;

  const LocationInfo({
    super.key,
    required this.date,
    this.userId, // 기본값 제거
    this.mapKey,
  });

  @override
  State<LocationInfo> createState() => LocationInfoState();
}

// 지도 및 위치 상태를 하나의 객체로 통합
class LocationMapState {
  static final LatLng defaultCenter = LatLng(37.5665, 126.9780); // 서울 시청
  static const int defaultZoomLevel = 7;
  static const int minZoomLevel = 1;
  static const int maxZoomLevel = 14;
  static const int fitBoundsFallbackZoom = 5;

  LatLng? mapCenter;
  bool isMapReady;
  bool isLoading;
  bool hasPermission;
  DailyLocationData? locationData;
  List<Marker> markers;
  List<Polyline> polylines;
  int currentZoomLevel;
  String? errorMessage;
  bool waitingForCurrentLocation;

  LocationMapState({
    this.mapCenter,
    this.isMapReady = false,
    this.isLoading = true,
    this.hasPermission = false,
    this.locationData,
    List<Marker>? markers,
    List<Polyline>? polylines,
    this.currentZoomLevel = defaultZoomLevel,
    this.errorMessage,
    this.waitingForCurrentLocation = false,
  }) : markers = markers ?? [],
       polylines = polylines ?? [];
}

class LocationInfoState extends State<LocationInfo>
    with AutomaticKeepAliveClientMixin {
  late LocationMapState _mapState;
  KakaoMapController? mapController;
  late LocationService _locationService;
  late LocationTrackingService _trackingService;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _locationService = LocationService(SqfliteDatabase());
    _trackingService = LocationTrackingService.instance;
    _mapState = LocationMapState();
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

      // 로컬 first 앱이므로 로그인이 없어도 로컬 사용자 ID 생성
      if (_currentUserId == null) {
        _currentUserId = 'local_user'; // 로컬 사용자 기본 ID
        debugPrint('로컬 사용자 ID 사용: $_currentUserId');
      }
    } catch (e) {
      debugPrint('사용자 ID 가져오기 실패, 로컬 ID 사용: $e');
      _currentUserId = 'local_user'; // 오류 시에도 로컬 ID 사용
    }
  }

  Future<void> _checkPermissionAndLoadData() async {
    if (!mounted) return;
    setState(() {
      _mapState.isLoading = true;
      _mapState.errorMessage = null;
    });
    try {
      _mapState.hasPermission = await _checkLocationPermission();
      if (_mapState.hasPermission && _currentUserId != null) {
        await _loadLocationData();
      } else {
        setState(() {
          _mapState.isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('권한 확인 및 데이터 로드 실패: $e');
      setState(() {
        _mapState.isLoading = false;
        _mapState.errorMessage = '위치 권한 확인 또는 데이터 로드 중 오류가 발생했습니다.';
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
        _mapState.hasPermission = hasPermission;
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
      if (_mapState.isLoading != false ||
          _mapState.errorMessage != '사용자 정보를 불러올 수 없습니다.') {
        setState(() {
          _mapState.isLoading = false;
          _mapState.errorMessage = '사용자 정보를 불러올 수 없습니다.';
        });
      }
      return;
    }
    try {
      if (_mapState.isLoading != true || _mapState.errorMessage != null) {
        setState(() {
          _mapState.isLoading = true;
          _mapState.errorMessage = null;
        });
      }
      final dateString = DateFormat('yyyy-MM-dd').format(widget.date);
      final locationData = await _locationService.fetchLocationDataForDate(
        _currentUserId!,
        dateString,
      );
      if (!mounted) return;
      if (_mapState.locationData != locationData ||
          _mapState.isLoading != false) {
        setState(() {
          _mapState.locationData = locationData;
          _mapState.isLoading = false;
        });
      }
      _updateMapView(isToday: _isToday());
      if (_mapState.isMapReady) {
        _updateMapWithLocationData();
      }
      _locationService.processPendingBackupQueue();
    } catch (e) {
      debugPrint('위치 데이터 로드 실패: $e');
      if (!mounted) return;
      final errorState = DailyLocationData(
        date: DateFormat('yyyy-MM-dd').format(widget.date),
        locations: [],
      );
      if (_mapState.locationData != errorState ||
          _mapState.isLoading != false ||
          _mapState.errorMessage != '위치 데이터를 불러오는 중 오류가 발생했습니다.') {
        setState(() {
          _mapState.locationData = errorState;
          _mapState.isLoading = false;
          _mapState.errorMessage = '위치 데이터를 불러오는 중 오류가 발생했습니다.';
        });
      }
      if (_mapState.isMapReady) {
        _updateMapWithLocationData();
      }
    }
  }

  void _resetMapToDefaultView() {
    if (mapController == null) return;
    mapController!.setCenter(LocationMapState.defaultCenter);
    mapController!.setLevel(LocationMapState.defaultZoomLevel);
  }

  void _clearMapDrawings() {
    if (_mapState.markers.isNotEmpty || _mapState.polylines.isNotEmpty) {
      if (!mounted) return;
      setState(() {
        _mapState.markers = [];
        _mapState.polylines = [];
      });
    }
  }

  void _updateMapWithLocationData({bool isToday = false}) async {
    if (mapController == null) return;
    // 오늘+위치데이터없음: 현재 위치 마커만 표시 (기존 로직 유지)
    if (isToday &&
        (_mapState.locationData == null ||
            _mapState.locationData!.locations.isEmpty)) {
      _clearMapDrawings();
      try {
        Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );
        if (!mounted) return;
        final currentLatLng = LatLng(position.latitude, position.longitude);
        final currentMarker = Marker(
          markerId: 'current_location',
          latLng: currentLatLng,
          width: 36,
          height: 36,
        );
        if (!mounted) return;
        setState(() {
          _mapState.markers = [currentMarker];
          _mapState.polylines = [];
        });
        mapController?.setCenter(currentLatLng);
        mapController?.setLevel(LocationMapState.defaultZoomLevel);
      } catch (e) {
        debugPrint('오늘+위치데이터없음: 현재 위치 가져오기 실패: $e');
        _resetMapToDefaultView();
      }
      return;
    }
    // 위치 데이터가 없을 때
    if (_mapState.locationData == null ||
        _mapState.locationData!.locations.isEmpty) {
      _handleNoLocationData();
      debugPrint("No location data. Resetting map to default view.");
      return;
    }
    final locations = _mapState.locationData!.locations;
    if (locations.length == 1) {
      _handleSingleLocation(locations.first);
    } else if (locations.length > 1) {
      _handleMultipleLocations(locations);
    }
  }

  void _zoomIn() {
    if (mapController == null) return;
    int newZoomLevel = (_mapState.currentZoomLevel - 1).clamp(
      LocationMapState.minZoomLevel,
      LocationMapState.maxZoomLevel,
    );
    if (_mapState.currentZoomLevel != newZoomLevel) {
      mapController!.setLevel(newZoomLevel);
      if (!mounted) return;
      setState(() {
        _mapState.currentZoomLevel = newZoomLevel;
      });
    }
  }

  void _zoomOut() {
    if (mapController == null) return;
    int newZoomLevel = (_mapState.currentZoomLevel + 1).clamp(
      LocationMapState.minZoomLevel,
      LocationMapState.maxZoomLevel,
    );
    if (_mapState.currentZoomLevel != newZoomLevel) {
      mapController!.setLevel(newZoomLevel);
      if (!mounted) return;
      setState(() {
        _mapState.currentZoomLevel = newZoomLevel;
      });
    }
  }

  Future<void> _addCurrentLocationMarker() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      if (!mounted) return;
      final currentLatLng = LatLng(position.latitude, position.longitude);
      final currentMarker = Marker(
        markerId: 'current_location',
        latLng: currentLatLng,
        width: 36,
        height: 36,
      );
      if (!mounted) return;
      setState(() {
        _mapState.markers.removeWhere((m) => m.markerId == 'current_location');
        _mapState.markers.add(currentMarker);
      });
    } catch (e) {
      debugPrint('현재 위치 가져오기 실패: $e');
    }
  }

  /// 위치 데이터가 없을 때 지도, 마커, 경로 상태를 초기화한다.
  void _handleNoLocationData() {
    if (!mounted) return;
    setState(() {
      _mapState.markers = [];
      _mapState.polylines = [];
      _mapState.mapCenter = LocationMapState.defaultCenter;
      _mapState.currentZoomLevel = LocationMapState.defaultZoomLevel;
    });
    if (mapController != null) {
      mapController!.setCenter(LocationMapState.defaultCenter);
      mapController!.setLevel(LocationMapState.defaultZoomLevel);
    }
  }

  // 중복 위치/지도 로직 함수화
  Future<LatLng> _getCurrentLocationLatLng() async {
    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    return LatLng(position.latitude, position.longitude);
  }

  LatLng _getMapCenter({required bool isToday}) {
    if (isToday && _mapState.mapCenter != null) {
      return _mapState.mapCenter!;
    } else if (_mapState.locationData?.locations.isNotEmpty ?? false) {
      final first = _mapState.locationData!.locations.first;
      return LatLng(first.latitude, first.longitude);
    } else {
      return LocationMapState.defaultCenter;
    }
  }

  // 위치 요청 중복 방지용 Future
  Future<LatLng>? _currentLocationFuture;

  void _updateMapView({required bool isToday}) {
    if (isToday && (_mapState.locationData?.locations.isEmpty ?? true)) {
      if (_mapState.mapCenter == null && !_mapState.waitingForCurrentLocation) {
        _mapState.waitingForCurrentLocation = true;
        _currentLocationFuture ??= _getCurrentLocationLatLng()
            .then((latLng) {
              if (mounted) {
                setState(() {
                  _mapState.mapCenter = latLng;
                  _mapState.waitingForCurrentLocation = false;
                });
              }
              _currentLocationFuture = null;
              return latLng;
            })
            .catchError((e) {
              debugPrint('현재 위치(center) 가져오기 실패: $e');
              if (mounted) {
                setState(() {
                  _mapState.mapCenter = LocationMapState.defaultCenter;
                  _mapState.waitingForCurrentLocation = false;
                });
              }
              _currentLocationFuture = null;
              return LocationMapState.defaultCenter;
            });
      }
    } else {
      final newCenter = _getMapCenter(isToday: isToday);
      if (_mapState.mapCenter != newCenter) {
        if (mounted) {
          setState(() {
            _mapState.mapCenter = newCenter;
          });
        } else {
          _mapState.mapCenter = newCenter;
        }
      }
    }
  }

  // 오늘 날짜 판별 함수로 중복 제거
  bool _isToday() {
    final now = DateTime.now();
    return now.year == widget.date.year &&
        now.month == widget.date.month &&
        now.day == widget.date.day;
  }

  @override
  bool get wantKeepAlive => true;

  // 외부에서 호출할 수 있는 새로고침 메서드
  Future<void> refreshData() async {
    await _checkPermissionAndLoadData();
  }

  @override
  void didUpdateWidget(covariant LocationInfo oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.date != oldWidget.date) {
      _checkPermissionAndLoadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // AutomaticKeepAliveClientMixin 요구사항
    final isToday = _isToday();
    if (_mapState.isLoading) {
      return LoadingView(errorMessage: _mapState.errorMessage);
    }
    if (!_mapState.hasPermission) {
      return PermissionView(
        onRequestPermission: _requestLocationPermission,
        onOpenSettings: _openLocationSettings,
      );
    }
    if (!isToday && (_mapState.locationData?.locations.isEmpty ?? true)) {
      return const NoDataView();
    }
    if (isToday && (_mapState.locationData?.locations.isEmpty ?? true)) {
      if (_mapState.mapCenter == null) {
        return const LoadingView();
      }
    }
    return _buildLocationMap(isToday: isToday);
  }

  // 상태별 위젯 컴포넌트 분리
  Widget _buildLocationMap({bool isToday = false}) {
    // 오늘이고 위치 데이터가 없으면 현재 위치 마커만 보장
    if (isToday &&
        _mapState.isMapReady &&
        (_mapState.locationData?.locations.isEmpty ?? true)) {
      _addCurrentLocationMarker();
    } else if (isToday && _mapState.isMapReady) {
      _addCurrentLocationMarker(); // 오늘+동선 있으면 동선+현재위치 모두 표시
    }

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
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                if (_mapState.locationData != null &&
                    _mapState.locationData!.locations.isNotEmpty)
                  Text(
                    '${_mapState.locationData!.locations.length}개 위치',
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
                            _mapState.isMapReady = true;
                          });
                          if (_mapState.locationData != null) {
                            _updateMapWithLocationData(isToday: isToday);
                          }
                        }
                      },
                      onMapTap: (LatLng position) {},
                      center:
                          _mapState.mapCenter ?? LocationMapState.defaultCenter,
                      markers: _mapState.markers,
                      polylines: _mapState.polylines,
                      onCameraIdle: (LatLng latLng, int zoomLevel) {
                        if (mounted) {
                          int newZoomLevel = zoomLevel.clamp(
                            LocationMapState.minZoomLevel,
                            LocationMapState.maxZoomLevel,
                          );
                          if (_mapState.currentZoomLevel != newZoomLevel) {
                            setState(() {
                              _mapState.currentZoomLevel = newZoomLevel;
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
                    if (!_mapState.isMapReady)
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
                    if (_mapState.isMapReady &&
                        !isToday &&
                        (_mapState.locationData?.locations.isEmpty ?? true))
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

  /// 위치 데이터가 2개 이상일 때 모든 위치에 마커와 경로(폴리라인)를 표시한다.
  void _handleMultipleLocations(List<LocationModel> locations) {
    final points =
        locations.map((loc) => LatLng(loc.latitude, loc.longitude)).toList();
    final markers =
        locations.asMap().entries.map((entry) {
          final idx = entry.key;
          final loc = entry.value;
          return Marker(
            markerId: 'location_$idx',
            latLng: LatLng(loc.latitude, loc.longitude),
            width: 36,
            height: 36,
          );
        }).toList();
    final polyline = Polyline(
      polylineId: 'daily_route',
      points: points,
      strokeColor: Colors.blue,
      strokeWidth: 3,
      strokeOpacity: 0.8,
    );
    setState(() {
      _mapState.markers = markers;
      _mapState.polylines = [polyline];
      _mapState.mapCenter = points.first;
      _mapState.currentZoomLevel = LocationMapState.defaultZoomLevel;
    });
    if (mapController != null) {
      try {
        mapController!.fitBounds(points);
      } catch (e) {
        debugPrint("지도 범위 설정 오류: $e");
        mapController!.setCenter(points.first);
        mapController!.setLevel(LocationMapState.fitBoundsFallbackZoom);
      }
    }
  }

  /// 위치 데이터가 1개일 때 해당 위치에 마커를 표시하고, 지도를 중앙으로 이동시킨다.
  void _handleSingleLocation(LocationModel location) {
    final point = LatLng(location.latitude, location.longitude);
    final marker = Marker(
      markerId: 'location_0',
      latLng: point,
      width: 36,
      height: 36,
    );
    setState(() {
      _mapState.markers = [marker];
      _mapState.polylines = [];
      _mapState.mapCenter = point;
      _mapState.currentZoomLevel = LocationMapState.defaultZoomLevel;
    });
    if (mapController != null) {
      mapController!.setCenter(point);
      mapController!.setLevel(LocationMapState.defaultZoomLevel);
    }
  }
}

// 상태별 위젯 컴포넌트 분리
class LoadingView extends StatelessWidget {
  final String? errorMessage;
  const LoadingView({this.errorMessage, super.key});
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 300,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            const Text('위치 데이터 로드 중...'),
            if (errorMessage != null) ...[
              const SizedBox(height: 16),
              Text(
                errorMessage!,
                style: const TextStyle(color: Colors.red, fontSize: 14),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class ErrorView extends StatelessWidget {
  final String message;
  const ErrorView(this.message, {super.key});
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 300,
      child: Center(
        child: Text(
          message,
          style: const TextStyle(color: Colors.red, fontSize: 16),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

class PermissionView extends StatelessWidget {
  final VoidCallback onRequestPermission;
  final VoidCallback onOpenSettings;
  const PermissionView({
    required this.onRequestPermission,
    required this.onOpenSettings,
    super.key,
  });
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.location_off, size: 48, color: Colors.orange),
          const SizedBox(height: 16),
          const Text(
            '위치 정보를 보려면 GPS 권한이 필요합니다.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            '위치 추적을 허용하면 하루 동선을 확인할 수 있습니다.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
          const SizedBox(height: 16),
          const Text(
            '📱 배터리 최적화 설정 팁',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '정확한 위치 추적을 위해 앱이 자동으로 종료되지 않도록 배터리 최적화에서 제외해주세요.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 24),
          Column(
            children: [
              ElevatedButton.icon(
                onPressed: onRequestPermission,
                icon: const Icon(Icons.gps_fixed),
                label: const Text('위치 권한 허용'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: onOpenSettings,
                icon: const Icon(Icons.settings),
                label: const Text('설정에서 권한 관리'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class NoDataView extends StatelessWidget {
  const NoDataView({super.key});
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 300,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.location_off, size: 48, color: Colors.black54),
            SizedBox(height: 16),
            Text(
              '이 날의 위치 데이터가 없습니다',
              style: TextStyle(fontSize: 16, color: Colors.black87),
            ),
          ],
        ),
      ),
    );
  }
}
