import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

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
    final place = placemarks.first;
    return '${place.administrativeArea ?? ''} ${place.subLocality ?? ''} ${place.thoroughfare ?? ''}'.trim();
  }
  return '주소를 찾을 수 없습니다';
}