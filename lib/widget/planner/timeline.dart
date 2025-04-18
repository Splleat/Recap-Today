import 'package:flutter/material.dart';
import 'package:recap_today/model/schedule_item.dart';
import 'package:recap_today/utils/time_utils.dart';
import 'package:recap_today/widget/planner/timetable.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:recap_today/utils/time_utils.dart';


const hourColumnWidth = 60.0;

Widget buildWeatherTimeAxis() { // 24시간의 온도 -> 날씨 -> 시간을 Column으로 반환
  final double weatherAreaHeight = 90.0;

  return Container(
    child: Row(
        children: List.generate(24, (hourIndex) {
          return Container(
              width: hourColumnWidth,
              padding: const EdgeInsets.symmetric(vertical:6.0),
              decoration: BoxDecoration(
                border: Border(
                  right: BorderSide(color: Colors.grey, width:0),
                  left: hourIndex == 0 ? BorderSide(color: Colors.grey, width: 0) : BorderSide.none,
                ),
              ),
              child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('${18 + hourIndex % 5}°'), // 온도 (임시 데이터)
                    Icon(Icons.wb_sunny_rounded), // 날씨 아이콘 (임시 데이터)
                    Text(hourIndex.toString().padLeft(2, '0')), // 시간 (임시 데이터)
                  ]
              )
          );
        })
    ),
  );
}

Widget buildScheduleArea(BuildContext context, DateTime date, List<ScheduleItem> allItems) {
  final double scheduleRowHeight = 40.0;

  final routineItems = allItems.where(
          (item) => item.isRoutine && item.dayOfWeek == date.weekday % 7
  ).toList();
  final userItems = allItems.where(
          (item) => !item.isRoutine && isSameDay(item.selectedDate, date)
  ).toList();

  return SizedBox(
    width: 24 * hourColumnWidth,
    child: Stack(
      children: [
        Row(
          children: List.generate((24), (index) => Container(
            width: hourColumnWidth,
            height: scheduleRowHeight * 2,
            decoration: BoxDecoration(
              border: Border(left: BorderSide(color: Colors.grey, width: 0)),
            ),
          )),
        ),
        ...routineItems.map((item) { // 루틴 일정 블록 배치
          final double left = timeOfDayToMinutes(item.startTime).toDouble();
          final double width = scheduleDuration(item.startTime, item.endTime).toDouble();
          if (width <= 0) return SizedBox.shrink(); // 길이가 0 이하인 경우 그리지 않음

          return Positioned(
            top: 0, // 윗줄
            left: left,
            width: width,
            height: scheduleRowHeight,
            child: TimetableScheduleBlock(item: item),
          );
        }).toList(),

        ...userItems.map((item) { // 사용자 일정 블록 배치
          final double left = timeOfDayToMinutes(item.startTime).toDouble();
          final double width = scheduleDuration(item.startTime, item.endTime).toDouble();
          if (width <= 0) return SizedBox.shrink(); // 길이가 0 이하인 경우 그리지 않음

          return Positioned(
            top: scheduleRowHeight, // 아랫줄
            left: left,
            width: width,
            height: scheduleRowHeight,
            child: TimetableScheduleBlock(item: item),
          );
        }).toList(),
      ],
    ),
  );
}

Widget DailyTimeline(BuildContext context, DateTime date, List<ScheduleItem> allItems) {
  return Column(
    children: [
      buildWeatherTimeAxis(),
      SizedBox(
        height: 0,
        width: 24 * hourColumnWidth,
        child :Divider(thickness: 1, color: Colors.grey),
      ),
      buildScheduleArea(context, date, allItems),
    ],
  );
}