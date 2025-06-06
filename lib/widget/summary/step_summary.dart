import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:provider/provider.dart';
import 'package:recap_today/model/freezed/step_model.dart';
import 'package:recap_today/provider/step_provider.dart';

class StepSummaryWidget extends StatelessWidget {
  final DateTime date;

  const StepSummaryWidget({
    super.key,
    required this.date,
  });

  @override
  Widget build(BuildContext context) {
    final stepProvider = context.watch<StepProvider>();
    final dailyGoal = stepProvider.dailyGoal;
    final dateFormatted = DateFormat('yyyy년 MM월 dd일').format(date);
    
    // 날짜 디버깅
    final now = DateTime.now();
    final isToday = date.year == now.year && date.month == now.month && date.day == now.day;
    
    // 오늘 날짜인 경우 현재 메모리 내 걸음 수와 데이터베이스의 값 비교
    if (isToday) {
      debugPrint('📊 오늘 날짜 요청: $dateFormatted');
      debugPrint('📊 현재 메모리의 todayStep: ${stepProvider.todayStep?.stepCount ?? "NULL"}');
    }
    
    // 기존 코드 유지
    return FutureBuilder<StepModel?>(
      future: stepProvider.loadStepsForDate(date),
      builder: (context, snapshot) {
        // 로딩 중
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: CircularProgressIndicator(),
            ),
          );
        }
        
        // 에러 발생
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Text(
                "데이터 로딩 중 오류가 발생했습니다.",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
            ),
          );
        }
        
        // 데이터가 없는 경우
        final stepData = snapshot.data;
        if (stepData == null) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Text(
                "기록된 걸음이 없습니다.",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          );
        }
        
        // 데이터가 있는 경우 - 이제 stepCount에 접근 가능
        final step = stepData.stepCount;
        final percent = step / dailyGoal;
        final formattedSteps = NumberFormat('#,###').format(step);
        final formattedGoal = NumberFormat('#,###').format(dailyGoal);
        final formattedDistance = (step * 0.7 / 1000).toStringAsFixed(1);
        
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 걸음 수
              Column(
                children: [
                  Text(
                    formattedSteps,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Row(
                    children: [
                      const Text('/'),
                      Text(
                        formattedGoal,
                        style: const TextStyle(fontSize: 16),
                      ),
                    ],
                  )
                ],
              ),
              const Spacer(),
          
              // 이동 거리
              Column(
                children: [
                  const Text(
                    '이동거리',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Text('$formattedDistance Km'),
                ],
              ),
              const Spacer(),
          
              // 원형 진행바
              CircularPercentIndicator(
                radius: 40.0,
                lineWidth: 8.0,
                percent: percent.clamp(0.0, 1.0),
                animation: true,
                animationDuration: 500,
                circularStrokeCap: CircularStrokeCap.round,
                progressColor: _getProgressColor(percent),
                backgroundColor: Colors.grey.shade300,
                center: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.directions_walk, size: 24),
                    Text(
                      '${(percent * 100).toStringAsFixed(0)}%',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }
    );
  }

  // 진행률에 따라 색상 변경
  Color _getProgressColor(double percent) {
    if (percent >= 1.0) return Colors.green;
    if (percent >= 0.7) return Colors.blue;
    if (percent >= 0.4) return Colors.orange;
    return Colors.red;
  }
}
