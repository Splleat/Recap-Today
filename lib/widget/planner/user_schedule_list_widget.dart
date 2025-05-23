import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:recap_today/provider/schedule_provider.dart';
import 'package:recap_today/utils/time_utils.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:recap_today/model/schedule_item.dart'; // Added import for ScheduleItem
import 'package:recap_today/widget/planner/schedule_add.dart'; // Corrected import path for ScheduleAddForm

class UserScheduleListWidget extends StatelessWidget {
  final DateTime date;

  const UserScheduleListWidget({super.key, required this.date});

  void _showEditDialog(BuildContext context, ScheduleItem item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return Padding(
          padding: MediaQuery.of(sheetContext).viewInsets,
          child: ScheduleAddForm(
            isRoutineContext: false, // User schedules are not routine
            initialItem: item,
            selectedDate: item.selectedDate,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheduleProvider = context.watch<ScheduleProvider>();
    final userItems =
        scheduleProvider
            .getUserItems()
            .where((item) => isSameDay(item.selectedDate, date))
            .toList();

    userItems.sort(
      (a, b) => // 시작 시간 기준으로 정렬
          timeOfDayToMinutes(
        a.startTime,
      ).compareTo(timeOfDayToMinutes(b.startTime)),
    );

    return ListView.builder(
      itemCount: userItems.length,
      itemBuilder: (context, index) {
        final item = userItems[index];
        return Container(
          margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: item.color ?? Colors.cyan, // Use item's color
            borderRadius: BorderRadius.circular(8.0),
          ),
          child: ListTile(
            title: Text(item.text),
            subtitle:
                (item.subText?.isNotEmpty ?? false)
                    ? Text(item.subText!)
                    : null,
            trailing: Text(
              '${item.startTime.format(context)} - ${item.endTime.format(context)}',
            ),
            onTap:
                () => _showEditDialog(context, item), // Added onTap for editing
          ),
        );
      },
    );
  }
}
