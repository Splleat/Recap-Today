import 'package:flutter/material.dart';
import 'package:recap_today/widget/background.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  State<CalendarScreen> createState() => _CalanderScreenState();
}

class _CalanderScreenState extends State<CalendarScreen> {

  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text('캘린더', style: textTheme.headlineMedium),
        centerTitle: true,
      ),
      body: Container(
        decoration: commonTabDecoration(),
      ),
    );
  }
}