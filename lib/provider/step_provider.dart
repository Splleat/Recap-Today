import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:pedometer/pedometer.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:health/health.dart';
import 'package:recap_today/model/freezed/step_model.dart';
import 'package:recap_today/data/database_helper.dart';  // 추가: DatabaseHelper import
import 'package:recap_today/provider/login_provider.dart'; // 추가: LoginProvider import

class StepProvider with ChangeNotifier {
  late StepModel todayStep;
  int _baseStepCount = 0;
  int _dailyGoal = 5000;
  DateTime _lastDate = DateTime.now();
  StreamSubscription<StepCount>? _subscription;
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;  // 추가: DatabaseHelper 인스턴스
  bool _isDisposed = false; // 추가: Provider의 disposed 상태를 추적하는 플래그
  final LoginProvider _loginProvider; // 추가: LoginProvider 인스턴스

  // 생성자에서 LoginProvider 주입받기
  StepProvider({required LoginProvider loginProvider}) 
      : _loginProvider = loginProvider {
    todayStep = StepModel(userId: _loginProvider.activeUserId, date: DateTime.now(), stepCount: 0);
  }
  
  // userId getter를 LoginProvider에서 가져오도록 수정
  String get userId => _loginProvider.activeUserId;

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
    final today = DateTime.now();
    final todayFormatted = _formatDate(today);
    
    // 데이터베이스에서 오늘 걸음 데이터 로드
    final storedSteps = await _dbHelper.getStepsByDate(todayFormatted, userId);
    if (storedSteps != null) {
      todayStep = storedSteps;
    } else {
      todayStep = StepModel(userId: userId, date: today, stepCount: 0);
    }
    
    if (!status.isGranted) {
      final result = await Permission.activityRecognition.request();
      if (!result.isGranted) {
        debugPrint('활동 인식 권한이 거부되었습니다.');
        return;
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
    if (_isDisposed) return; // 추가: disposed 상태 확인
    
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();

    // 사용자별 저장소 키 사용
    final baseKey = '${userId}_stepBase';
    final dateKey = '${userId}_stepDate';

    // 새 날짜이거나 초기화된 경우
    bool isNewDay = !_isSameDay(_lastDate, now) || _baseStepCount == 0;
    
    if (isNewDay) {
      _baseStepCount = event.steps;
      _lastDate = now;
      await prefs.setInt(baseKey, _baseStepCount);
      await prefs.setString(dateKey, now.toIso8601String());
      // 새 날짜에는 저장
      await _saveStepsToDatabase(StepModel(userId: userId, date: now, stepCount: 0));
    }

    final steps = (event.steps - _baseStepCount).clamp(0, 100000);
    todayStep = StepModel(userId: userId, date: now, stepCount: steps);
    
    // 걸음 수 데이터 저장은 다음 경우에만 수행:
    // 1. 날짜가 변경된 경우 (위에서 처리)
    // 2. 매 100번째 걸음마다
    // 3. dispose() 메서드에서 앱 종료 시
    if (steps % 100 == 0) {
      await _saveStepsToDatabase(todayStep);
    }
    
    notifyListeners();
  }

  // 걸음 수 데이터를 데이터베이스에 저장하는 메서드
  Future<void> _saveStepsToDatabase(StepModel steps) async {
    try {
      await _dbHelper.insertStepCount(steps);
    } catch (e) {
      debugPrint('걸음 수 데이터 저장 중 오류 발생: $e');
    }
  }

  Future<void> fetchStepFromGoogleFit(DateTime date) async {
    if (_isDisposed) return; // 추가: disposed 상태 확인
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
      final stepModel = StepModel(userId: userId, date: date, stepCount: steps);
      todayStep = stepModel;
      
      // Google Fit에서 가져온 걸음 수도 데이터베이스에 저장
      await _saveStepsToDatabase(stepModel);
      
      notifyListeners();
    } else {
      // 데이터베이스에서 해당 날짜의 걸음 수 데이터를 로드
      final dateFormatted = _formatDate(date);
      final storedSteps = await _dbHelper.getStepsByDate(dateFormatted, userId);
      
      if (storedSteps != null) {
        todayStep = storedSteps;
        notifyListeners();
      } else {
        debugPrint('Google Fit 걸음 수 데이터 없음');
      }
    }
  }

  // 특정 날짜의 걸음 수 데이터 로드
  Future<StepModel?> loadStepsForDate(DateTime date) async {
    final dateFormatted = _formatDate(date);
    return await _dbHelper.getStepsByDate(dateFormatted, userId);
  }

  // 날짜를 yyyy-MM-dd 형식의 문자열로 변환
  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  Future<void> updateDailyGoal(int goal) async {
    if (_isDisposed) return; // 추가: disposed 상태 확인
    
    final prefs = await SharedPreferences.getInstance();
    _dailyGoal = goal;
    await prefs.setInt('${userId}_dailyGoal', goal);
    if (!_isDisposed) notifyListeners(); // 추가: 다시 한번 확인
  }

  Future<void> _loadBaseStepInfo() async {
    if (_isDisposed) return; // 추가: disposed 상태 확인
    
    final prefs = await SharedPreferences.getInstance();
    // 사용자별 저장소 키 사용
    final baseKey = '${userId}_stepBase';
    final dateKey = '${userId}_stepDate';
    
    _baseStepCount = prefs.getInt(baseKey) ?? 0;
    final dateStr = prefs.getString(dateKey);
    _lastDate = dateStr != null ? DateTime.tryParse(dateStr) ?? DateTime.now() : DateTime.now();
  }

  Future<void> _loadDailyGoal() async {
    if (_isDisposed) return; // 추가: disposed 상태 확인
    
    final prefs = await SharedPreferences.getInstance();
    _dailyGoal = prefs.getInt('${userId}_dailyGoal') ?? 5000;
    if (!_isDisposed) notifyListeners(); // 추가: 다시 한번 확인
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
    _isDisposed = true; // 추가: 먼저 disposed 상태로 설정
    
    // 앱 종료 또는 provider 종료 시 마지막 걸음 수 저장
    if (todayStep.stepCount > 0) {
      _saveStepsToDatabase(todayStep);
    }
    _subscription?.cancel();
    super.dispose();
  }
}
