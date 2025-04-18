import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

class MainCalendar extends StatefulWidget {
  final void Function(DateTime selectedDay)? onDateSelectedCallback;

  const MainCalendar ({
    super.key,
    this.onDateSelectedCallback,
  });

  _MainCalendarState createState() => _MainCalendarState();
}

class _MainCalendarState extends State<MainCalendar> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  void initState() {
    super.initState();
    _selectedDay = DateTime.now();
    _focusedDay = _selectedDay!;
  }

  Widget build(BuildContext context) {
    return TableCalendar(
      locale: 'ko_KR',
      focusedDay: _focusedDay,
      calendarFormat: _calendarFormat,
      firstDay: DateTime(1800, 1, 1),
      lastDay: DateTime(3000, 1, 1),

      onFormatChanged: (format) {
        setState(() {
          _calendarFormat = format;
        });
      },

      selectedDayPredicate: (day) {
        return isSameDay(_selectedDay, day);
      },

      onDaySelected: (selectedDay, focusedDay) {
        setState(() {
          _selectedDay = selectedDay;
          _focusedDay = selectedDay;
        });
        print('선택된 날짜: $_selectedDay'); // 디버그용 코드

        widget.onDateSelectedCallback?.call(selectedDay);
      },

      availableCalendarFormats: const {
        CalendarFormat.month: '주간',
        CalendarFormat.week: '월간',
      },

      headerStyle: HeaderStyle(
        titleCentered: true,
        formatButtonVisible: true,
      ),

      calendarStyle: CalendarStyle(
        isTodayHighlighted: false,
      ),
    );
  }
}