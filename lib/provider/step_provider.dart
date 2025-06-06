import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:pedometer/pedometer.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:health/health.dart';
import 'package:recap_today/model/freezed/step_model.dart';
import 'package:recap_today/data/database_helper.dart';
import 'package:recap_today/provider/login_provider.dart';

class StepProvider with ChangeNotifier {
  late StepModel todayStep;
  int _baseStepCount = 0;
  int _dailyGoal = 5000;
  DateTime _lastDate = DateTime.now();
  StreamSubscription<StepCount>? _subscription;
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  bool _isDisposed = false;
  final LoginProvider _loginProvider;

  StepProvider({required LoginProvider loginProvider}) 
      : _loginProvider = loginProvider {
    // todayStep 초기화 시 String 날짜 사용
    final today = DateTime.now();
    final formattedDate = _formatDate(today);
    todayStep = StepModel(userId: _loginProvider.activeUserId, date: formattedDate, stepCount: 0);
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
    // String 날짜 사용
    final formattedDate = _formatDate(DateTime.now());
    todayStep = StepModel(userId: userId, date: formattedDate, stepCount: 0);
    _baseStepCount = 0;
  }

  Future<void> initialize() async {
    debugPrint('🔄 StepProvider 초기화 시작');
    
    final status = await Permission.activityRecognition.status;
    final today = DateTime.now();
    final todayFormatted = _formatDate(today);
    
    // 데이터베이스에서 오늘 걸음 데이터 로드
    final storedSteps = await _dbHelper.getStepsByDate(todayFormatted, userId);
    if (storedSteps != null) {
      todayStep = storedSteps;
    } else {
      todayStep = StepModel(userId: userId, date: todayFormatted, stepCount: 0);
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
    
    debugPrint('🎧 Pedometer 이벤트 리스너 설정 중...');
    _subscription = Pedometer.stepCountStream.listen(
      (event) {
        debugPrint('👣 Pedometer 이벤트 발생: ${event.steps} 걸음');
        _onStepCount(event);
      },
      onError: (e) {
        debugPrint('❌ Pedometer 오류: $e');
        // 오류 발생 시 재시도 로직 추가 가능
      },
      cancelOnError: false, // 오류가 발생해도 구독 유지
    );
    
    debugPrint('✅ StepProvider 초기화 완료');
  }

  void _onStepCount(StepCount event) async {
    if (_isDisposed) return; // 추가: disposed 상태 확인
    
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final formattedDate = _formatDate(now);

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
      // 새 날짜에는 저장 - String 날짜 사용
      await _saveStepsToDatabase(StepModel(userId: userId, date: formattedDate, stepCount: 0));
    }

    final steps = (event.steps - _baseStepCount).clamp(0, 100000);
    todayStep = StepModel(userId: userId, date: formattedDate, stepCount: steps);
    
    // 걸음 수 데이터 저장은 다음 경우에만 수행:
    // 1. 날짜가 변경된 경우 (위에서 처리)
    // 2. 매 33번째 걸음마다
    // 3. dispose() 메서드에서 앱 종료 시
    if (steps % 33 == 0) {
      await _saveStepsToDatabase(todayStep);
    }
    
    notifyListeners();
  }

  // 걸음 수 데이터를 데이터베이스에 저장하는 메서드
  Future<void> _saveStepsToDatabase(StepModel steps) async {
    try {
      debugPrint('💾 걸음 수 저장 시도: ${steps.stepCount}, 날짜: ${steps.date}');
      await _dbHelper.insertStepCount(steps);
      debugPrint('✅ 걸음 수 저장 성공: ${steps.date} ${steps.stepCount}');
    } catch (e) {
      debugPrint('❌ 걸음 수 데이터 저장 중 오류 발생: $e');
    }
  }

  // 특정 날짜의 걸음 수 데이터 로드
  Future<StepModel?> loadStepsForDate(DateTime date) async {
    final dateFormatted = _formatDate(date);
    debugPrint('🔍 걸음 수 데이터베이스 로드 시도: $dateFormatted, 사용자: $userId');
    
    // 데이터베이스 호출 전에 현재 todayStep 상태 확인
    debugPrint('📱 현재 메모리의 todayStep: ${todayStep.stepCount}');
    
    final result = await _dbHelper.getStepsByDate(dateFormatted, userId);
    
    if (result != null) {
      debugPrint('📊 데이터베이스에서 로드된 걸음 수: ${result.date} ${result.stepCount}');
    } else {
      debugPrint('📭 데이터베이스에 해당 날짜의 걸음 수 없음');
    }
    
    return result;
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
