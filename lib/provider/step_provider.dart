import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:pedometer/pedometer.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:health/health.dart';
import 'package:recap_today/model/freezed/step_model.dart';

class StepProvider with ChangeNotifier {
  String userId;
  late StepModel todayStep;
  int _baseStepCount = 0;
  int _dailyGoal = 5000;
  DateTime _lastDate = DateTime.now();
  StreamSubscription<StepCount>? _subscription;

  // 생성자에서 userId를 받도록 수정
  StepProvider({required this.userId}) {
    todayStep = StepModel(userId: userId, date: DateTime.now(), stepCount: 0);
  }

  int get dailyGoal => _dailyGoal;

  // userId가 변경될 경우 업데이트하는 메서드 추가
  void updateUserId(String newUserId) {
    if (userId != newUserId) {
      // 여기에서 userId를 직접 변경하지 않고, 
      // 필요한 로직만 수행 (새 Provider 인스턴스가 생성될 것이므로)
      _resetStepData();
      notifyListeners();
    }
  }

  void _resetStepData() {
    todayStep = StepModel(userId: userId, date: DateTime.now(), stepCount: 0);
    _baseStepCount = 0;
  }

  Future<void> initialize() async {
    final status = await Permission.activityRecognition.status;
    todayStep = StepModel(userId: userId, date: DateTime.now(), stepCount: 0);
    
    if (!status.isGranted) {
      final result = await Permission.activityRecognition.request();
      if (!result.isGranted) {
        debugPrint('활동 인식 권한이 거부되었습니다.');
        return; // 예외를 던지는 대신 로깅하고 반환
      }
    }

    await _requestPermissions();
    await _loadBaseStepInfo();
    await _loadDailyGoal();

    // 기존 구독이 있으면 취소
    await _subscription?.cancel();
    
    _subscription = Pedometer.stepCountStream.listen(
      _onStepCount,
      onError: (e) => debugPrint('걸음 수 오류: $e'),
      cancelOnError: true,
    );
  }

  void _onStepCount(StepCount event) async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();

    // 사용자별 저장소 키 사용
    final baseKey = '${userId}_stepBase';
    final dateKey = '${userId}_stepDate';

    if (!_isSameDay(_lastDate, now) || _baseStepCount == 0) {
      _baseStepCount = event.steps;
      _lastDate = now;
      await prefs.setInt(baseKey, _baseStepCount);
      await prefs.setString(dateKey, now.toIso8601String());
    }

    final steps = (event.steps - _baseStepCount).clamp(0, 100000);
    todayStep = StepModel(userId: userId, date: now, stepCount: steps);
    notifyListeners();
  }

  Future<void> fetchStepFromGoogleFit(DateTime date) async {
    if (!Platform.isAndroid) return;

    final health = Health();
    final types = [HealthDataType.STEPS];

    final start = DateTime(date.year, date.month, date.day);
    final end = DateTime(date.year, date.month, date.day, 23, 59, 59);

    final allowed = await health.requestAuthorization(types);
    if (!allowed) {
      debugPrint('Google Fit 권한 거부됨');
      return;
    }

    final steps = await health.getTotalStepsInInterval(start, end);
    if (steps != null) {
      todayStep = StepModel(userId: userId, date: date, stepCount: steps);
      notifyListeners();
    } else {
      debugPrint('Google Fit 걸음 수 데이터 없음');
    }
  }

  Future<void> updateDailyGoal(int goal) async {
    final prefs = await SharedPreferences.getInstance();
    _dailyGoal = goal;
    await prefs.setInt('${userId}_dailyGoal', goal);
    notifyListeners();
  }

  Future<void> _loadBaseStepInfo() async {
    final prefs = await SharedPreferences.getInstance();
    // 사용자별 저장소 키 사용
    final baseKey = '${userId}_stepBase';
    final dateKey = '${userId}_stepDate';
    
    _baseStepCount = prefs.getInt(baseKey) ?? 0;
    final dateStr = prefs.getString(dateKey);
    _lastDate = dateStr != null ? DateTime.tryParse(dateStr) ?? DateTime.now() : DateTime.now();
  }

  Future<void> _loadDailyGoal() async {
    final prefs = await SharedPreferences.getInstance();
    _dailyGoal = prefs.getInt('${userId}_dailyGoal') ?? 5000;
    notifyListeners();
  }

  Future<void> _requestPermissions() async {
    final status = await Permission.activityRecognition.status;
    if (!status.isGranted) {
      await Permission.activityRecognition.request();
    }
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
