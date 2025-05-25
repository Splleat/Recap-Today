import 'package:flutter/material.dart';
import 'package:recap_today/api/weather_service.dart';
import 'package:recap_today/model/full_weather_model.dart';
import 'package:intl/intl.dart';

class CachedWeather {
  final List<WeatherData> data;
  final bool isComplete;
  final DateTime lastRequestAt;

  CachedWeather({
    required this.data,
    required this.isComplete,
    required this.lastRequestAt,
  });
}

class WeatherProvider with ChangeNotifier {
  final WeatherService _weatherService;
  final Map<String, CachedWeather> _weatherCache = {};

  WeatherProvider(this._weatherService);

  List<WeatherData>? getWeather(DateTime date) {
    final dateStr = _formatDate(date);
    return _weatherCache[dateStr]?.data;
  }

  Future<void> fetchWeather(DateTime date, int nx, int ny) async {
    final today = DateTime.now();
    final dateStr = _formatDate(date);
    final todayStr = _formatDate(today);

    final existing = _weatherCache[dateStr];
    final alreadyFetchedToday = 
      existing != null && _formatDate(existing.lastRequestAt) == todayStr;

    // 데이터가 이미 캐시에 있고 오늘 이미 요청한 경우
    if (existing != null && alreadyFetchedToday) return;
    // 데이터가 이미 캐시에 있고 오늘 이미 요청한 경우, 그리고 데이터가 불완전한 경우
    if (existing != null && alreadyFetchedToday && !existing.isComplete) return;

    try {
      final fullData = await _weatherService.fetchFullWeather(nx, ny);
      
      final matchedDay = fullData.firstWhere(
        (day) => day.date == dateStr,
        orElse: () => FullWeather(date: dateStr, weather: []),
      );

      final isComplete = matchedDay.weather.length == 24;

      _weatherCache[dateStr] = CachedWeather(
        data: matchedDay.weather,
        isComplete: isComplete,
        lastRequestAt: today,
      );

      notifyListeners();
    } catch (e) {
      debugPrint('날씨 데이터 요청 실패: $e');
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year}${date.month.toString().padLeft(2, '0')}${date.day.toString().padLeft(2, '0')}';
  }
}