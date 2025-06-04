import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../provider/login_provider.dart';
import '../../service/ai_feedback_service.dart';

class AiFeedback extends StatelessWidget {
  final String? feedbackText;
  final bool isLoading;
  final VoidCallback? onRequestFeedback;
  final bool requestedToday;

  const AiFeedback({
    super.key,
    this.feedbackText,
    this.isLoading = false,
    this.onRequestFeedback,
    this.requestedToday = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withOpacity(0.8),
        borderRadius: BorderRadius.circular(16.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.insights),
                const SizedBox(width: 8),
                Text(
                  'AI 인사이트',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                OutlinedButton.icon(
                  onPressed:
                      isLoading || requestedToday ? null : onRequestFeedback,
                  icon: const Icon(Icons.refresh),
                  label: const Text('피드백 생성'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Theme.of(context).primaryColor,
                    side: BorderSide(color: Theme.of(context).primaryColor),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            if (isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 24.0),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (feedbackText != null && feedbackText!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Text(
                  feedbackText!,
                  style: const TextStyle(fontSize: 15, height: 1.5),
                ),
              )
            else
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24.0),
                child: Center(
                  child: Text(
                    '아직 피드백이 생성되지 않았습니다.',
                    style: TextStyle(fontSize: 15, fontStyle: FontStyle.italic),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class AiFeedbackWidget extends StatefulWidget {
  final AiFeedbackService service;
  const AiFeedbackWidget({super.key, required this.service});

  @override
  State<AiFeedbackWidget> createState() => _AiFeedbackWidgetState();
}

class _AiFeedbackWidgetState extends State<AiFeedbackWidget> {
  String? feedbackText;
  bool isLoading = false;
  bool requestedToday = false;

  @override
  void initState() {
    super.initState();
    // 피드백 캐싱/조회가 필요하다면 로컬에서 처리
    // _loadTodayFeedback(); // 필요시 구현
  }

  // 프롬프트 생성 및 서버 요청
  Future<void> _requestFeedback() async {
    setState(() {
      isLoading = true;
    });
    final prompt = '';
    try {
      final loginProvider = Provider.of<LoginProvider>(context, listen: false);
      final authToken = loginProvider.authToken;
      final text = await widget.service.requestAIFeedback(
        prompt,
        authToken: authToken,
      );
      setState(() {
        feedbackText = text;
        requestedToday = true;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      if (e.toString().contains('오늘은 이미 AI 피드백을 요청하셨습니다.')) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('오늘은 이미 AI 피드백을 요청하셨습니다.'),
            backgroundColor: Colors.orange,
          ),
        );
        setState(() {
          requestedToday = true;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('AI 피드백 요청 중 오류가 발생했습니다.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AiFeedback(
      feedbackText: feedbackText,
      isLoading: isLoading,
      onRequestFeedback: _requestFeedback,
      requestedToday: requestedToday,
    );
  }
}
