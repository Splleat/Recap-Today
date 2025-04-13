import 'package:flutter/material.dart';

class TimetableItem {
  final String id;
  String text; // 루틴 이름 (예: 수학 수업)
  String subText;
  int dayOfWeek; // 요일 (1: 월요일, 2: 화요일, ..., 7: 일요일)
  TimeOfDay startTime; // 시작 시간
  TimeOfDay endTime; // 종료 시간
  Color color; // 일정 색상

  TimetableItem({
    required this.id,
    required this.text,
    required this.subText,
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    this.color = Colors.orangeAccent, // 기본 색상
  });

  TimetableItem copyWith({
    String? id,
    String? text,
    String? subText,
    int? dayOfWeek,
    TimeOfDay? startTime,
    TimeOfDay? endTime,
    Color? color,
  }) {
    return TimetableItem(
      id: id ?? this.id,
      text: text ?? this.text,
      subText: subText ?? this.subText,
      dayOfWeek: dayOfWeek ?? this.dayOfWeek,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      color: color ?? this.color,
    );
  }
}