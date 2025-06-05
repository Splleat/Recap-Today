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

  // 토큰 확인 디버깅 코드
  void debugCheckToken();

  String? getToken();

  void setToken(String token);

  void clearToken();

  /// 현재 로그인된 사용자 ID 반환
  String? getCurrentUserId();

  /// 사용자 이름 업데이트
  Future<User> updateUserName(String name);

  /// 사용자 프로필 업데이트 (이름과 비밀번호)
  Future<User> updateUserProfile({
    required String name,
    required String currentPassword,
    required String newPassword,
  });
}
