import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:flutter/foundation.dart';

Future<Position> getCurrentLocation() async {
  bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) {
    // 위치 서비스가 비활성화된 경우
    throw Exception('위치 서비스가 비활성화되어 있습니다.');
  }

  LocationPermission permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    // 위치 권한이 거부된 경우
    permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) {
      // 여전히 권한이 거부된 경우
      throw Exception('위치 권한이 거부되었습니다.');
    }
  }

  if (permission == LocationPermission.deniedForever) {
    // 위치 권한이 영구적으로 거부된 경우
    throw Exception('위치 권한이 영구적으로 거부되었습니다.');
  }

  // 현재 위치를 가져옴
  return await Geolocator.getCurrentPosition(
    desiredAccuracy: LocationAccuracy.high,
  );
}

Future<String> getCurrentAddress(double lat, double lon) async {
  List<Placemark> placemarks = await placemarkFromCoordinates(lat, lon);
  if (placemarks.isNotEmpty) {
    for (var place in placemarks) {
      debugPrint('Placemark: ${place.toString()}'); // 모든 속성을 출력
      debugPrint('Name: ${place.name}');
      debugPrint('Street: ${place.street}');
      debugPrint('Locality: ${place.locality}');
      debugPrint('Administrative Area: ${place.administrativeArea}');
      debugPrint('Postal Code: ${place.postalCode}');
      debugPrint('Country: ${place.country}');
    }
    final place = placemarks.first;
    return place.toString();
  }
  return '주소를 찾을 수 없습니다';
}