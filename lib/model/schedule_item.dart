import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

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

  /// 신규 일정 생성 시 사용하는 생성자
  /// ID는 자동 생성됩니다
  ScheduleItem.create({
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
  }) : id = const Uuid().v4();

  /// 기존 일정을 위한 생성자
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

  // SQLite를 위한 Map 변환 메서드
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'text': text,
      'subText': subText,
      'dayOfWeek': dayOfWeek,
      'selectedDate': selectedDate?.toIso8601String(),
      'isRoutine': isRoutine ? 1 : 0,
      'startTimeHour': startTime.hour,
      'startTimeMinute': startTime.minute,
      'endTimeHour': endTime.hour,
      'endTimeMinute': endTime.minute,
      'colorValue': color?.value,
      'hasAlarm': hasAlarm == true ? 1 : 0,
      'alarmOffsetInMinutes': alarmOffset?.inMinutes,
    };
  }

  // Map에서 객체 생성을 위한 팩토리 메서드
  factory ScheduleItem.fromMap(Map<String, dynamic> map) {
    DateTime? date;
    if (map['selectedDate'] != null) {
      try {
        date = DateTime.parse(map['selectedDate']);
      } catch (e) {
        debugPrint('날짜 파싱 오류: $e');
      }
    }

    return ScheduleItem(
      id: map['id'],
      text: map['text'],
      subText: map['subText'],
      dayOfWeek: map['dayOfWeek'],
      selectedDate: date,
      isRoutine: map['isRoutine'] == 1,
      startTime: TimeOfDay(
        hour: map['startTimeHour'] ?? 0,
        minute: map['startTimeMinute'] ?? 0,
      ),
      endTime: TimeOfDay(
        hour: map['endTimeHour'] ?? 0,
        minute: map['endTimeMinute'] ?? 0,
      ),
      color:
          map['colorValue'] != null
              ? Color(map['colorValue'])
              : Colors.lightBlueAccent,
      hasAlarm: map['hasAlarm'] == 1,
      alarmOffset:
          map['alarmOffsetInMinutes'] != null
              ? Duration(minutes: map['alarmOffsetInMinutes'])
              : const Duration(hours: 1),
    );
  }

  /// 시작 시간을 24시간 형식의 double 값으로 변환 (정렬용)
  double get startTimeValue => startTime.hour + (startTime.minute / 60.0);

  /// 종료 시간을 24시간 형식의 double 값으로 변환 (정렬용)
  double get endTimeValue => endTime.hour + (endTime.minute / 60.0);

  /// 일정 시간이 서로 겹치는지 확인
  bool overlapsWith(ScheduleItem other) {
    // 요일이나 날짜가 다르면 겹치지 않음
    if (isRoutine && other.isRoutine) {
      if (dayOfWeek != other.dayOfWeek) return false;
    } else if (!isRoutine && !other.isRoutine) {
      if (selectedDate?.year != other.selectedDate?.year ||
          selectedDate?.month != other.selectedDate?.month ||
          selectedDate?.day != other.selectedDate?.day) {
        return false;
      }
    } else {
      // 하나는 루틴이고 하나는 일회성이면 비교 불가
      return false;
    }

    // 시간 비교: [a시작, a종료]와 [b시작, b종료]가 겹치는지 확인
    return (startTimeValue <= other.endTimeValue) &&
        (endTimeValue >= other.startTimeValue);
  }
}
