import 'dio_client.dart';
import '../model/full_weather_model.dart';
import 'package:recap_today/service/location_tracking_service.dart';

class WeatherService {
  Future<List<FullWeather>> fetchFullWeather() async {
    try {
      final position =
          await LocationTrackingService.instance.getCurrentLocation();
      final response = await DioClient.dio.get(
        '/weather/full/geo',
        queryParameters: {'lat': position.latitude, 'lon': position.longitude},
      );

      final data = response.data as List;
      return data.map((item) => FullWeather.fromJson(item)).toList();
    } catch (e) {
      throw Exception('날씨 데이터를 불러오지 못했습니다: $e');
    }
  }
}