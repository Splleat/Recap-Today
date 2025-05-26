import 'package:flutter/material.dart';
import 'package:recap_today/api/weather_service.dart';
import 'package:recap_today/model/full_weather_model.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

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

String _encodeCachedWeather(CachedWeather cached) {
  return json.encode({
    'data': cached.data.map((w) => w.toJson()).toList(),
    'isComplete': cached.isComplete,
    'lastRequestAt': cached.lastRequestAt.toIso8601String(),
  });
}

CachedWeather _decodeCachedWeather(String jsonStr) {
  final map = json.decode(jsonStr);
  return CachedWeather(
    data: (map['data'] as List)
        .map((item) => WeatherData.fromJson(item))
        .toList(),
    isComplete: map['isComplete'],
    lastRequestAt: DateTime.parse(map['lastRequestAt']),
  );
}

class WeatherProvider with ChangeNotifier {
  final WeatherService _weatherService;
  final Map<String, CachedWeather> _weatherCache = {};
  bool isLoading = false;

  WeatherProvider(this._weatherService);

  List<WeatherData>? getWeather(DateTime date) {
    final dateStr = _formatDate(date);
    return _weatherCache[dateStr]?.data;
  }

  Future<void> loadCachedWeather(DateTime date) async {
    final prefs = await SharedPreferences.getInstance();
    final dateStr = _formatDate(date);
    final cachedJson = prefs.getString('weather_$dateStr');

    if (cachedJson != null) {
      final cached = _decodeCachedWeather(cachedJson);
      _weatherCache[dateStr] = cached;
      notifyListeners();
    }
}

  Future<void> fetchWeather(DateTime date, int nx, int ny, {bool force = false}) async {
    final today = DateTime.now();
    final dateStr = _formatDate(date);
    final todayStr = _formatDate(today);

    final existing = _weatherCache[dateStr];
    final alreadyFetchedToday = 
      existing != null && _formatDate(existing.lastRequestAt) == todayStr;

    // 데이터가 이미 캐시에 있고, 오늘 요청이 이미 완료되었으며, 데이터가 완전한 경우
    if (!force && alreadyFetchedToday && existing.isComplete) {
      return;
    }

    isLoading = true;
    notifyListeners();

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

      final prefs = await SharedPreferences.getInstance();
      prefs.setString('weather_$dateStr', _encodeCachedWeather(_weatherCache[dateStr]!));

      notifyListeners();
    } catch (e) {
      debugPrint('날씨 데이터 요청 실패: $e');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  bool isComplete(DateTime date) {
    final dateStr = _formatDate(date);
    return _weatherCache[dateStr]?.isComplete ?? false;
  }

  String _formatDate(DateTime date) {
    return '${date.year}${date.month.toString().padLeft(2, '0')}${date.day.toString().padLeft(2, '0')}';
  }
}