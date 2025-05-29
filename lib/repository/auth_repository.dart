import 'package:recap_today/model/user_credential.dart';
import 'package:recap_today/model/user_model.dart';

abstract interface class AuthRepository {
  /// 로그인
  Future<UserCredential> login(String userId, String password);

  /// 로그아웃
  Future<void> logout();

  /// 회원가입
  Future<UserCredential> register(String userId, String password, String name);

  /// 토큰 유효성 검증
  Future<bool> validateToken();

  /// 현재 사용자 정보 조회
  Future<User?> getCurrentUser();

  String? getToken();

  void setToken(String token);

  void clearToken();

  /// 현재 로그인된 사용자 ID 반환
  String? getCurrentUserId();
}
