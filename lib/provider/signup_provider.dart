import 'package:flutter/material.dart';
import 'package:recap_today/repository/auth_repository.dart';

class SignupProvider with ChangeNotifier {
  String _username = '';
  String _password = '';
  String _confirmPassword = '';
  String _name = ''; // name 필드 추가
  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;

  String get username => _username;
  String get password => _password;
  String get confirmPassword => _confirmPassword;
  String get name => _name; // name getter 추가
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;

  final AuthRepository _authRepository;

  SignupProvider(this._authRepository);

  void setUsername(String username) {
    _username = username;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
  }

  void setPassword(String password) {
    _password = password;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
  }

  void setConfirmPassword(String confirmPassword) {
    _confirmPassword = confirmPassword;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
  }

  void setName(String name) {
    // setName 메소드 추가
    _name = name;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
  }

  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _clearMessages() {
    _errorMessage = null;
    _successMessage = null;
  }

  Future<bool> signup() async {
    _clearMessages();
    if (password != confirmPassword) {
      _errorMessage = '비밀번호가 일치하지 않습니다.';
      notifyListeners();
      return false;
    }
    if (name.isEmpty) {
      // 이름 필드 검증 추가
      _errorMessage = '이름을 입력해주세요.';
      notifyListeners();
      return false;
    }

    setLoading(true);

    try {
      // await _authRepository.signup(username, password); // 이전 코드
      await _authRepository.register(
        username,
        password,
        name,
      ); // 수정된 코드: register 메소드 사용 및 name 전달
      _successMessage = '회원가입 성공!';
      setLoading(false);
      return true;
    } catch (e) {
      _errorMessage = '회원가입 실패: ${e.toString()}';
      setLoading(false);
      return false;
    }
  }
}
