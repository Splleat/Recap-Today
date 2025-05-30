import 'package:flutter/material.dart';
import 'package:recap_today/api/weather_service.dart';
import 'package:recap_today/model/full_weather_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class WeatherProvider with ChangeNotifier {
  final WeatherService _weatherService;
  final Map<String, List<WeatherData>> _weatherCache = {};
  bool isLoading = false;

  WeatherProvider(this._weatherService);

  /// 날짜별 캐시된 날씨 가져오기
  List<WeatherData>? getWeather(DateTime date) {
    final dateStr = _formatDate(date);
    return _weatherCache[dateStr];
  }

  /// SharedPreferences에서 캐시 불러오기
  Future<void> loadCachedWeather(DateTime date) async {
    final prefs = await SharedPreferences.getInstance();
    final dateStr = _formatDate(date);
    final cachedJson = prefs.getString('weather_$dateStr');

    if (cachedJson != null) {
      final jsonList = json.decode(cachedJson) as List;
      _weatherCache[dateStr] =
          jsonList.map((e) => WeatherData.fromJson(e)).toList();
      notifyListeners();
    }
  }

  /// 기상청 API로 날씨 요청하고 캐시에 저장
  Future<void> fetchWeather(DateTime date, int nx, int ny) async {
    final reqDay = _formatDate(date);
    final prefs = await SharedPreferences.getInstance();

    if (reqDay == prefs.getString('lastReq')) {
      debugPrint('이미 요청함');
      loadCachedWeather(date);
      return;
    }
    
    try {
      final fullData = await _weatherService.fetchFullWeather(nx, ny);
      isLoading = true;
      final prefs = await SharedPreferences.getInstance();

      for (final day in fullData) {
        final dayStr = day.date.replaceAll('-', '');

        _weatherCache[dayStr] = day.weather;

        final encoded = json.encode(day.weather.map((w) => w.toJson()).toList());
        prefs.setString('weather_$dayStr', encoded);

        debugPrint('[캐시됨] $dayStr → ${day.weather.length}개 항목');
      }

      prefs.setString('lastReq', reqDay);

      notifyListeners();
    } catch (e) {
      debugPrint('날씨 데이터 요청 실패: $e');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year}${date.month.toString().padLeft(2, '0')}${date.day.toString().padLeft(2, '0')}';
  }
}
