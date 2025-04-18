import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:recap_today/provider/schedule_provider.dart';
import 'package:recap_today/utils/time_utils.dart';
import 'package:table_calendar/table_calendar.dart';

class UserScheduleListWidget extends StatelessWidget {
  final DateTime date;

  const UserScheduleListWidget({super.key, required this.date});

  Widget build(BuildContext context) {
    final scheduleProvider = context.watch<ScheduleProvider>();
    final userItems = scheduleProvider.getUserItems().where(
            (item) => isSameDay(item.selectedDate, date)
    ).toList();

    userItems.sort((a, b) => // 시작 시간 기준으로 정렬
      timeOfDayToMinutes(a.startTime).compareTo(timeOfDayToMinutes(b.startTime))
    );

    return ListView.builder(
      itemCount: userItems.length,
      itemBuilder: (context, index) {
        final item = userItems[index];
        return Container(
          margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: Colors.cyan,
            borderRadius: BorderRadius.circular(8.0),
          ),
          child: ListTile(
            title: Text(item.text),
            subtitle: (item.subText?.isNotEmpty ?? false) ? Text(item.subText!) : null,
            trailing: Text(
                '${item.startTime.format(context)} - ${item.endTime.format(context)}'
            ),
          )
        );
      },
    );
  }
}
