import 'package:flutter/material.dart';
import 'package:kakao_map_plugin/kakao_map_plugin.dart';

class LocationInfo extends StatefulWidget {
  const LocationInfo({super.key});

  @override
  State<LocationInfo> createState() => _LocationInfoState();
}

class _LocationInfoState extends State<LocationInfo> {
  KakaoMapController? mapController;
  bool _isMapReady = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 300,
      child: Column(
        children: [
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
                        }
                      },
                      onMapTap: (LatLng position) {
                        // 지도 탭 처리 (선택사항)
                      },
                      center: LatLng(37.5665, 126.9780), // Seoul coordinates
                    ),
                    if (!_isMapReady)
                      Positioned.fill(
                        child: Container(
                          color: Colors.grey.shade100,
                          child: const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                CircularProgressIndicator(),
                                SizedBox(height: 16),
                                Text(
                                  '카카오맵을 로딩 중...',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey,
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
