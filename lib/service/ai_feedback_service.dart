// AI 피드백 관련 서버 API 연동 및 모델 정의
// 실제 네트워크 호출 및 데이터 파싱 구현
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:recap_today/constants.dart';

class AiFeedbackService {
  // AI 피드백 요청: 프롬프트(혹은 데이터)를 서버에 전달
  Future<String?> requestAIFeedback(String prompt, {String? authToken}) async {
    final url = Uri.parse(
      'kBaseUrl/ai-feedback/request'.replaceFirst('kBaseUrl', kBaseUrl),
    );
    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          if (authToken != null) 'Authorization': 'Bearer $authToken',
        },
        body: jsonEncode({'prompt': prompt}),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body)['feedbackText'];
      } else if (response.statusCode == 429) {
        throw Exception('오늘은 이미 AI 피드백을 요청하셨습니다.');
      }
      return null;
    } catch (e) {
      // TODO: 에러 로깅/처리
      rethrow;
    }
  }
}
