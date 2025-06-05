import 'package:flutter/material.dart';
import 'package:recap_today/data/database_helper.dart';

import 'package:recap_today/repository/auth_repository.dart';
import 'package:recap_today/model/user_model.dart';

class LoginProvider with ChangeNotifier {
  String _userId = '';
  String _password = '';
  bool _isLoading = false;
  bool _isLoggedIn = false;
  String? _errorMessage;
  User? _currentUser;

  String get userId => _userId;
  String get password => _password;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _isLoggedIn;
  String? get errorMessage => _errorMessage;
  User? get currentUser => _currentUser;
  String get activeUserId => _currentUser?.id ?? DatabaseHelper.LOCAL_USER_ID;


  final AuthRepository _authRepository;

  LoginProvider(this._authRepository) {
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    debugPrint('로그인 상태 확인 시작');
    final token = _authRepository.getToken();
    debugPrint('저장된 토큰: ${token != null ? '있음' : '없음'}');
    
    if (token != null) {
      try {
        _currentUser = await _authRepository.getCurrentUser();
        if (_currentUser != null) {
          debugPrint('사용자 정보 로드 성공: ${_currentUser!.name}');
        } else {
          debugPrint('사용자 정보가 null로 반환됨');
        }
        _isLoggedIn = true;
      } catch (e) {
        debugPrint('사용자 정보 로드 중 오류 발생: $e');
        // 오류가 발생해도 토큰이 있으면 로그인 상태 유지
        _isLoggedIn = true;
      }
    } else {
      _isLoggedIn = false;
    }
    
    debugPrint('로그인 상태 확인 완료: $_isLoggedIn');
    notifyListeners();
  }

  void setUserId(String id) {
    _userId = id;
    notifyListeners();
  }

  void setPassword(String password) {
    _password = password;
    notifyListeners();
  }

  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  Future<bool> login() async {
    setLoading(true);
    _errorMessage = null;

    try {
      final credential = await _authRepository.login(userId, password);
      print(credential);
      _authRepository.setToken(credential.accessToken);
      _currentUser = credential.user; // 사용자 정보 저장
      _isLoggedIn = true;
      _errorMessage = null;

      if (_currentUser != null) {
        await DatabaseHelper.instance.migrateLocalDataToUser(_currentUser!.id);
        debugPrint('로컬 데이터 마이그레이션 성공: ${_currentUser!.id}');
      }

      _authRepository.debugCheckToken();

      return true;
    } catch (e) {
      print('Login failed: $e');
      _isLoggedIn = false;

      // 에러 타입에 따른 구체적인 메시지 설정
      if (e.toString().contains('User not found')) {
        _errorMessage = '존재하지 않는 사용자입니다.';
      } else if (e.toString().contains('Invalid password')) {
        _errorMessage = '비밀번호가 올바르지 않습니다.';
      } else if (e.toString().contains('Network')) {
        _errorMessage = '네트워크 연결을 확인해주세요.';
      } else {
        _errorMessage = '로그인에 실패했습니다. 다시 시도해주세요.';
      }

      return false;
    } finally {
      setLoading(false);
      notifyListeners();
    }
  }

  Future<void> logout() async {
    setLoading(true);
    try {
      await _authRepository.logout();
      _isLoggedIn = false;
      _currentUser = null; // 사용자 정보 초기화
      _errorMessage = null;
    } catch (e) {
      print('Logout failed: $e');
      // 로그아웃 실패 시에도 로컬 상태는 초기화
      _isLoggedIn = false;
      _currentUser = null; // 사용자 정보 초기화
      _errorMessage = null;
    } finally {
      setLoading(false);
      notifyListeners();
    }
  }

  /// 현재 사용자 정보를 새로고침
  Future<void> refreshCurrentUser() async {
    if (!_isLoggedIn) {
      return;
    }

    try {
      _currentUser = await _authRepository.getCurrentUser();
      notifyListeners();
    } catch (e) {
      print('Failed to refresh user info: $e');
    }
  }

  String? get authToken => _authRepository.getToken();
}
