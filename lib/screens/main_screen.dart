import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:recap_today/provider/step_provider.dart'; // import 추가
import 'package:recap_today/widget/bottom_navigation.dart';
import 'home_screen.dart';
import 'planner_screen.dart';
import 'calendar_screen.dart';
import 'summary_screen.dart'; //임시 주석

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    
    // 앱 시작 시 걸음 수 저장 (화면이 그려진 후)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final stepProvider = Provider.of<StepProvider>(context, listen: false);
      if (stepProvider.todayStep.stepCount > 0) {
        stepProvider.saveStepsToDatabase(stepProvider.todayStep);
        debugPrint('👣 앱 시작 시 걸음 수 저장: ${stepProvider.todayStep.stepCount}');
      }
    });
  }

  void _onTabTapped(int index) {
    if (_currentIndex != index && (index == 0 || index == 3)) {
      // 탭이 변경될 때만 저장 실행
      final stepProvider = Provider.of<StepProvider>(context, listen: false);
      if (stepProvider.todayStep.stepCount > 0) {
        stepProvider.saveStepsToDatabase(stepProvider.todayStep);
        debugPrint('👣 탭 전환 시 걸음 수 저장: ${stepProvider.todayStep.stepCount}');
      }
    }
    
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
