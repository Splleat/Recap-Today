import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:recap_today/model/schedule_item.dart';
import 'package:recap_today/provider/schedule_provider.dart';
import 'package:recap_today/widget/planner/timetable.dart';

class TimetableWidget extends StatelessWidget {
  TimetableWidget({super.key});

  Widget build(BuildContext context) {
    final scheduleProvider = context.watch<ScheduleProvider>();
    final allItems = scheduleProvider.items;

    List<List<ScheduleItem>> weeklyFilteredItems = List.generate(7, (dayIndex) {
      return allItems.where((item) {
        if (item.isRoutine) {
          return item.dayOfWeek != null && item.dayOfWeek == dayIndex;
        }
        return false;
      }).toList();

    });

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
                  ...buildDayColumn(0, weeklyFilteredItems[0]),
                  ...buildDayColumn(1, weeklyFilteredItems[1]),
                  ...buildDayColumn(2, weeklyFilteredItems[2]),
                  ...buildDayColumn(3, weeklyFilteredItems[3]),
                  ...buildDayColumn(4, weeklyFilteredItems[4]),
                  ...buildDayColumn(5, weeklyFilteredItems[5]),
                  ...buildDayColumn(6, weeklyFilteredItems[6]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}