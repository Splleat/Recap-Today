import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:async';

final List<IconData> dummyWeatherIcons = [Icons.sunny, Icons.sunny, Icons.sunny, Icons.sunny, Icons.sunny, Icons.sunny, Icons.sunny, Icons.sunny, Icons.sunny, Icons.sunny, Icons.sunny, Icons.sunny, Icons.sunny, Icons.sunny, Icons.sunny, Icons.sunny, Icons.sunny, Icons.sunny, Icons.sunny, Icons.sunny, Icons.sunny, Icons.sunny, Icons.sunny, Icons.sunny];

class HomeSchedule extends StatelessWidget {
  const HomeSchedule({super.key});

  Widget build(BuildContext context) {
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
              const SizedBox(height: 8),
              const Divider(thickness: 2, color: Colors.red),
              const SizedBox(height: 8),
              HomeScheduleTimeline(),
              const SizedBox(height: 8),
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

class HomeScheduleWeather extends StatelessWidget {
  final List<IconData> weatherIcons;

  const HomeScheduleWeather({super.key, required this.weatherIcons});

  Widget build(BuildContext context) {
    return SizedBox(
      height: 50,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: List.generate(
            weatherIcons.length,
            (index) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Column(
                children: [
                  Icon(weatherIcons[index], size: 24),
                  Text('${index}시', style: TextStyle(fontSize: 10)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class HourlyTimeGrid extends StatelessWidget {
  const HourlyTimeGrid({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(24, (index) {
        return Expanded(
          child: Container(
            height: 40,
            decoration: BoxDecoration(
              border: Border(
                right: BorderSide(color: Colors.grey.shade300, width: 0.5),
              ),
            ),
          ),
        );
      }),
    );
  }
}

class ScheduleBar extends StatelessWidget {
  final int startHour; // 0~23
  final int durationHours; // 1~24
  final Color color;
  final String type;
  final double height;

  const ScheduleBar({
    super.key,
    required this.startHour,
    required this.durationHours,
    required this.color,
    required this.type,
    this.height = 20.0,
  });

  @override
  Widget build(BuildContext context) {
    double hourWidth = MediaQuery.of(context).size.width / 24;
    double barHeight = 20.0;

    return SizedBox(
      width: durationHours * hourWidth,
      height: barHeight,
      child: Container(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(4),
        ),
      ),
    );
  }
}

class HomeScheduleTimeline extends StatelessWidget {
  const HomeScheduleTimeline({super.key});

  final List<Map<String, dynamic>> scheduleData = const [
    {'startHour': 6, 'durationHours': 2, 'color': Colors.lightBlue, 'type': 'routine'},
    {'startHour': 10, 'durationHours': 1, 'color': Colors.greenAccent, 'type': 'user'},
    {'startHour': 8, 'durationHours': 3, 'color': Colors.lightBlue, 'type': 'routine'},
    {'startHour': 12, 'durationHours': 2, 'color': Colors.purple, 'type': 'user'},
    {'startHour': 7, 'durationHours': 1, 'color': Colors.lightBlueAccent, 'type': 'routine'},
  ];

  @override
  Widget build(BuildContext context) {
    double hourWidth = 60.0;
    double totalWidth = hourWidth * 24;
    const double verticalSpacing = 50;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,

      child: SizedBox(
        width: totalWidth,
        child: Column(
          children: [
            Row(
              children: List.generate(24, (index) {
                return SizedBox(
                  width: hourWidth,
                  child: Column(
                    children: [
                      Icon(dummyWeatherIcons[index], size: 24),
                      Text('${index}시', style: TextStyle(fontSize: 10)),
                    ],
                  ),
                );
              }),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 80,
              child: Stack(
                children: [
                  Row(
                    children: List.generate(24, (index) {
                      return Container(
                        width: hourWidth,
                        height: 80,
                        decoration: BoxDecoration(
                          border: Border(
                            right: BorderSide(color: Colors.grey.shade300, width: 0.5),
                          ),
                        ),
                      );
                    }),
                  ),
                  ...scheduleData.map((event) {
                    final double topOffset = event['type'] == 'routine'
                        ? 0
                        : verticalSpacing;
                    final int startHour = event['startHour'] as int;
                    final double leftPosition = startHour * hourWidth;

                    return Positioned(
                      top: topOffset,
                      left: leftPosition, // 막대의 시작 위치 설정
                      child: ScheduleBar(
                        startHour: startHour,
                        durationHours: event['durationHours'] as int,
                        color: event['color'] as Color,
                        type: event['type'] as String,
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
