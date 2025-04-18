import 'package:flutter/material.dart';
import 'package:recap_today/router.dart';
import 'package:recap_today/widget/bottom_navigation.dart';
import 'home_screen.dart';
import 'planner_screen.dart';
import 'calendar_screen.dart';
import 'summary_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  final List<String> _routes = [
    AppRoutes.home,
    AppRoutes.planner,
    AppRoutes.calendar,
    AppRoutes.summary,
  ];

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
      // Navigator.pushReplacementNamed(context, _routes[index]); // body만 변경하므로 불필요
    });
  }

  Widget _buildBody(int index) {
    switch (index) {
      case 0:
        return const HomeScreen(); // HomeScreenContent 반환
    case 1:
      return const PlannerScreen();
    case 2:
      return const CalendarScreen();
    case 3:
      return const SummaryScreen();
      default:
        return const Center(child: Text('알 수 없는 화면'));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: _buildBody(_currentIndex),
      bottomNavigationBar: BottomNavigationBarWidget(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
      ),
    );
  }
}