import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:recap_today/model/freezed/step_model.dart';
import 'package:recap_today/provider/step_provider.dart';
import 'package:intl/intl.dart';

class StepSummary extends StatefulWidget {
  final DateTime date;

  const StepSummary({
    Key? key,
    required this.date,
  }) : super(key: key);

  @override
  State<StepSummary> createState() => _StepSummaryState();
}

class _StepSummaryState extends State<StepSummary> {
  late Future<StepModel?> _stepDataFuture;

  @override
  void initState() {
    super.initState();
    _loadStepData();
  }

  @override
  void didUpdateWidget(StepSummary oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.date != widget.date) {
      _loadStepData();
    }
  }

  void _loadStepData() {
    final stepProvider = Provider.of<StepProvider>(context, listen: false);
    _stepDataFuture = stepProvider.loadStepsForDate(widget.date);
  }

  @override
  Widget build(BuildContext context) {
    final stepProvider = Provider.of<StepProvider>(context);
    final isToday = _isToday(widget.date);
    
    return FutureBuilder<StepModel?>(
      future: _stepDataFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _LoadingView();
        }

        // Today's data comes from provider directly
        if (isToday) {
          return _StepDataView(
            stepData: stepProvider.todayStep,
            dailyGoal: stepProvider.dailyGoal,
          );
        }

        if (snapshot.hasError) {
          return const _ErrorView();
        }

        final stepData = snapshot.data;
        if (stepData == null) {
          return _EmptyView(date: widget.date);
        }

        return _StepDataView(
          stepData: stepData,
          dailyGoal: stepProvider.dailyGoal,
        );
      },
    );
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month && date.day == now.day;
  }
}

class _LoadingView extends StatelessWidget {
  const _LoadingView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Center(
          child: CircularProgressIndicator(),
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Center(
          child: Text('데이터를 불러오는 중 오류가 발생했습니다'),
        ),
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  final DateTime date;
  
  const _EmptyView({Key? key, required this.date}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text('걸음 수', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(DateFormat('yyyy-MM-dd').format(date)),
            const Text('기록된 걸음 수 없음'),
            if (_canShowSyncButton())
              ElevatedButton(
                onPressed: () {
                  final stepProvider = Provider.of<StepProvider>(
                    context, 
                    listen: false
                  );
                  stepProvider.fetchStepFromGoogleFit(date);
                },
                child: const Text('Google Fit에서 가져오기'),
              ),
          ],
        ),
      ),
    );
  }

  bool _canShowSyncButton() {
    return true; // 간소화를 위해 항상 표시
  }
}

class _StepDataView extends StatelessWidget {
  final StepModel stepData;
  final int dailyGoal;
  
  const _StepDataView({
    Key? key, 
    required this.stepData, 
    required this.dailyGoal,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final double percentComplete = (stepData.stepCount / dailyGoal).clamp(0.0, 1.0);
    
    return Card(
      // 카드가 가로로 꽉 차도록 margin 제거 또는 최소화
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          // 전체 너비 사용
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('걸음 수', 
              style: TextStyle(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            // 가로 중앙 정렬을 유지하면서 너비 최대화
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      height: 100,
                      width: 100,
                      child: CircularProgressIndicator(
                        value: percentComplete,
                        backgroundColor: Colors.grey[200],
                        valueColor: AlwaysStoppedAnimation<Color>(
                          percentComplete >= 1.0 ? Colors.green : Colors.blue,
                        ),
                        // 두껍게 표시
                        strokeWidth: 10,
                      ),
                    ),
                    Text(
                      '${stepData.stepCount}\n/${dailyGoal}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${(percentComplete * 100).toInt()}% 달성',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
