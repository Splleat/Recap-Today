import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:recap_today/repository/auth_repository.dart';
import 'package:recap_today/model/user_model.dart';
import 'package:recap_today/database/database_helper.dart';

class LoginProvider with ChangeNotifier {
  String _userId = '';
  String? _temporaryUserId;
  String _password = '';
  bool _isLoading = false;
  bool _isLoggedIn = false;
  String? _errorMessage;
  User? _currentUser;

  final AuthRepository _authRepository;

  LoginProvider(this._authRepository) {
    _checkLoginStatus();
  }

  Future<void> initTemporaryUserId() async {
    final prefs = await SharedPreferences.getInstance();
    _temporaryUserId = prefs.getString('temp_user_id');

    if (_temporaryUserId == null) {
      _temporaryUserId = _generateTempId();
      await prefs.setString('temp_user_id', _temporaryUserId!);
    }
  }

  String get userId {
    if (_isLoggedIn && _currentUser != null) {
      return _currentUser!.id;
    } else if (_temporaryUserId != null) {
      return _temporaryUserId!;
    } else {
      throw Exception('userId가 초기화되지 않았습니다. initTemporaryUserId()를 먼저 호출해야 합니다.');
    }
  }
  String get password => _password;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _isLoggedIn;
  String? get errorMessage => _errorMessage;
  User? get currentUser => _currentUser;

  String _generateTempId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final rand = UniqueKey().toString().substring(2, 8);
    return 'temp_$timestamp$rand';
  }

  Future<void> _checkLoginStatus() async {
    final token = _authRepository.getToken();
    if (token != null) {
      final isValid = await _authRepository.validateToken();
      _isLoggedIn = isValid;

      if (isValid) {
        _currentUser = await _authRepository.getCurrentUser();
      }
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
      _authRepository.setToken(credential.accessToken);
      _currentUser = credential.user;
      _isLoggedIn = true;

      // ✅ 로그인 후 임시 아이디 데이터 마이그레이션
      await migrateTempDataToRealUser(_currentUser!.id);

      notifyListeners();
      return true;
    } catch (e) {
      _isLoggedIn = false;

      if (e.toString().contains('User not found')) {
        _errorMessage = '존재하지 않는 사용자입니다.';
      } else if (e.toString().contains('Invalid password')) {
        _errorMessage = '비밀번호가 올바르지 않습니다.';
      } else if (e.toString().contains('Network')) {
        _errorMessage = '네트워크 연결을 확인해주세요.';
      } else {
        _errorMessage = '로그인에 실패했습니다. 다시 시도해주세요.';
      }

      notifyListeners();
      return false;
    } finally {
      setLoading(false);
    }
  }

  Future<void> logout() async {
    setLoading(true);
    try {
      await _authRepository.logout();
      _isLoggedIn = false;
      _currentUser = null;
      _errorMessage = null;
    } catch (_) {
      _isLoggedIn = false;
      _currentUser = null;
      _errorMessage = null;
    } finally {
      setLoading(false);
      notifyListeners();
    }
  }

  Future<void> refreshCurrentUser() async {
    if (!_isLoggedIn) return;
    try {
      _currentUser = await _authRepository.getCurrentUser();
      notifyListeners();
    } catch (_) {}
  }

  Future<void> migrateTempDataToRealUser(String realUserId) async {
    final prefs = await SharedPreferences.getInstance();
    final tempUserId = prefs.getString('temp_user_id');

    if (tempUserId == null || tempUserId == realUserId) return;

    final db = await DatabaseHelper().database;

    final tablesToUpdate = [
      'location',
      'checklist',
      'diary',
      'photo',
      'step',
      'app_usage',
    ];

    for (final table in tablesToUpdate) {
      await db.update(
        table,
        {'userId': realUserId},
        where: 'userId = ?',
        whereArgs: [tempUserId],
      );
    }

    // 완료 후 임시 아이디 제거
    await prefs.remove('temp_user_id');
  }
}
