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
  Future<void> logout() {
    // 로그아웃 로직 구현
    // 예를 들어, 토큰 삭제 등
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
