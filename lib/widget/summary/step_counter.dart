import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:provider/provider.dart';
import 'package:recap_today/provider/step_provider.dart';

class StepWidget extends StatelessWidget {
  final int dailyGoal;

  const StepWidget({super.key, this.dailyGoal = 5000});

  @override
  Widget build(BuildContext context) {
    final stepProvider = context.watch<StepProvider>();
    final step = stepProvider.todayStep.stepCount;

    final percent = step / dailyGoal;
    final formattedSteps = NumberFormat('#,###').format(step);
    final formattedGoal = NumberFormat('#,###').format(dailyGoal);
    final formattedDistance = (step * 0.7 / 1000).toStringAsFixed(1);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.8),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Column(
            children: [
              Text(
                formattedSteps,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Text('/ $formattedGoal'),
            ],
          ),
          const Spacer(flex: 1),
          Column(
            children: [
              const Text(
                '이동거리',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Text('$formattedDistance Km'),
            ],
          ),
          const Spacer(flex: 2),
          CircularPercentIndicator(
            radius: 50.0,
            lineWidth: 10.0,
            percent: percent.clamp(0.0, 1.0),
            animation: true,
            circularStrokeCap: CircularStrokeCap.round,
            progressColor: Colors.blue,
            backgroundColor: Colors.grey.shade300,
            center: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.directions_walk, size: 32),
                const SizedBox(height: 4),
                Text(
                  '${(percent * 100).toStringAsFixed(1)}%',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
