import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:recap_today/model/user_credential.dart';
import 'package:recap_today/repository/auth_repository.dart';

final class AuthRepositoryImpl implements AuthRepository {
  final Dio dio;
  final SharedPreferences sharedPreferences;

  late String? _token = sharedPreferences.getString('token');

  AuthRepositoryImpl(this.dio, this.sharedPreferences);

  @override
  Future<UserCredential> login(String userId, String password) async {
    final response = await dio.post(
      '/auth/login',
      data: {'userId': userId, 'password': password},
    );
    return UserCredential.fromJson(response.data);
  }

  @override
  Future<void> logout() async {
    // 로그아웃 로직 구현
    // 예를 들어, 토큰 삭제 등
    // 서버에 로그아웃 요청을 보낼 수도 있습니다.
    if (_token != null) {
      try {
        await dio.post('/auth/logout', data: {'token': _token});
      } catch (e) {
        // 서버 로그아웃 실패 시 에러 처리 (예: 로깅)
        // 클라이언트 측에서는 토큰을 어쨌든 삭제하므로, 여기서 특별한 사용자 알림은 필요 없을 수 있음
        print('Server logout failed: $e');
      }
    }
    clearToken(); // 토큰 삭제
    // 추가적인 로컬 상태 초기화 로직이 필요하다면 여기에 추가합니다.
    return Future.value();
  }

  @override
  Future<UserCredential> register(
    String userId,
    String password,
    String name,
  ) async {
    final response = await dio.post(
      '/auth/register',
      data: {'userId': userId, 'password': password, 'name': name},
    );
    return UserCredential.fromJson(response.data);
  }

  @override
  String? getToken() {
    return _token;
  }

  @override
  void setToken(String token) {
    _token = token;
    sharedPreferences.setString('token', token);
  }

  @override
  void clearToken() {
    _token = null;
    sharedPreferences.remove('token');
  }
}
