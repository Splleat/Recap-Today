import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class ScheduleItem {
  final String id;
  String text; // 일정 이름
  String? subText; // 일정의 세부 정보
  int? dayOfWeek; // 요일
  DateTime? selectedDate; // 날짜
  bool isRoutine; // 루틴 일정 / 사용자 일정 (반복 / 일회성)
  TimeOfDay startTime; // 시작 시간
  TimeOfDay endTime; // 종료 시간
  Color? color; // 일정 색상
  bool? hasAlarm; // 알림 설정 여부
  Duration? alarmOffset; // 알림 시간 간격

  ScheduleItem({
    required this.id,
    required this.text,
    this.subText,
    this.dayOfWeek,
    this.selectedDate,
    required this.isRoutine,
    required this.startTime,
    required this.endTime,
    this.color = Colors.lightBlueAccent,
    this.hasAlarm = false,
    this.alarmOffset = const Duration(hours: 1),
  });

  ScheduleItem copyWith({
    String? id,
    String? text,
    String? subText,
    int? dayOfWeek,
    DateTime? date,
    bool? isRoutine,
    TimeOfDay? startTime,
    TimeOfDay? endTime,
    Color? color,
    bool? hasAlarm,
    Duration? alarmOffset,
  }) {
    return ScheduleItem(
      id: id ?? this.id,
      text: text ?? this.text,
      subText: subText ?? this.subText,
      dayOfWeek: dayOfWeek ?? this.dayOfWeek,
      selectedDate: date ?? this.selectedDate,
      isRoutine: isRoutine ?? this.isRoutine,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      color: color ?? this.color,
      hasAlarm: hasAlarm ?? this.hasAlarm,
      alarmOffset: alarmOffset ?? this.alarmOffset,
    );
  }
}