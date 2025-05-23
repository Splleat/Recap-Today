import 'package:flutter/material.dart';
import 'package:recap_today/router.dart';
import 'package:recap_today/widget/background.dart';
import 'package:recap_today/widget/summary/location_info.dart';
import 'package:recap_today/widget/summary/weather_summary.dart'; // 날씨 요약 위젯 추가
import 'package:recap_today/widget/summary/app_usage.dart';
import 'package:recap_today/widget/summary/checklist_achievement.dart';
import 'package:recap_today/widget/summary/ai_feedback.dart';
import 'package:recap_today/widget/summary/diary_widget.dart';
import 'package:recap_today/widget/summary/emotion_summary_graph.dart'; // 추가

class SummaryScreen extends StatefulWidget {
  const SummaryScreen({super.key});

  @override
  State<SummaryScreen> createState() => _SummaryScreenState();
}

class _SummaryScreenState extends State<SummaryScreen> {
  double initialChildSize = 0.5;

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
            onPressed: () {
              // 공유 기능 구현
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
          Container(decoration: commonTabDecoration()),
          // 요약 카드들 (스크롤 가능)
          SafeArea(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 80.0),
                      child: LocationInfo(),
                    ),
                  ),
                  Card(
                    child: Padding(
                      // 패딩 추가
                      padding: const EdgeInsets.symmetric(
                        vertical: 80.0,
                      ), // LocationInfo와 동일한 패딩 적용
                      child: WeatherSummary(),
                    ),
                  ), // 날씨 요약 위젯 추가
                  Card(child: AppUsage()),
                  Card(child: ChecklistAchievement()),
                  // EmotionSummaryGraph 추가
                  Card(child: EmotionSummaryGraph(date: DateTime.now())),
                  Card(child: AiFeedback()),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 35.0),
                    ),
                  ),
                ],
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
                  color: Colors.white,
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
