import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:recap_today/model/freezed/ai_feedback_model.dart';
import 'package:recap_today/data/sqflite_database.dart';
import 'package:recap_today/data/database_helper.dart';
import 'package:uuid/uuid.dart';
import 'dart:collection';
import 'package:recap_today/provider/login_provider.dart';
import 'dart:async';

/// AI 피드백 관련 상태 관리 및 데이터 접근을 위한 Provider 클래스
class AiFeedbackProvider with ChangeNotifier {
  bool _isLoading = false;
  List<AiFeedbackModel> _feedbacks = [];
  AiFeedbackModel? _currentFeedback;
  final SqfliteDatabase _database = SqfliteDatabase();

  final LoginProvider _loginProvider;

  // 생성자에서 LoginProvider 주입받기
  AiFeedbackProvider({required LoginProvider loginProvider})
    : _loginProvider = loginProvider {
    // defer initial load to next event loop to avoid calling notifyListeners during build
    Future.delayed(Duration.zero, () {
      _loadItems();
    });
  }

  // userId getter를 LoginProvider에서 가져오도록 수정
  String get userId => _loginProvider.activeUserId;

  // 게터
  bool get isLoading => _isLoading;
  UnmodifiableListView<AiFeedbackModel> get feedbacks =>
      UnmodifiableListView(_feedbacks);
  AiFeedbackModel? get currentFeedback => _currentFeedback;

  // 데이터베이스에서 항목 로드
  Future<void> _loadItems() async {
    try {
      _setLoading(true);
      _feedbacks = await _database.getAllAiFeedback(userId);
      debugPrint('AI 피드백 ${_feedbacks.length}개 로드 완료');
    } catch (e) {
      debugPrint('AI 피드백 초기 로드 중 오류 발생: $e');
    } finally {
      _setLoading(false);
    }
  }

  // 로딩 상태 설정
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // 현재 피드백 설정
  void setCurrentFeedback(AiFeedbackModel? feedback) {
    _currentFeedback = feedback;
    notifyListeners();
  }

  // 모든 AI 피드백 로드
  Future<void> loadAllFeedbacks() async {
    try {
      _setLoading(true);
      _feedbacks = await _database.getAllAiFeedback(userId);
    } catch (e) {
      debugPrint('모든 AI 피드백 로드 중 오류 발생: $e');
    } finally {
      _setLoading(false);
    }
  }

  // 특정 날짜의 AI 피드백 로드
  Future<List<AiFeedbackModel>> loadFeedbacksByDate(String date) async {
    try {
      _setLoading(true);
      final feedbacks = await _database.getAiFeedbackByDate(date, userId);
      return feedbacks;
    } catch (e) {
      debugPrint('날짜별 AI 피드백 로드 중 오류 발생: $e');
      return [];
    } finally {
      _setLoading(false);
    }
  }

  // 특정 ID의 AI 피드백 로드
  Future<AiFeedbackModel?> loadFeedbackById(int id) async {
    try {
      _setLoading(true);
      final feedback = await _database.getAiFeedbackById(id, userId);
      return feedback;
    } catch (e) {
      debugPrint('ID별 AI 피드백 로드 중 오류 발생: $e');
      return null;
    } finally {
      _setLoading(false);
    }
  }

  // AI 피드백 추가
  Future<bool> addFeedback(String date, String feedbackText) async {
    try {
      final feedback = AiFeedbackModel(
        date: date,
        feedback_text: feedbackText,
        userId: userId,
      );

      final id = await _database.insertAiFeedback(feedback);
      if (id > 0) {
        // 로컬 상태 업데이트 (ID 포함)
        final newFeedback = feedback.copyWith(id: id);
        _feedbacks.add(newFeedback);
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('AI 피드백 추가 중 오류 발생: $e');
      return false;
    }
  }

  // AI 피드백 업데이트
  Future<bool> updateFeedback(AiFeedbackModel feedback) async {
    try {
      final result = await _database.updateAiFeedback(feedback);
      if (result > 0) {
        // 로컬 상태 업데이트
        final index = _feedbacks.indexWhere((f) => f.id == feedback.id);
        if (index != -1) {
          _feedbacks[index] = feedback;
          notifyListeners();
        }
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('AI 피드백 업데이트 중 오류 발생: $e');
      return false;
    }
  }

  // AI 피드백 삭제
  Future<bool> deleteFeedback(int id) async {
    try {
      final result = await _database.deleteAiFeedback(id, userId);
      if (result > 0) {
        // 로컬 상태 업데이트
        _feedbacks.removeWhere((feedback) => feedback.id == id);
        // 현재 선택된 피드백이 삭제되었다면 null로 설정
        if (_currentFeedback?.id == id) {
          _currentFeedback = null;
        }
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('AI 피드백 삭제 중 오류 발생: $e');
      return false;
    }
  }

  // 날짜별 AI 피드백 가져오기 (메모리/캐시 우선 확인 후 DB 조회)
  Future<List<AiFeedbackModel>> getFeedbacksByDate(String date) async {
    // 먼저 메모리에서 해당 날짜의 피드백을 찾음
    final cachedFeedbacks = _feedbacks.where((f) => f.date == date).toList();

    // 이미 메모리에 있으면 바로 반환
    if (cachedFeedbacks.isNotEmpty) {
      return cachedFeedbacks;
    }

    // 없으면 DB에서 로드
    return await loadFeedbacksByDate(date);
  }

  // 앱 초기화 시 기본 데이터 로드
  Future<void> initializeData() async {
    await loadAllFeedbacks();
  }
}
