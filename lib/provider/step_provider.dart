import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:pedometer/pedometer.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:health/health.dart';
import 'package:recap_today/model/step_model.dart';
import 'package:recap_today/repository/auth_repository.dart';
import 'package:provider/provider.dart';

class StepProvider with ChangeNotifier {
  String? userId; 
  StepModel? todayStep;
  int get debugBaseStepCount => _baseStepCount;
  DateTime get debugLastDate => _lastDate;
  int _baseStepCount = 0;
  int _dailyGoal = 5000;
  DateTime _lastDate = DateTime.now();
  StreamSubscription<StepCount>? _subscription;

  int get dailyGoal => _dailyGoal;

  Future<void> initialize(BuildContext context) async {
    final authRepo = context.read<AuthRepository>();
    userId = authRepo.getCurrentUserId();

    final status = await Permission.activityRecognition.status;

    if (!status.isGranted) {
      final result = await Permission.activityRecognition.request();
      if (!result.isGranted) {
        throw Exception('활동 인식 권한이 필요합니다.');
      }
    }

    await _loadBaseStepInfo();
    await _loadDailyGoal();

    _subscription = Pedometer.stepCountStream.listen(
      _onStepCount,
      onError: (e) => debugPrint('걸음 수 오류: $e'),
      cancelOnError: true,
    );
  }

  void _onStepCount(StepCount event) async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();

    // userId가 없으면 기록하지 않음.
    if (userId == null) {
      debugPrint('사용자 ID가 없습니다. 걸음 수 기록을 중단합니다.');
      return;
    }

    if (!_isSameDay(_lastDate, now) || _baseStepCount == 0) {
      _baseStepCount = event.steps;
      _lastDate = now;
      await prefs.setInt('stepBase', _baseStepCount);
      await prefs.setString('stepDate', now.toIso8601String());
    }

    final steps = (event.steps - _baseStepCount).clamp(0, 100000);
    todayStep = StepModel(userId: userId!, date: now, stepCount: steps);
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
      todayStep = StepModel(userId: userId!, date: date, stepCount: steps);
      notifyListeners();
    } else {
      debugPrint('Google Fit 걸음 수 데이터 없음');
    }
  }

  Future<void> updateDailyGoal(int goal) async {
    final prefs = await SharedPreferences.getInstance();
    _dailyGoal = goal;
    await prefs.setInt('dailyGoal', goal);
    notifyListeners();
  }

  Future<void> _loadBaseStepInfo() async {
    final prefs = await SharedPreferences.getInstance();
    _baseStepCount = prefs.getInt('stepBase') ?? 0;
    final dateStr = prefs.getString('stepDate');
    _lastDate = dateStr != null ? DateTime.tryParse(dateStr) ?? DateTime.now() : DateTime.now();
  }

  Future<void> _loadDailyGoal() async {
    final prefs = await SharedPreferences.getInstance();
    _dailyGoal = prefs.getInt('dailyGoal') ?? 5000;
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
