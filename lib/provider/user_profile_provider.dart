import 'package:flutter/material.dart';
import 'package:recap_today/repository/auth_repository.dart';
import 'package:recap_today/model/user_model.dart';
import 'package:recap_today/provider/login_provider.dart';

class UserProfileProvider with ChangeNotifier {
  String _name = '';
  String _currentPassword = '';
  String _newPassword = '';
  String _confirmPassword = '';
  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;

  String get name => _name;
  String get currentPassword => _currentPassword;
  String get newPassword => _newPassword;
  String get confirmPassword => _confirmPassword;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;
  final AuthRepository _authRepository;
  final LoginProvider? _loginProvider;

  UserProfileProvider(this._authRepository, [this._loginProvider]);

  void setName(String name) {
    _name = name;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
  }

  void setCurrentPassword(String password) {
    _currentPassword = password;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
  }

  void setNewPassword(String password) {
    _newPassword = password;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
  }

  void setConfirmPassword(String password) {
    _confirmPassword = password;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
  }

  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void clearMessages() {
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
  }

  void initializeWithCurrentUser(User? user) {
    if (user != null) {
      _name = user.name;
      notifyListeners();
    }
  }

  bool _validateInput() {
    if (_name.trim().isEmpty) {
      _errorMessage = '닉네임을 입력해주세요.';
      return false;
    }

    if (_name.trim().length < 2) {
      _errorMessage = '닉네임은 2자 이상이어야 합니다.';
      return false;
    }

    // 비밀번호 변경을 시도하는 경우
    if (_newPassword.isNotEmpty ||
        _confirmPassword.isNotEmpty ||
        _currentPassword.isNotEmpty) {
      if (_currentPassword.isEmpty) {
        _errorMessage = '현재 비밀번호를 입력해주세요.';
        return false;
      }

      if (_newPassword.isEmpty) {
        _errorMessage = '새 비밀번호를 입력해주세요.';
        return false;
      }

      if (_newPassword.length < 6) {
        _errorMessage = '새 비밀번호는 6자 이상이어야 합니다.';
        return false;
      }

      if (_newPassword != _confirmPassword) {
        _errorMessage = '새 비밀번호가 일치하지 않습니다.';
        return false;
      }

      if (_currentPassword == _newPassword) {
        _errorMessage = '새 비밀번호는 현재 비밀번호와 달라야 합니다.';
        return false;
      }
    }

    return true;
  }

  Future<bool> updateProfile() async {
    if (!_validateInput()) {
      notifyListeners();
      return false;
    }

    setLoading(true);
    _errorMessage = null;
    _successMessage = null;

    try {
      // 이름만 변경하는 경우
      if (_newPassword.isEmpty) {
        await _authRepository.updateUserName(_name.trim());
        _successMessage = '프로필이 성공적으로 업데이트되었습니다.';
      } else {
        // 이름과 비밀번호 모두 변경하는 경우
        await _authRepository.updateUserProfile(
          name: _name.trim(),
          currentPassword: _currentPassword,
          newPassword: _newPassword,
        );
        _successMessage = '프로필과 비밀번호가 성공적으로 업데이트되었습니다.';

        // 비밀번호 필드 초기화
        _currentPassword = '';
        _newPassword = '';
        _confirmPassword = '';
      }

      // LoginProvider의 사용자 정보 새로고침
      _loginProvider?.refreshCurrentUser();

      setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      print('Profile update failed: $e');

      // 에러 타입에 따른 구체적인 메시지 설정
      if (e.toString().contains('Invalid password')) {
        _errorMessage = '현재 비밀번호가 올바르지 않습니다.';
      } else if (e.toString().contains('Network')) {
        _errorMessage = '네트워크 연결을 확인해주세요.';
      } else if (e.toString().contains('Username already exists')) {
        _errorMessage = '이미 사용 중인 닉네임입니다.';
      } else {
        _errorMessage = '프로필 업데이트에 실패했습니다. 다시 시도해주세요.';
      }

      setLoading(false);
      notifyListeners();
      return false;
    }
  }

  void reset() {
    _name = '';
    _currentPassword = '';
    _newPassword = '';
    _confirmPassword = '';
    _isLoading = false;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
  }
}
