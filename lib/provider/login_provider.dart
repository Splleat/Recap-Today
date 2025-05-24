import 'package:flutter/material.dart';

import 'package:recap_today/repository/auth_repository.dart';

class LoginProvider with ChangeNotifier {
  String _userId = '';
  String _password = '';
  bool _isLoading = false;
  bool _isLoggedIn = false;

  String get userId => _userId;
  String get password => _password;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _isLoggedIn;

  final AuthRepository _authRepository;

  LoginProvider(this._authRepository) {
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    final token = _authRepository.getToken();
    _isLoggedIn = token != null;
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

  Future<void> login() async {
    setLoading(true);
    bool loginSuccess = false;
    try {
      final credential = await _authRepository.login(userId, password);
      print(credential);
      _authRepository.setToken(credential.accessToken);
      _isLoggedIn = true;
      loginSuccess = true;
    } catch (e) {
      print('Login failed: $e');
      loginSuccess = false;
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
    } finally {
      setLoading(false);
      notifyListeners();
    }
  }
}
