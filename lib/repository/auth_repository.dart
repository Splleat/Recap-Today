import 'package:recap_today/model/user_credential.dart';

abstract interface class AuthRepository {
  /// 로그인
  Future<UserCredential> login(String userId, String password);

  /// 로그아웃
  Future<void> logout();

  /// 회원가입
  Future<UserCredential> register(String userId, String password, String name);

  String? getToken();

  void setToken(String token);

  void clearToken();
}
