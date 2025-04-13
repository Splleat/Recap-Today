import 'package:flutter/material.dart';
import 'package:recap_today/widget/background.dart';
import 'package:recap_today/router.dart';
import 'package:recap_today/widget/home/home_checklist.dart';
import 'package:recap_today/widget/home/home_schedule.dart';
import 'package:recap_today/widget/planner/checklist_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {

  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text('Recap Today', style: textTheme.headlineLarge),
        actions: <Widget>[
          IconButton(
              icon: Icon(Icons.settings),
              onPressed: () {
                Navigator.pushNamed(context, AppRoutes.settings);
              }
          )
        ],
      ),
      body: Stack (
        children: [
          Container(
            decoration: commonTabDecoration(),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  HomeSchedule(),
                  const SizedBox(height: 16),
                  const Expanded(child: ChecklistScreen()),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}