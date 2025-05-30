import 'dart:async';
import 'package:flutter/material.dart';
import 'package:pedometer/pedometer.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:recap_today/model/step_model.dart';

class StepProvider with ChangeNotifier {
  StepModel todayStep = StepModel(date: DateTime.now(), stepCount: 0);
  int _baseStepCount = 0;
  int _dailyGoal = 5000;
  int get dailyGoal => _dailyGoal;
  DateTime _lastDate = DateTime.now();
  StreamSubscription<StepCount>? _subscription;

  Future<void> initialize() async {
    await _loadBaseStepInfo();
    await _loadDailyGoal();
    _subscription = Pedometer.stepCountStream.listen(
      _onStepCount,
      onError: (e) => debugPrint('걸음 수 오류: $e'),
      cancelOnError: true,
    );
  }

  Future<void> _loadBaseStepInfo() async {
    final prefs = await SharedPreferences.getInstance();
    _baseStepCount = prefs.getInt('stepBase') ?? 0;
    final lastDateStr = prefs.getString('stepDate');
    if (lastDateStr != null) {
      _lastDate = DateTime.tryParse(lastDateStr) ?? DateTime.now();
    }
  }

  void _onStepCount(StepCount event) async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();

    // 날짜가 바뀌었는지 확인
    if (!_isSameDay(_lastDate, now)) {
      _baseStepCount = event.steps;
      _lastDate = now;
      await prefs.setInt('stepBase', _baseStepCount);
      await prefs.setString('stepDate', now.toIso8601String());
    }

    final todaySteps = (event.steps - _baseStepCount).clamp(0, 100000);
    todayStep = StepModel(date: now, stepCount: todaySteps);
    notifyListeners();
  }

  Future<void> _loadDailyGoal() async {
    final prefs = await SharedPreferences.getInstance();
    _dailyGoal = prefs.getInt('dailyGoal') ?? 5000;
    notifyListeners();
  }

  Future<void> updateDailyGoal(int goal) async {
    final prefs = await SharedPreferences.getInstance();
    _dailyGoal = goal;
    await prefs.setInt('dailyGoal', goal);
    notifyListeners();
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
