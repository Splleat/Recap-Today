// import 'dart:async';
// import 'package:flutter/material.dart';
// import 'package:kakao_map_plugin/kakao_map_plugin.dart';
// import 'package:provider/provider.dart';
// import 'package:geolocator/geolocator.dart';
// import '../../model/freezed/location_model.dart';
// import '../../api/location_service.dart';
// import '../../data/sqflite_database.dart';
// import '../../repository/auth_repository.dart' as auth;
// import '../../service/location_tracking_service.dart';
// import '../../provider/location_provider.dart';

// class LocationInfo extends StatefulWidget {
//   final DateTime date;
//   final String? userId; // 선택적 매개변수로 변경
//   final Key? mapKey;

//   const LocationInfo({
//     super.key,
//     required this.date,
//     this.userId, // 기본값 제거
//     this.mapKey,
//   });

//   @override
//   State<LocationInfo> createState() => LocationInfoState();
// }

// // 지도 및 위치 상태를 하나의 객체로 통합
// class LocationMapState {
//   static final LatLng defaultCenter = LatLng(37.5665, 126.9780); // 서울 시청
//   static const int defaultZoomLevel = 3; // 3으로 고정
//   static const int minZoomLevel = 1;
//   static const int maxZoomLevel = 14;
//   static const int fitBoundsFallbackZoom = 5;

//   LatLng? mapCenter;
//   bool isMapReady;
//   bool isLoading;
//   bool hasPermission;
//   DailyLocationData? locationData;
//   List<Marker> markers;
//   List<Polyline> polylines;
//   int currentZoomLevel;
//   String? errorMessage;
//   bool waitingForCurrentLocation;

//   LocationMapState({
//     this.mapCenter,
//     this.isMapReady = false,
//     this.isLoading = true,
//     this.hasPermission = false,
//     this.locationData,
//     List<Marker>? markers,
//     List<Polyline>? polylines,
//     this.currentZoomLevel = defaultZoomLevel, // defaultZoomLevel 사용
//     this.errorMessage,
//     this.waitingForCurrentLocation = false,
//   }) : markers = markers ?? [],
//        polylines = polylines ?? [];
// }

// class LocationInfoState extends State<LocationInfo>
//     with AutomaticKeepAliveClientMixin {
//   late LocationMapState _mapState;
//   KakaoMapController? mapController;
//   late LocationService _locationService;
//   late LocationTrackingService _trackingService;
//   String? _currentUserId;
//   StreamSubscription<Position>? _locationLogSubscription;
//   // _autoZoomApplied 등 자동 줌 관련 코드 제거

//   @override
//   void initState() {
//     super.initState();
//     _locationService = LocationService(SqfliteDatabase());
//     _trackingService = LocationTrackingService.instance;
//     _mapState = LocationMapState();
//     WidgetsBinding.instance.addPostFrameCallback((_) async {
//       await _getCurrentUserId();
//       if (_currentUserId != null) {
//         final provider = Provider.of<LocationProvider>(context, listen: false);
//         provider.loadLocationData(_currentUserId!, widget.date);
//       }
//     });
//   }

//   @override
//   void dispose() {
//     _locationLogSubscription?.cancel();
//     super.dispose();
//   }

//   @override
//   void deactivate() {
//     // 화면이 비활성화(탭 이동 등)될 때 구독 해제
//     _locationLogSubscription?.cancel();
//     _locationLogSubscription = null;
//     super.deactivate();
//   }

//   @override
//   void activate() {
//     super.activate();
//     // 화면이 다시 활성화될 때 조건 만족 시 재구독
//     _setupLocationLogListener();
//   }

//   void _setupLocationLogListener() {
//     // 오늘 날짜 + 권한 허용 + userId 존재 시만 구독
//     if (_isToday() && _currentUserId != null) {
//       _locationLogSubscription?.cancel();
//       final provider = Provider.of<LocationProvider>(context, listen: false);
//       _locationLogSubscription = _trackingService.locationLogStream.listen((
//         position,
//       ) {
//         // 위치 저장 이벤트 발생 시 동선 데이터 재로딩
//         if (mounted) {
//           provider.loadLocationData(_currentUserId!, widget.date);
//         }
//       });
//     } else {
//       _locationLogSubscription?.cancel();
//       _locationLogSubscription = null;
//     }
//   }

//   Future<void> _getCurrentUserId() async {
//     if (widget.userId != null) {
//       _currentUserId = widget.userId;
//       return;
//     }

//     try {
//       final authRepository = Provider.of<auth.AuthRepository>(
//         context,
//         listen: false,
//       );
//       _currentUserId = authRepository.getCurrentUserId();

//       // 로컬 first 앱이므로 로그인이 없어도 로컬 사용자 ID 생성
//       if (_currentUserId == null) {
//         _currentUserId = 'local_user'; // 로컬 사용자 기본 ID
//         debugPrint('로컬 사용자 ID 사용: $_currentUserId');
//       }
//     } catch (e) {
//       debugPrint('사용자 ID 가져오기 실패, 로컬 ID 사용: $e');
//       _currentUserId = 'local_user'; // 오류 시에도 로컬 ID 사용
//     }
//   }

//   void _resetMapToDefaultView() {
//     if (mapController == null) return;
//     mapController!.setCenter(LocationMapState.defaultCenter);
//     mapController!.setLevel(LocationMapState.defaultZoomLevel);
//   }

//   void _clearMapDrawings() {
//     if (_mapState.markers.isNotEmpty || _mapState.polylines.isNotEmpty) {
//       if (!mounted) return;
//       setState(() {
//         _mapState.markers = [];
//         _mapState.polylines = [];
//       });
//     }
//   }

//   void _updateMapWithLocationData({bool isToday = false}) async {
//     if (mapController == null) return;
//     if (isToday &&
//         (_mapState.locationData == null ||
//             _mapState.locationData!.locations.isEmpty)) {
//       _clearMapDrawings();
//       try {
//         Position position = await Geolocator.getCurrentPosition(
//           desiredAccuracy: LocationAccuracy.high,
//         );
//         if (!mounted) return;
//         if (_currentUserId != null) {
//           await _locationService.addLocationLog(
//             _currentUserId!,
//             position.latitude,
//             position.longitude,
//           );
//           // 위치를 저장만 하고 return 하므로, 아래 코드가 실행되지 않음
//           return;
//         }
//         // 아래 코드는 절대 실행되지 않으므로, 중복 마커 생성 원인 아님
//       } catch (e) {
//         debugPrint('오늘+위치데이터없음: 현재 위치 가져오기 실패: $e');
//         _resetMapToDefaultView();
//       }
//       return;
//     }
//     if (_mapState.locationData == null ||
//         _mapState.locationData!.locations.isEmpty) {
//       debugPrint("No location data. Resetting map to default view.");
//       return;
//     }
//     final locations = _mapState.locationData!.locations;
//     // 중복 마커 방지: locations가 1개 이상일 때만 마커 생성
//     if (locations.length >= 1) {
//       // 최신 위치만 사용하여 마커 1개만 표시
//       _handleSingleLocation(locations.last);
//     } else if (locations.length > 1) {
//       _handleMultipleLocations(locations);
//     }
//   }

//   void _zoomIn() {
//     if (mapController == null) return;
//     int newZoomLevel = (_mapState.currentZoomLevel - 1).clamp(
//       LocationMapState.minZoomLevel,
//       LocationMapState.maxZoomLevel,
//     );
//     if (_mapState.currentZoomLevel != newZoomLevel) {
//       mapController!.setLevel(newZoomLevel);
//       if (!mounted) return;
//       setState(() {
//         _mapState.currentZoomLevel = newZoomLevel;
//       });
//     }
//   }

//   void _zoomOut() {
//     if (mapController == null) return;
//     int newZoomLevel = (_mapState.currentZoomLevel + 1).clamp(
//       LocationMapState.minZoomLevel,
//       LocationMapState.maxZoomLevel,
//     );
//     if (_mapState.currentZoomLevel != newZoomLevel) {
//       mapController!.setLevel(newZoomLevel);
//       if (!mounted) return;
//       setState(() {
//         _mapState.currentZoomLevel = newZoomLevel;
//       });
//     }
//   }

//   // 오늘 날짜 판별 함수로 중복 제거
//   bool _isToday() {
//     final now = DateTime.now();
//     return now.year == widget.date.year &&
//         now.month == widget.date.month &&
//         now.day == widget.date.day;
//   }

//   @override
//   bool get wantKeepAlive => true;

//   @override
//   void didUpdateWidget(covariant LocationInfo oldWidget) {
//     super.didUpdateWidget(oldWidget);
//     if (widget.date != oldWidget.date) {
//       if (_currentUserId != null) {
//         final provider = Provider.of<LocationProvider>(context, listen: false);
//         provider.loadLocationData(_currentUserId!, widget.date);
//       }
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     super.build(context);
//     final locationProvider = Provider.of<LocationProvider>(context);
//     final isToday = _isToday();
//     final locations = locationProvider.locationData?.locations ?? [];
//     debugPrint(
//       '[LocationInfo] build: locations.length = \\${locations.length}',
//     );
//     if (locations.isNotEmpty) {
//       final first = locations.first;
//       debugPrint(
//         '[LocationInfo] First location: lat=\\${first.latitude}, lng=\\${first.longitude}, ts=\\${first.timestamp}',
//       );
//     }
//     if (!isToday && locations.isEmpty) {
//       return const NoDataView();
//     }
//     if (isToday && locations.isEmpty) {
//       return const LoadingView();
//     }
//     // 기존 _buildLocationMap 대신 Provider 데이터 기반으로 동선 표시
//     return _buildLocationMapWithProvider(locationProvider, isToday);
//   }

//   Widget _buildLocationMapWithProvider(
//     LocationProvider provider,
//     bool isToday,
//   ) {
//     if (_mapState.locationData != provider.locationData) {
//       _mapState.locationData = provider.locationData;
//       if (_mapState.isMapReady) {
//         _updateMapWithLocationData(isToday: isToday);
//       }
//     }
//     // 기존 코드 유지
//     return SizedBox(
//       height: 300,
//       child: Column(
//         children: [
//           Padding(
//             padding: const EdgeInsets.all(16.0),
//             child: Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 Text(
//                   '하루 동선',
//                   style: Theme.of(
//                     context,
//                   ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
//                 ),
//                 if (provider.locationData != null &&
//                     provider.locationData!.locations.isNotEmpty)
//                   Text(
//                     '${provider.locationData!.locations.length}개 위치',
//                     style: Theme.of(
//                       context,
//                     ).textTheme.bodyMedium?.copyWith(color: Colors.black87),
//                   ),
//               ],
//             ),
//           ),
//           Expanded(
//             child: Container(
//               decoration: BoxDecoration(
//                 borderRadius: BorderRadius.circular(12.0),
//                 border: Border.all(color: Colors.grey.shade300),
//               ),
//               child: ClipRRect(
//                 borderRadius: BorderRadius.circular(12.0),
//                 child: Stack(
//                   children: [
//                     KakaoMap(
//                       key: ValueKey(
//                         _mapState.mapCenter?.toString() ?? 'default',
//                       ),
//                       onMapCreated: (KakaoMapController controller) {
//                         if (mounted) {
//                           setState(() {
//                             mapController = controller;
//                             _mapState.isMapReady = true;
//                           });
//                           _updateMapWithLocationData(isToday: isToday);
//                         }
//                       },
//                       onMapTap: (LatLng position) {},
//                       center:
//                           (!_mapState.isMapReady
//                               ? _mapState.mapCenter ??
//                                   LocationMapState.defaultCenter
//                               : null),
//                       markers: _mapState.markers,
//                       polylines: _mapState.polylines,
//                       onCameraIdle: (LatLng latLng, int zoomLevel) {
//                         debugPrint(
//                           '[LocationInfo] onCameraIdle: zoomLevel=$zoomLevel',
//                         );
//                         if (mounted) {
//                           int newZoomLevel = zoomLevel.clamp(
//                             LocationMapState.minZoomLevel,
//                             LocationMapState.maxZoomLevel,
//                           );
//                           if (_mapState.currentZoomLevel != newZoomLevel) {
//                             setState(() {
//                               _mapState.currentZoomLevel = newZoomLevel;
//                             });
//                           }
//                         }
//                       },
//                     ),
//                     Positioned(
//                       left: 16,
//                       top: 16,
//                       child: FutureBuilder<int>(
//                         future: mapController?.getLevel(),
//                         builder: (context, snapshot) {
//                           return Container(
//                             padding: const EdgeInsets.symmetric(
//                               horizontal: 8,
//                               vertical: 4,
//                             ),
//                             decoration: BoxDecoration(
//                               color: Colors.black.withOpacity(0.5),
//                               borderRadius: BorderRadius.circular(8),
//                             ),
//                             child: Text(
//                               'Zoom: [36m${snapshot.data ?? '-'}[0m',
//                               style: const TextStyle(
//                                 color: Colors.white,
//                                 fontSize: 14,
//                               ),
//                             ),
//                           );
//                         },
//                       ),
//                     ),
//                     // 줌 컨트롤 버튼들
//                     Positioned(
//                       top: 16,
//                       right: 16,
//                       child: Column(
//                         children: [
//                           Container(
//                             decoration: BoxDecoration(
//                               color: Colors.white,
//                               borderRadius: BorderRadius.circular(8),
//                               boxShadow: [
//                                 BoxShadow(
//                                   color: Colors.black.withOpacity(0.1),
//                                   blurRadius: 4,
//                                   offset: const Offset(0, 2),
//                                 ),
//                               ],
//                             ),
//                             child: Column(
//                               children: [
//                                 InkWell(
//                                   onTap: _zoomIn,
//                                   borderRadius: const BorderRadius.vertical(
//                                     top: Radius.circular(8),
//                                   ),
//                                   child: Container(
//                                     width: 44,
//                                     height: 44,
//                                     decoration: const BoxDecoration(
//                                       borderRadius: BorderRadius.vertical(
//                                         top: Radius.circular(8),
//                                       ),
//                                     ),
//                                     child: const Icon(
//                                       Icons.add,
//                                       size: 20,
//                                       color: Colors.black87,
//                                     ),
//                                   ),
//                                 ),
//                                 Container(
//                                   width: 44,
//                                   height: 1,
//                                   color: Colors.grey.shade300,
//                                 ),
//                                 InkWell(
//                                   onTap: _zoomOut,
//                                   borderRadius: const BorderRadius.vertical(
//                                     bottom: Radius.circular(8),
//                                   ),
//                                   child: Container(
//                                     width: 44,
//                                     height: 44,
//                                     decoration: const BoxDecoration(
//                                       borderRadius: BorderRadius.vertical(
//                                         bottom: Radius.circular(8),
//                                       ),
//                                     ),
//                                     child: const Icon(
//                                       Icons.remove,
//                                       size: 20,
//                                       color: Colors.black87,
//                                     ),
//                                   ),
//                                 ),
//                               ],
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                     if (!_mapState.isMapReady)
//                       Positioned.fill(
//                         child: Container(
//                           color: Colors.grey.shade100,
//                           child: Center(
//                             child: Column(
//                               mainAxisAlignment: MainAxisAlignment.center,
//                               children: [
//                                 const CircularProgressIndicator(),
//                                 const SizedBox(height: 16),
//                                 Text(
//                                   '카카오맵을 로딩 중...',
//                                   style: TextStyle(
//                                     fontSize: 16,
//                                     color: Colors.black87,
//                                   ),
//                                 ),
//                               ],
//                             ),
//                           ),
//                         ),
//                       ),
//                     if (_mapState.isMapReady &&
//                         !isToday &&
//                         (_mapState.locationData?.locations.isEmpty ?? true))
//                       Positioned.fill(
//                         child: Container(
//                           color: Colors.grey.shade50,
//                           child: const Center(
//                             child: Column(
//                               mainAxisAlignment: MainAxisAlignment.center,
//                               children: [
//                                 Icon(
//                                   Icons.location_off,
//                                   size: 48,
//                                   color: Colors.black54,
//                                 ),
//                                 SizedBox(height: 16),
//                                 Text(
//                                   '이 날의 위치 데이터가 없습니다',
//                                   style: TextStyle(
//                                     fontSize: 16,
//                                     color: Colors.black87,
//                                   ),
//                                 ),
//                               ],
//                             ),
//                           ),
//                         ),
//                       ),
//                   ],
//                 ),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   /// 위치 데이터가 2개 이상일 때 모든 위치에 마커와 경로(폴리라인)를 표시한다.
//   void _handleMultipleLocations(List<LocationModel> locations) {
//     final points =
//         locations.map((loc) => LatLng(loc.latitude, loc.longitude)).toList();
//     final markers =
//         locations.asMap().entries.map((entry) {
//           final idx = entry.key;
//           final loc = entry.value;
//           return Marker(
//             markerId: 'location_$idx',
//             latLng: LatLng(loc.latitude, loc.longitude),
//             width: 36,
//             height: 36,
//           );
//         }).toList();
//     final polyline = Polyline(
//       polylineId: 'daily_route',
//       points: points,
//       strokeColor: Colors.blue,
//       strokeWidth: 3,
//       strokeOpacity: 0.8,
//     );
//     setState(() {
//       _mapState.markers = markers;
//       _mapState.polylines = [polyline];
//       _mapState.mapCenter = points.first;
//       _mapState.currentZoomLevel = LocationMapState.defaultZoomLevel;
//     });
//     if (mapController != null) {
//       try {
//         mapController!.fitBounds(points);
//       } catch (e) {
//         debugPrint("지도 범위 설정 오류: $e");
//         mapController!.setCenter(points.first);
//         mapController!.setLevel(LocationMapState.fitBoundsFallbackZoom);
//       }
//     }
//   }

//   /// 위치 데이터가 1개일 때 해당 위치에 마커를 표시하고, 지도를 중앙으로 이동시킨다.
//   void _handleSingleLocation(LocationModel location) async {
//     final point = LatLng(location.latitude, location.longitude);
//     final marker = Marker(
//       markerId: 'current_location', // 항상 동일한 markerId 사용
//       latLng: point,
//       width: 36,
//       height: 36,
//     );
//     setState(() {
//       _mapState.markers = [marker]; // 항상 1개만
//       _mapState.polylines = [];
//       _mapState.mapCenter = point;
//       _mapState.currentZoomLevel = LocationMapState.defaultZoomLevel;
//     });
//     if (mapController != null) {
//       debugPrint('[LocationInfo] setCenter to single location');
//       mapController!.setCenter(point);
//       mapController!.setLevel(LocationMapState.defaultZoomLevel);
//     }
//   }
// }

// // 상태별 위젯 컴포넌트 분리
// class LoadingView extends StatelessWidget {
//   final String? errorMessage;
//   const LoadingView({this.errorMessage, super.key});
//   @override
//   Widget build(BuildContext context) {
//     return SizedBox(
//       height: 300,
//       child: Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             const CircularProgressIndicator(),
//             const SizedBox(height: 16),
//             const Text('위치 데이터 로드 중...'),
//             if (errorMessage != null) ...[
//               const SizedBox(height: 16),
//               Text(
//                 errorMessage!,
//                 style: const TextStyle(color: Colors.red, fontSize: 14),
//                 textAlign: TextAlign.center,
//               ),
//             ],
//           ],
//         ),
//       ),
//     );
//   }
// }

// class ErrorView extends StatelessWidget {
//   final String message;
//   const ErrorView(this.message, {super.key});
//   @override
//   Widget build(BuildContext context) {
//     return SizedBox(
//       height: 300,
//       child: Center(
//         child: Text(
//           message,
//           style: const TextStyle(color: Colors.red, fontSize: 16),
//           textAlign: TextAlign.center,
//         ),
//       ),
//     );
//   }
// }

// class PermissionView extends StatelessWidget {
//   final VoidCallback onRequestPermission;
//   final VoidCallback onOpenSettings;
//   const PermissionView({
//     required this.onRequestPermission,
//     required this.onOpenSettings,
//     super.key,
//   });
//   @override
//   Widget build(BuildContext context) {
//     return Padding(
//       padding: const EdgeInsets.all(24.0),
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           const Icon(Icons.location_off, size: 48, color: Colors.orange),
//           const SizedBox(height: 16),
//           const Text(
//             '위치 정보를 보려면 GPS 권한이 필요합니다.',
//             textAlign: TextAlign.center,
//             style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
//           ),
//           const SizedBox(height: 8),
//           const Text(
//             '위치 추적을 허용하면 하루 동선을 확인할 수 있습니다.',
//             textAlign: TextAlign.center,
//             style: TextStyle(fontSize: 14, color: Colors.grey),
//           ),
//           const SizedBox(height: 16),
//           const Text(
//             '📱 배터리 최적화 설정 팁',
//             style: TextStyle(
//               fontSize: 14,
//               fontWeight: FontWeight.bold,
//               color: Colors.blue,
//             ),
//           ),
//           const SizedBox(height: 8),
//           const Text(
//             '정확한 위치 추적을 위해 앱이 자동으로 종료되지 않도록 배터리 최적화에서 제외해주세요.',
//             textAlign: TextAlign.center,
//             style: TextStyle(fontSize: 12, color: Colors.grey),
//           ),
//           const SizedBox(height: 24),
//           Column(
//             children: [
//               ElevatedButton.icon(
//                 onPressed: onRequestPermission,
//                 icon: const Icon(Icons.gps_fixed),
//                 label: const Text('위치 권한 허용'),
//                 style: ElevatedButton.styleFrom(
//                   padding: const EdgeInsets.symmetric(
//                     horizontal: 24,
//                     vertical: 12,
//                   ),
//                 ),
//               ),
//               const SizedBox(height: 8),
//               TextButton.icon(
//                 onPressed: onOpenSettings,
//                 icon: const Icon(Icons.settings),
//                 label: const Text('설정에서 권한 관리'),
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }
// }

// class NoDataView extends StatelessWidget {
//   const NoDataView({super.key});
//   @override
//   Widget build(BuildContext context) {
//     return SizedBox(
//       height: 300,
//       child: Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: const [
//             Icon(Icons.location_off, size: 48, color: Colors.black54),
//             SizedBox(height: 16),
//             Text(
//               '이 날의 위치 데이터가 없습니다',
//               style: TextStyle(fontSize: 16, color: Colors.black87),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
