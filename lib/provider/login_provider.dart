import 'package:flutter/material.dart';

import 'package:recap_today/repository/auth_repository.dart';

class LoginProvider with ChangeNotifier {
  String _userId = '';
  String _password = '';
  bool _isLoading = false;

  String get userId => _userId;
  String get password => _password;
  bool get isLoading => _isLoading;

  final AuthRepository _authRepository;

  LoginProvider(this._authRepository);

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

    try {
      final credential = await _authRepository.login(userId, password);
      print(credential);
    } finally {
      setLoading(false);
    }
  }
}
