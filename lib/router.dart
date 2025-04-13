import 'package:flutter/material.dart';
import 'package:recap_today/screens/home_screen.dart';
import 'package:recap_today/screens/planner_screen.dart';
import 'package:recap_today/screens/calendar_screen.dart';
import 'package:recap_today/screens/summary_screen.dart';
import 'package:recap_today/screens/settings_screen.dart';
import 'package:recap_today/widget/planner/timetable.dart';

class AppRoutes {
  static const String home = '/';
  static const String planner = '/planner';
  static const String calendar = '/calendar';
  static const String summary = '/summary';
  static const String settings = '/settings';
  static const String timetable = '/timetable';
}

class AppRouter {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.home:
        return MaterialPageRoute(builder: (_) => const HomeScreen());
      case AppRoutes.planner:
        return MaterialPageRoute(builder: (_) => const PlannerScreen());
      case AppRoutes.calendar:
        return MaterialPageRoute(builder: (_) => const CalendarScreen());
      case AppRoutes.summary:
        return MaterialPageRoute(builder: (_) => const SummaryScreen());
      case AppRoutes.settings:
        return MaterialPageRoute(builder: (_) => const SettingsScreen());
      case AppRoutes.timetable:
        //return MaterialPageRoute(builder: (_) => const TimetableWidget());
      default:
        return _errorRoute();
    }
  }

  static Route<dynamic> _errorRoute() {
    return MaterialPageRoute(builder: (_) {
      return Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: const Center(child: Text('잘못된 경로입니다.')),
      );
    });
  }
}