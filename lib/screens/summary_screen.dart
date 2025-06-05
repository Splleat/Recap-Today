import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:recap_today/provider/login_provider.dart';
import 'package:recap_today/router.dart';
import 'package:recap_today/widget/background.dart';
import 'package:recap_today/widget/summary/location_info.dart';
import 'package:recap_today/widget/summary/weather_summary.dart'; // 날씨 요약 위젯 추가
import 'package:recap_today/widget/summary/app_usage.dart';
import 'package:recap_today/widget/summary/checklist_achievement.dart';
import 'package:recap_today/widget/summary/ai_feedback.dart';
import 'package:recap_today/widget/summary/diary_widget.dart';
import 'package:recap_today/widget/summary/emotion_summary_graph.dart'; // 추가
import 'package:recap_today/utils/share_util.dart';
import 'package:recap_today/service/ai_feedback_service.dart';
import 'package:recap_today/widget/summary/step_summary.dart'; // 걸음 수 요약 위젯 추가

class SummaryScreen extends StatefulWidget {
  const SummaryScreen({super.key});

  @override
  State<SummaryScreen> createState() => _SummaryScreenState();
}

class _SummaryScreenState extends State<SummaryScreen> {
  double initialChildSize = 0.5;
  final GlobalKey _captureKey = GlobalKey();
  LocationInfo? _locationInfoWidget;
  final GlobalKey<LocationInfoState> _locationInfoKey =
      GlobalKey<LocationInfoState>();

  @override
  void initState() {
    super.initState();
    _locationInfoWidget = LocationInfo(
      key: _locationInfoKey,
      date: DateTime.now(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;

    // 키보드가 나타날 때 바닥 시트를 전체 화면으로 확장
    if (keyboardHeight > 0) {
      initialChildSize = 1.0;
    } else {
      initialChildSize = 0.1;
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      resizeToAvoidBottomInset: false, // 키보드 등장 시 화면 크기 조정 방지
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text('하루 요약'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () async {
              final imageBytes = await ShareUtil.capture(_captureKey);
              if (imageBytes != null) {
                showDialog(
                  context: context,
                  builder:
                      (_) => AlertDialog(
                        content: Image.memory(imageBytes),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text('닫기'),
                          ),
                          TextButton(
                            onPressed: () async {
                              final file = await ShareUtil.saveToTempFile(
                                imageBytes,
                                'recap_preview',
                              );
                              if (file != null) {
                                await ShareUtil.shareImageFile(file);
                              }
                              Navigator.pop(context);
                            },
                            child: Text('공유하기'),
                          ),
                        ],
                      ),
                );
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.pushNamed(context, AppRoutes.settings),
          ),
        ],
      ),
      body: Stack(
        children: [
          // 배경 데코레이션
          Container(decoration: commonTabDecoration(context)),
          // 요약 카드들 (스크롤 가능)
          SafeArea(
            child: SingleChildScrollView(
              child: RepaintBoundary(
                key: _captureKey,
                child: Column(
                  children: [
                    Card(child: _locationInfoWidget!),
                    Card(child: StepSummary(date: DateTime.now())),
                    Card(child: AppUsage()),
                    Card(child: ChecklistAchievement()),
                    Card(child: EmotionSummaryGraph(date: DateTime.now())),
                    Card(child: AiFeedbackWidget(service: AiFeedbackService())),
                    Card(
                      child: SizedBox(
                        height: MediaQuery.of(context).size.height * 0.075,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // 다이어리 위젯을 포함한 드래그 가능한 바닥 시트
          SafeArea(
            child: DraggableScrollableSheet(
              initialChildSize: initialChildSize,
              minChildSize: 0.1,
              maxChildSize: 1.0,
              builder: (
                BuildContext context,
                ScrollController scrollController,
              ) {
                return Container(
                  color: Theme.of(context).colorScheme.surface,
                  child: SingleChildScrollView(
                    controller: scrollController,
                    child: DiaryWidget(), // Restored to original DiaryWidget
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
