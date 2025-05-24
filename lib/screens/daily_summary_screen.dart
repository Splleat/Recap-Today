import 'package:flutter/material.dart';
import 'package:recap_today/widget/summary/app_usage.dart';
import 'package:recap_today/widget/summary/checklist_achievement.dart';
import 'package:recap_today/widget/background.dart';

class DailySummaryScreen extends StatelessWidget {
  final DateTime selectedDate;

  const DailySummaryScreen({super.key, required this.selectedDate});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          "${selectedDate.year}년 ${selectedDate.month}월 ${selectedDate.day}일",
        ),
      ),
      body: Container(
        decoration: commonTabDecoration(),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 8.0,
                      vertical: 8.0,
                    ),
                    child: AppUsage(date: selectedDate),
                  ),
                  Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 8.0,
                      vertical: 8.0,
                    ),
                    child: ChecklistAchievement(date: selectedDate),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
