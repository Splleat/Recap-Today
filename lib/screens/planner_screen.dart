import 'package:flutter/material.dart';
import 'package:recap_today/router.dart';
import 'package:recap_today/widget/background.dart';
import 'package:recap_today/widget/calendar.dart';
import 'package:recap_today/widget/planner/timeline_widget.dart';
import 'package:recap_today/widget/planner/checklist_screen.dart';
import 'package:recap_today/provider/weather_provider.dart';
import 'package:provider/provider.dart';

class PlannerScreen extends StatefulWidget {
  const PlannerScreen({super.key});

  @override
  State<PlannerScreen> createState() => _PlannerScreenState();
}

class _PlannerScreenState extends State<PlannerScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text('플래너'),
        centerTitle: true,
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.calendar_today),
            onPressed: () {
              Navigator.pushNamed(context, AppRoutes.timetable);
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          Container(decoration: commonTabDecoration(context)),
          SafeArea(
            child: Column(
              children: [
                MainCalendar(
                  onDateSelectedCallback: (selectedDay) async {
                    final weatherProvider = context.read<WeatherProvider>();
                    await weatherProvider.loadCachedWeather(selectedDay);
                    debugPrint('${weatherProvider.getWeather(selectedDay)}');
                    showDialog(
                      context: context,
                      builder:
                          (context) => Dialog(
                            child: DailyTimelineWidget(date: selectedDay),
                          ),
                    );
                  },
                ),
                Expanded(
                  child: Container(
                    padding: EdgeInsets.all(16.0),
                    decoration: BoxDecoration(),
                    child: ChecklistScreen(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
