import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:provider/provider.dart';
import 'package:recap_today/provider/step_provider.dart';

class StepWidget extends StatelessWidget {

  const StepWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final stepProvider = context.watch<StepProvider>();
    final step = stepProvider.todayStep.stepCount;
    final dailyGoal = stepProvider.dailyGoal;

    final percent = step / dailyGoal;
    final formattedSteps = NumberFormat('#,###').format(step);
    final formattedGoal = NumberFormat('#,###').format(dailyGoal);
    final formattedDistance = (step * 0.7 / 1000).toStringAsFixed(1);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Theme.of(context).colorScheme.surface.withOpacity(0.8),
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
              Row(
                children: [
                  Text('/'),
                  TextButton(
                    onPressed: () async {
                      final controller = TextEditingController(
                        text: dailyGoal.toString(),
                      );

                      final result = await showDialog<int>(
                        context: context,
                        builder: (context) {
                          return AlertDialog(
                            title: const Text('목표 걸음 수 설정'),
                            content: TextField(
                              controller: controller,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(labelText: '걸음 수'),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(),
                                child: const Text('취소'),
                              ),
                              TextButton(
                                onPressed: () {
                                  final input = int.tryParse(controller.text);
                                  Navigator.of(context).pop(input);
                                },
                                child: const Text('확인'),
                              ),
                            ],
                          );
                        },
                      );

                      if (result != null && result > 0) {
                        await context.read<StepProvider>().updateDailyGoal(result);
                      }
                    },

                    child: Text(
                      formattedGoal,
                      style: const TextStyle(decoration: TextDecoration.underline),
                    ),
                  ),
                ],
              )
            ],
          ),
          const Spacer(),
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
