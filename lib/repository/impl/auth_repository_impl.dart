import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';

import 'package:recap_today/model/user_credential.dart';
import 'package:recap_today/model/user_model.dart';
import 'package:recap_today/repository/auth_repository.dart';
import 'package:recap_today/api/location_service.dart';

final class AuthRepositoryImpl implements AuthRepository {
  final Dio dio;
  final SharedPreferences sharedPreferences;
  final LocationService? _locationService;

  late String? _token = sharedPreferences.getString('token');

  AuthRepositoryImpl(this.dio, this.sharedPreferences, [this._locationService]);

  @override
  Future<UserCredential> login(String userId, String password) async {
    final response = await dio.post(
      '/auth/login',
      data: {'userId': userId, 'password': password},
    );

    final userCredential = UserCredential.fromJson(response.data);

    // 로그인 성공 시 토큰 저장
    setToken(userCredential.accessToken);

    // 로컬 사용자 데이터 마이그레이션 실행
    if (_locationService != null) {
      _migrateLocalDataInBackground(userId);
    }

    return userCredential;
  }

  /// 백그라운드에서 로컬 사용자 데이터를 실제 사용자로 마이그레이션
  Future<void> _migrateLocalDataInBackground(String realUserId) async {
    try {
      final locationService = _locationService;
      if (locationService == null) return;

      // 로컬 데이터 존재 여부 확인
      final hasLocalData = await locationService.hasLocalUserData();
      if (!hasLocalData) {
        developer.log('마이그레이션할 로컬 데이터가 없습니다.', name: 'AuthRepository');
        return;
      }

      developer.log(
        '로그인 후 로컬 데이터 마이그레이션 시작: $realUserId',
        name: 'AuthRepository',
      );

      // 백그라운드에서 마이그레이션 실행
      final success = await locationService.migrateLocalUserDataToRealUser(
        realUserId,
      );

      if (success) {
        developer.log('로컬 데이터 마이그레이션 완료', name: 'AuthRepository');
      } else {
        developer.log('로컬 데이터 마이그레이션 실패', name: 'AuthRepository');
      }
    } catch (e) {
      developer.log('마이그레이션 중 오류 발생: $e', name: 'AuthRepository');
    }
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
        debugPrint('서버 로그아웃 실패: $e');
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

  @override
  Future<bool> validateToken() async {
    if (_token == null) return false;

    try {
      // 서버에 토큰 유효성 검증 요청
      final response = await dio.get(
        '/auth/validate',
        options: Options(headers: {'Authorization': 'Bearer $_token'}),
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('토큰 유효성 검증 실패: $e');
      // 토큰이 유효하지 않으면 로컬에서 제거
      clearToken();
      return false;
    }
  }

  @override
  String? getCurrentUserId() {
    if (_token == null) return null;

    try {
      // JWT 토큰을 '.'으로 분리
      final parts = _token!.split('.');
      if (parts.length != 3) return null;

      // 페이로드 부분을 디코딩
      final payload = parts[1];
      // Base64Url 디코딩을 위해 패딩 추가
      final normalized = payload.padRight((payload.length + 3) ~/ 4 * 4, '=');
      final decoded = utf8.decode(base64Url.decode(normalized));
      final Map<String, dynamic> data = json.decode(decoded);

      // 'sub' 필드에서 사용자 ID 추출 (JWT 표준)
      return data['sub']?.toString();
    } catch (e) {
      debugPrint('JWT 토큰 디코딩 실패: $e');
      return null;
    }
  }

  @override
  Future<User?> getCurrentUser() async {
    if (_token == null) return null;

    try {
      final response = await dio.get(
        '/auth/me',
        options: Options(headers: {'Authorization': 'Bearer $_token'}),
      );
      return User.fromJson(response.data);
    } catch (e) {
      debugPrint('현재 사용자 정보 조회 실패: $e');
      return null;
    }
  }
}
