import 'package:dio/dio.dart';

class DioClient {
  static final Dio dio = Dio(
    BaseOptions(
      // baseUrl: 'http://127.0.0.1:3000', // 에뮬레이터면 10.0.2.2
      // baseUrl: 'http://10.0.2.2:3000',
      // baseUrl: 'http://192.168.1.10:80',
      baseUrl: 'http://3.37.238.133:80', // 실제 서버 주소
      connectTimeout: const Duration(seconds: 100),
      receiveTimeout: const Duration(seconds: 100),
      contentType: 'application/json',
    ),
  );
}
