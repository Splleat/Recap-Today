import 'package:flutter/material.dart';
import 'package:recap_today/widget/background.dart';
import 'package:recap_today/router.dart';
import 'package:recap_today/widget/home/home_checklist.dart';
import 'package:recap_today/widget/home/home_schedule.dart';
import 'package:recap_today/widget/planner/checklist_screen.dart';
import 'package:recap_today/widget/home/hourly_emotion_logger.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text('Recap Today'),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.settings),
            onPressed: () {
              Navigator.pushNamed(context, AppRoutes.settings);
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          Container(decoration: commonTabDecoration()),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: SingleChildScrollView(
                // Wrap Column with SingleChildScrollView
                child: Column(
                  children: [
                    HomeSchedule(date: DateTime.now()),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const HomeChecklist(),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white.withOpacity(0.8),
                          padding: const EdgeInsets.all(16.0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                          elevation: 0,
                          shadowColor: Colors.transparent,
                        ),
                        child: Row(
                          children: [
                            Text('할 일을 확인하세요'),
                            Spacer(),
                            Icon(Icons.arrow_forward),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    HourlyEmotionLogger(initialDate: DateTime.now()),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
