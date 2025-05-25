import 'package:dio/dio.dart';
import 'dio_client.dart';
import '../model/full_weather_model.dart';

class WeatherService {
  Future<List<FullWeather>> fetchFullWeather(int nx, int ny) async {
    try {
      final response = await DioClient.dio.get(
        '/weather/full',
        queryParameters: {
          'nx': nx,
          'ny': ny,
        },
      );

      final data = response.data as List;
      return data.map((item) => FullWeather.fromJson(item)).toList();
    } catch (e) {
      throw Exception('날씨 데이터를 불러오지 못했습니다: $e');
    }
  }
}
