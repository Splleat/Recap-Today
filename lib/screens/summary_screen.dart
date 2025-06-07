import 'dart:typed_data'; // For Uint8List
import 'package:flutter/material.dart';
import 'package:recap_today/router.dart';
import 'package:recap_today/widget/background.dart';
import 'package:recap_today/widget/summary/location_info.dart';
import 'package:recap_today/widget/summary/app_usage.dart';
import 'package:recap_today/widget/summary/checklist_achievement.dart';
import 'package:recap_today/widget/summary/ai_feedback.dart';
import 'package:recap_today/widget/summary/diary_widget.dart';
import 'package:recap_today/widget/summary/emotion_summary_graph.dart'; // 추가
import 'package:recap_today/utils/share_util.dart';
import 'package:recap_today/service/ai_feedback_service.dart';
import 'package:recap_today/widget/summary/step_summary.dart'; // 걸음 수 요약 위젯 추가
import 'package:recap_today/widget/crop_and_share_dialog.dart'; // Added import

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

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _locationInfoWidget = LocationInfo(
      key: _locationInfoKey,
      date: DateTime.now(),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // _updateCaptureWidgetRect();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;

    if (keyboardHeight > 0) {
      initialChildSize = 1.0;
    } else {
      initialChildSize = 0.1;
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text('하루 요약'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _initiateShareProcess,
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.pushNamed(context, AppRoutes.settings),
          ),
        ],
      ),
      body: Stack(
        children: [
          Container(decoration: commonTabDecoration(context)),
          SafeArea(
            child: SingleChildScrollView(
              controller: _scrollController,
              child: RepaintBoundary(
                key: _captureKey,
                child: Column(
                  children: [
                    Card(child: _locationInfoWidget!),
                    Card(child: StepSummaryWidget(date: DateTime.now())),
                    Card(child: AppUsage()),
                    Card(child: ChecklistAchievement()),
                    Card(child: EmotionSummaryGraph(date: DateTime.now())),
                    Card(
                      child: AiFeedbackWidget(
                        service: AiFeedbackService(),
                        date: DateTime.now(),
                      ),
                    ),
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

  Future<void> _initiateShareProcess() async {
    final Uint8List? fullImageBytes = await ShareUtil.capture(_captureKey);

    if (fullImageBytes == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('캡처에 실패했습니다.')));
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder:
            (context) => CropAndShareDialog(
              originalImageBytes: fullImageBytes,
            ), // Now uses the imported widget
        fullscreenDialog: true,
      ),
    );
  }
}
