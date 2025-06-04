import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import '../../provider/login_provider.dart';
import '../../service/ai_feedback_service.dart';

class AiFeedback extends StatelessWidget {
  final String? feedbackText;
  final bool isLoading;
  final VoidCallback? onRequestFeedback;
  final bool isButtonEnabled;

  const AiFeedback({
    super.key,
    this.feedbackText,
    this.isLoading = false,
    this.onRequestFeedback,
    this.isButtonEnabled = false,
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
                Icon(Icons.insights, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Text(
                  'AI 인사이트',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: isButtonEnabled ? onRequestFeedback : null,
                  icon: Icon(
                    Icons.refresh,
                    color: isButtonEnabled ? Colors.white : Colors.grey[400],
                  ),
                  label: Text(
                    '피드백 생성',
                    style: TextStyle(
                      color: isButtonEnabled ? Colors.white : Colors.grey[400],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        isButtonEnabled
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).disabledColor,
                    disabledBackgroundColor: Theme.of(context).disabledColor,
                    elevation: isButtonEnabled ? 2 : 0,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 12,
                    ),
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
            else if (feedbackText != null && feedbackText!.trim().isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: SelectableText(
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

  Future<void> _requestFeedback() async {
    setState(() {
      isLoading = true;
    });
    final prompt = 'api 호출이 잘 되는지 테스트하기 위한 프롬프트야. 가장 짧은 유머를 하나 해줘';
    try {
      final loginProvider = Provider.of<LoginProvider>(context, listen: false);
      final authToken = loginProvider.authToken;
      final text = await widget.service.requestAIFeedback(
        prompt,
        authToken: authToken,
      );
      if (!mounted) return;
      setState(() {
        feedbackText = text;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('AI 피드백 요청 중 오류가 발생했습니다.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoggedIn = context.select<LoginProvider, bool>(
      (login) => login.authToken != null && login.authToken!.isNotEmpty,
    );
    return AiFeedback(
      feedbackText: feedbackText,
      isLoading: isLoading,
      onRequestFeedback: _requestFeedback,
      isButtonEnabled: isLoggedIn && !isLoading,
    );
  }
}
