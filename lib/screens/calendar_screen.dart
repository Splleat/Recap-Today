import 'package:flutter/material.dart';
import 'package:recap_today/widget/background.dart';
import 'package:recap_today/widget/calendar.dart';
import 'package:recap_today/router.dart'; // Add this import
import 'package:recap_today/widget/summary/app_usage.dart'; // Import AppUsage widget

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
                // The problematic null check has been removed.
                // selectedDay is non-nullable as determined by the Dart analyzer.

                showModalBottomSheet(
                  context: context,
                  isScrollControlled:
                      true, // Allow bottom sheet to take full height if needed
                  builder:
                      (context) => SingleChildScrollView(
                        // Wrap with SingleChildScrollView
                        child: Container(
                          color: Colors.white,
                          // height: 300, // Removed fixed height
                          child: Column(
                            mainAxisSize:
                                MainAxisSize.min, // Shrink wrap the column
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Text(
                                  // Formatting the date - removed unnecessary backslashes
                                  "${selectedDay.year}년 ${selectedDay.month}월 ${selectedDay.day}일",
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              // Removed Expanded widget
                              Card(
                                margin: EdgeInsets.symmetric(
                                  horizontal: 16.0,
                                  vertical: 8.0,
                                ),
                                child: AppUsage(
                                  date: selectedDay,
                                ), // Pass selectedDay to AppUsage
                              ),
                            ],
                          ),
                        ),
                      ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
