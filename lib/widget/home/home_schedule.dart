import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import 'package:recap_today/widget/planner/timeline.dart';
import 'package:recap_today/provider/schedule_provider.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';

class HomeSchedule extends StatelessWidget {
  final DateTime date;

  const HomeSchedule({super.key, required this.date});

  Widget build(BuildContext context) {
    final scheduleProvider = context.watch<ScheduleProvider>();
    final allItems = scheduleProvider.items;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      child: Card(
        elevation: 0.1,
        color: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: Container(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const HomeScheduleTime(),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DailyTimeline(context, date, allItems),
              )
            ],
          ),
        )
      ),
    );
  }
}

class HomeScheduleTime extends StatefulWidget {
  const HomeScheduleTime({super.key});

  @override
  State<HomeScheduleTime> createState() => _HomeScheduleTime();
}

class _HomeScheduleTime extends State<HomeScheduleTime> {
  late Timer _timer;
  late String _formattedTime = '';

  @override
  void initState() {
    super.initState();
    _updateTime();
    _timer = Timer.periodic(const Duration(seconds: 60), (_) => _updateTime());
  }

  void _updateTime() {
    final now = DateTime.now();
    setState(() {
      _formattedTime = DateFormat('a h:mm', 'ko').format(now);
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  Widget build(BuildContext context) {

    return Text('$_formattedTime');
  }
}

