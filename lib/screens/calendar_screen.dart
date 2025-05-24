import 'package:flutter/material.dart';
import 'package:recap_today/widget/background.dart';
import 'package:recap_today/widget/calendar.dart';
import 'package:recap_today/router.dart'; // Add this import

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  State<CalendarScreen> createState() => _CalanderScreenState();
}

class _CalanderScreenState extends State<CalendarScreen> {
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text('캘린더'),
        centerTitle: true,
        actions: <Widget>[
          // Add this actions widget
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
            child: MainCalendar(
              onDateSelectedCallback: (selectedDay) {
                showModalBottomSheet(
                  context: context,
                  builder:
                      (context) => Container(color: Colors.white, height: 300),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
