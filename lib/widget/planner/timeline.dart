import 'package:flutter/material.dart';
import 'package:recap_today/model/freezed/schedule_item.dart';
import 'package:recap_today/utils/time_util.dart';
import 'package:recap_today/widget/planner/timetable.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:recap_today/model/full_weather_model.dart';


const hourColumnWidth = 60.0;

IconData getWeatherIcon(String sky) {
  switch (sky) {
    case '맑음':
      return Icons.wb_sunny_rounded;
    case '구름많음':
      return Icons.cloud_queue_rounded;
    case '흐림':
      return Icons.cloud_rounded;
    case '비':
      return Icons.beach_access_rounded;
    case '눈':
      return Icons.ac_unit_rounded;
    case '소나기':
      return Icons.shower_rounded;
    default:
      return Icons.help_outline_rounded;
  }
}

Widget buildWeatherTimeAxis(List<WeatherData>? weatherList) {
  return Row(
    children: List.generate(24, (hourIndex) {
      final hourStr = '${hourIndex.toString().padLeft(2, '0')}시';
      WeatherData? weather;
      if (weatherList != null) {
        try {
          weather = weatherList.firstWhere((w) => w.time == hourStr);
        } catch (_) {
          weather = null;
        }
      }

      // 날씨 정보 출력
      return Container(
        width: hourColumnWidth,
        padding: const EdgeInsets.symmetric(vertical: 6.0),
        decoration: BoxDecoration(
          border: Border(
            right: BorderSide(color: Colors.grey, width: 0),
            left: hourIndex == 0 ? BorderSide(color: Colors.grey, width: 0) : BorderSide.none,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: weather == null
          ? [
            Text('-'),
            Icon(Icons.help_outline_rounded),
            Text('-'),
            Text(hourStr),
          ]
          : [
            Text(weather.temperature),
            Icon(getWeatherIcon(weather.sky)),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.opacity_rounded,
                  size: 16,
                ),
                Text(weather.precipitationProbability),
              ],
            ),
            Text(hourStr),
          ],
        ),
      );
    }),
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
          children: List.generate(24, (index) => Container(
            width: hourColumnWidth,
            height: scheduleRowHeight * 2,
            decoration: const BoxDecoration(
              border: Border(left: BorderSide(color: Colors.grey, width: 0)),
            ),
          )),
        ),
        ...routineItems.map((item) {
          final double left = timeOfDayToMinutes(item.startTime).toDouble();
          final double width = scheduleDuration(item.startTime, item.endTime).toDouble();
          if (width <= 0) return const SizedBox.shrink();

          return Positioned(
            top: 0,
            left: left,
            width: width,
            height: scheduleRowHeight,
            child: TimetableScheduleBlock(item: item),
          );
        }).toList(),
        ...userItems.map((item) {
          final double left = timeOfDayToMinutes(item.startTime).toDouble();
          final double width = scheduleDuration(item.startTime, item.endTime).toDouble();
          if (width <= 0) return const SizedBox.shrink();

          return Positioned(
            top: scheduleRowHeight,
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

Widget DailyTimeline(BuildContext context, DateTime date, List<ScheduleItem> allItems, List<WeatherData>? weatherList) {
  return Column(
    children: [
      buildWeatherTimeAxis(weatherList),
      const SizedBox(
        height: 0,
        width: 24 * hourColumnWidth,
        child: Divider(thickness: 1, color: Colors.grey),
      ),
      buildScheduleArea(context, date, allItems),
    ],
  );
}