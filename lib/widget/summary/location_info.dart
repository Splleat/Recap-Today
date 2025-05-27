import 'package:flutter/material.dart';
import 'package:kakao_map_plugin/kakao_map_plugin.dart';
import 'package:intl/intl.dart';
import '../../model/location_model.dart';
import '../../api/location_service.dart';
import '../../data/sqflite_database.dart';

class LocationInfo extends StatefulWidget {
  final DateTime date;
  final String userId;

  const LocationInfo({
    super.key,
    required this.date,
    this.userId = 'test-user', // 임시 사용자 ID
  });

  @override
  State<LocationInfo> createState() => _LocationInfoState();
}

class _LocationInfoState extends State<LocationInfo> {
  KakaoMapController? mapController;
  bool _isMapReady = false;
  bool _isLoading = true;
  DailyLocationData? _locationData;
  List<Marker> _markers = [];
  List<Polyline> _polylines = [];
  late LocationService _locationService;
  int _currentZoomLevel = 5; // 기본 줌 레벨을 유효한 범위(1-14) 내의 값으로 변경 (예: 5)

  @override
  void initState() {
    super.initState();
    _locationService = LocationService(SqfliteDatabase());
    _loadLocationData();
  }

  Future<void> _loadLocationData() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final dateString = DateFormat('yyyy-MM-dd').format(widget.date);

      // 로컬 우선 방식으로 위치 데이터 가져오기 (즉시 응답)
      final locationData = await _locationService.fetchLocationDataForDate(
        widget.userId,
        dateString,
      );

      // 데이터가 비어있으면 더미 데이터로 대체 (테스트용)
      if (locationData.locations.isEmpty && mounted) {
        final dummyLocations = _generateDummyLocations();

        if (mounted) {
          setState(() {
            _locationData = DailyLocationData(
              date: dateString,
              locations: dummyLocations,
            );
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _locationData = locationData;
            _isLoading = false;
          });
        }
      }

      if (_isMapReady && mounted) {
        _updateMapWithLocationData();
      }

      // 백그라운드에서 동기화 대기열 처리 (사용자 경험에 영향 없음)
      _locationService.processPendingSyncQueue();
    } catch (e) {
      debugPrint('위치 데이터 로드 실패: $e');

      // 오류 발생 시 더미 데이터 사용
      final dummyLocations = _generateDummyLocations();

      if (mounted) {
        setState(() {
          _locationData = DailyLocationData(
            date: DateFormat('yyyy-MM-dd').format(widget.date),
            locations: dummyLocations,
          );
          _isLoading = false;
        });

        if (_isMapReady) {
          _updateMapWithLocationData();
        }
      }
    }
  }

  List<LocationModel> _generateDummyLocations() {
    return [
      LocationModel(
        id: '1',
        userId: widget.userId,
        latitude: 37.5665,
        longitude: 126.9780,
        timestamp: DateTime(
          widget.date.year,
          widget.date.month,
          widget.date.day,
          9,
          0,
        ),
      ),
      LocationModel(
        id: '2',
        userId: widget.userId,
        latitude: 37.5595,
        longitude: 126.9745,
        timestamp: DateTime(
          widget.date.year,
          widget.date.month,
          widget.date.day,
          12,
          0,
        ),
      ),
      LocationModel(
        id: '3',
        userId: widget.userId,
        latitude: 37.5547,
        longitude: 126.9706,
        timestamp: DateTime(
          widget.date.year,
          widget.date.month,
          widget.date.day,
          15,
          0,
        ),
      ),
      LocationModel(
        id: '4',
        userId: widget.userId,
        latitude: 37.5512,
        longitude: 126.9882,
        timestamp: DateTime(
          widget.date.year,
          widget.date.month,
          widget.date.day,
          18,
          0,
        ),
      ),
    ];
  }

  void _updateMapWithLocationData() {
    if (mapController == null) return; // mapController가 null이면 아무것도 하지 않음

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
    _markers =
        []; // Ensure markers are always cleared as per previous requirement

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
            // points가 비어있는 극단적인 경우 (위의 null/empty 체크로 걸러지지만 안전장치)
            mapController!.setCenter(LatLng(37.5665, 126.9780));
            mapController!.setLevel(7);
          }
        }
      }
      // points가 비어있는 경우는 이미 위에서 처리됨
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

                          // 맵 컨트롤러가 준비되었으므로, 현재 데이터 상태에 따라 지도 업데이트 시도
                          // _loadLocationData()는 initState에서 이미 호출됨.
                          // _updateMapWithLocationData()는 _locationData가 null이거나 비어있는 경우를 처리하여 기본 뷰를 설정함.
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
                            print(
                              "onCameraIdle: Zoom Level Changed from $_currentZoomLevel to $newZoomLevel",
                            );
                            setState(() {
                              _currentZoomLevel = newZoomLevel;
                            });
                          }
                        }
                      },
                      // onZoomChangeCallback: (int zoomLevel, ZoomType zoomType) {
                      //   if (mounted) {
                      //     int newZoomLevel = zoomLevel.clamp(1, 14);
                      //     if (_currentZoomLevel != newZoomLevel) {
                      //       print("onZoomChangeCallback: Zoom Level Changed from $_currentZoomLevel to $newZoomLevel, type: $zoomType");
                      //       setState(() {
                      //         _currentZoomLevel = newZoomLevel;
                      //       });
                      //     }
                      //   }
                      // },
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
                    if (!_isMapReady || _isLoading)
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
                                  _isLoading
                                      ? '위치 데이터 로드 중...'
                                      : '카카오맵을 로딩 중...',
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
                    if (!_isLoading &&
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
