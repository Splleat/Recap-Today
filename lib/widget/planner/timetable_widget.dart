import 'package:flutter/material.dart';
import 'package:recap_today/widget/planner/timetable.dart';

class TimetableWidget extends StatelessWidget {
  TimetableWidget({super.key});

  Widget build(BuildContext context) {

    return SafeArea(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: (kColumnLength / 2 * kBoxSize) + kFirstColumnHeight,
              child: Row(
                children: [
                  buildTimeColumn(),
                  ...buildDayColumn(0),
                  ...buildDayColumn(1),
                  ...buildDayColumn(2),
                  ...buildDayColumn(3),
                  ...buildDayColumn(4),
                  ...buildDayColumn(5),
                  ...buildDayColumn(6),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}