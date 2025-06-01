import 'package:dio/dio.dart';

class ApiService {
  final Dio _dio;
  // TODO: Make baseUrl configurable (e.g., via environment variables or settings)
  static const String _baseUrl = 'http://localhost:3000/api';

  ApiService(Dio? dio) : _dio = dio ?? Dio(BaseOptions(baseUrl: _baseUrl)) {
    _dio.interceptors.add(
      LogInterceptor(responseBody: true, requestBody: true),
    );
    // TODO: Implement and add a proper AuthInterceptor
    // _dio.interceptors.add(AuthInterceptor(_dio));
  }

  Future<Options> _getAuthOptions(Options? options) async {
    // TODO: Replace with actual secure token retrieval logic
    String? token = "YOUR_JWT_TOKEN_PLACEHOLDER"; // Placeholder

    final authOptions = options ?? Options();
    authOptions.headers =
        authOptions.headers ?? {}; // Initialize headers if null

    // if (token != null && token.isNotEmpty) { // Temporarily commented out due to linting issue
    authOptions.headers!['Authorization'] = 'Bearer $token';
    // }
    return authOptions;
  }

  Future<Map<String, dynamic>> syncDiaries(
    List<Map<String, dynamic>> diaries, {
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await _dio.post(
        '/sync/diaries', // This endpoint likely expects a list of diaries
        data: {'diaries': diaries},
        cancelToken: cancelToken,
        options: await _getAuthOptions(null),
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      print('ApiService: DioError syncing diaries: ${e.message}');
      throw Exception(
        'Network error while syncing diaries: ${e.response?.statusCode} - ${e.message}',
      );
    } catch (e) {
      print('ApiService: Generic error syncing diaries: $e');
      throw Exception('Failed to sync diaries: $e');
    }
  }

  // New method for the combined payload from SyncService.syncAllData
  Future<Map<String, dynamic>> syncMainPayload(
    Map<String, dynamic> payload, {
    CancelToken? cancelToken,
  }) async {
    try {
      // This assumes the '/sync/diaries' endpoint can also handle this broader payload,
      // or there's another endpoint like '/sync/all'. For now, using '/sync/diaries'
      // as a placeholder for where syncAllData was pointing.
      // This might need a dedicated backend endpoint.
      final response = await _dio.post(
        '/sync/diaries', // Or a more appropriate endpoint like '/sync/main' or '/sync/all'
        data: payload,
        cancelToken: cancelToken,
        options: await _getAuthOptions(null),
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      print('ApiService: DioError syncing main payload: ${e.message}');
      throw Exception(
        'Network error while syncing main payload: ${e.response?.statusCode} - ${e.message}',
      );    } catch (e) {
      print('ApiService: Generic error syncing main payload: $e');
      throw Exception('Failed to sync main payload: $e');
    }
  }

  Future<Map<String, dynamic>> syncDiariesAndPhotos({
    required List<Map<String, dynamic>> diaryChanges,
    required List<Map<String, dynamic>> standalonePhotoChanges,
    String? lastDiarySyncTime,
    String? lastPhotoSyncTime,
    CancelToken? cancelToken,
  }) async {
    try {
      final payload = {
        'diaryChanges': diaryChanges,
        'standalonePhotoChanges': standalonePhotoChanges,
        'lastDiarySyncTime': lastDiarySyncTime,
        'lastPhotoSyncTime': lastPhotoSyncTime,
      };
      
      final response = await _dio.post(
        '/sync/diaries-photos',
        data: payload,
        cancelToken: cancelToken,
        options: await _getAuthOptions(null),
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      print('ApiService: DioError syncing diaries and photos: ${e.message}');
      throw Exception(
        'Network error while syncing diaries and photos: ${e.response?.statusCode} - ${e.message}',
      );
    } catch (e) {
      print('ApiService: Generic error syncing diaries and photos: $e');
      throw Exception('Failed to sync diaries and photos: $e');
    }
  }

  Future<Map<String, dynamic>> syncPhotos(
    List<Map<String, dynamic>> photos, {
    CancelToken? cancelToken,
  }) async {
    try {
      // TODO: Implement proper FormData construction if sending files for photos.
      // For now, sending as JSON like diaries.
      final response = await _dio.post(
        '/sync/photos',
        data: {'photos': photos},
        cancelToken: cancelToken,
        options: await _getAuthOptions(null),
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      print('ApiService: DioError syncing photos: ${e.message}');
      throw Exception(
        'Network error while syncing photos: ${e.response?.statusCode} - ${e.message}',
      );
    } catch (e) {
      print('ApiService: Generic error syncing photos: $e');
      throw Exception('Failed to sync photos: $e');
    }
  }

  Future<Map<String, dynamic>> syncChecklists(
    Map<String, dynamic>
    payload, { // Changed from List<Map<String, dynamic>> checklists
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await _dio.post(
        '/sync/checklists',
        data: payload, // Use the payload directly
        cancelToken: cancelToken,
        options: await _getAuthOptions(null),
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      // Changed _ back to e
      print('ApiService: DioError syncing checklists: ${e.message}');
      throw Exception(
        'Network error while syncing checklists: ${e.response?.statusCode} - ${e.message}',
      );
    } catch (e) {
      print('ApiService: Generic error syncing checklists: $e');
      throw Exception('Failed to sync checklists: $e');
    }
  }

  Future<Map<String, dynamic>> syncEmotions(
    Map<String, dynamic>
    payload, { // Changed from List<Map<String, dynamic>> emotions
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await _dio.post(
        '/sync/emotions',
        data: payload, // Use the payload directly
        cancelToken: cancelToken,
        options: await _getAuthOptions(null),
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      // Changed _ back to e
      print('ApiService: DioError syncing emotions: ${e.message}');
      throw Exception(
        'Network error while syncing emotions: ${e.response?.statusCode} - ${e.message}',
      );
    } catch (e) {
      print('ApiService: Generic error syncing emotions: $e');
      throw Exception('Failed to sync emotions: $e');
    }
  }

  Future<Map<String, dynamic>> syncLocations(
    Map<String, dynamic>
    payload, { // Changed from List<Map<String, dynamic>> locations
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await _dio.post(
        '/sync/locations',
        data: payload, // Use the payload directly
        cancelToken: cancelToken,
        options: await _getAuthOptions(null),
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      // Changed _ back to e
      print('ApiService: DioError syncing locations: ${e.message}');
      throw Exception(
        'Network error while syncing locations: ${e.response?.statusCode} - ${e.message}',
      );
    } catch (e) {
      print('ApiService: Generic error syncing locations: $e');
      throw Exception('Failed to sync locations: $e');
    }
  }

  Future<Map<String, dynamic>> syncSchedules(
    Map<String, dynamic>
    payload, { // Changed from List<Map<String, dynamic>> schedules
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await _dio.post(
        '/sync/schedules',
        data: payload, // Use the payload directly
        cancelToken: cancelToken,
        options: await _getAuthOptions(null),
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      // Changed _ back to e
      print('ApiService: DioError syncing schedules: ${e.message}');
      throw Exception(
        'Network error while syncing schedules: ${e.response?.statusCode} - ${e.message}',
      );
    } catch (e) {
      print('ApiService: Generic error syncing schedules: $e');
      throw Exception('Failed to sync schedules: $e');
    }
  }
}
