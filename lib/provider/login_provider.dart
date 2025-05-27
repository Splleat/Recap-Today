import 'package:flutter/material.dart';

import 'package:recap_today/repository/auth_repository.dart';

class LoginProvider with ChangeNotifier {
  String _userId = '';
  String _password = '';
  bool _isLoading = false;
  bool _isLoggedIn = false;
  String? _errorMessage;

  String get userId => _userId;
  String get password => _password;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _isLoggedIn;
  String? get errorMessage => _errorMessage;

  final AuthRepository _authRepository;

  LoginProvider(this._authRepository) {
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    final token = _authRepository.getToken();
    if (token != null) {
      // 토큰이 있으면 유효성 검증
      final isValid = await _authRepository.validateToken();
      _isLoggedIn = isValid;
    } else {
      _isLoggedIn = false;
    }
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
      _isLoggedIn = true;
      _errorMessage = null;
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
      _errorMessage = null;
    } catch (e) {
      print('Logout failed: $e');
      // 로그아웃 실패 시에도 로컬 상태는 초기화
      _isLoggedIn = false;
      _errorMessage = null;
    } finally {
      setLoading(false);
      notifyListeners();
    }
  }
}
