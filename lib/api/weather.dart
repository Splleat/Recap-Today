import 'package:dio/dio.dart';
import '../constants.dart';

// 예시: 시간별 온도만 받아오는 경우
Future<List<int>> fetchWeatherData({required String nx, required String ny}) async {
  final dio = Dio();
  final url = 'http://${kBaseUrl}/weather/full?nx=$nx&ny=$ny';

  try {
    final response = await dio.get(url);
    // 응답이 List 형태라고 가정
    final List<dynamic> data = response.data;
    // 첫 날짜의 temps만 추출 (응답 구조에 따라 수정)
    if (data.isNotEmpty && data[0]['temps'] != null) {
      return List<int>.from(data[0]['temps']);
    } else {
      throw Exception('temps 데이터가 없습니다.');
    }
  } catch (e) {
    print('날씨 데이터 에러: $e');
    rethrow;
  }
}