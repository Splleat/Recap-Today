import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'schedule_item.freezed.dart';
part 'schedule_item.g.dart';

class TimeOfDayConverter implements JsonConverter<TimeOfDay, String> {
  const TimeOfDayConverter();

  @override
  TimeOfDay fromJson(String json) {
    final parts = json.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  @override
  String toJson(TimeOfDay object) {
    return '${object.hour}:${object.minute}';
  }
}

class ColorConverter implements JsonConverter<Color?, int?> {
  const ColorConverter();

  @override
  Color? fromJson(int? json) => json != null ? Color(json) : null;

  @override
  int? toJson(Color? object) => object?.value;
}

class DurationConverter implements JsonConverter<Duration?, int?> {
  const DurationConverter();

  @override
  Duration? fromJson(int? json) => json != null ? Duration(milliseconds: json) : null;

  @override
  int? toJson(Duration? object) => object?.inMilliseconds;
}

@freezed
abstract class ScheduleItem with _$ScheduleItem {
  const factory ScheduleItem({
    required String id,
    required String userId,
    required String text,
    String? subText,
    int? dayOfWeek,
    DateTime? selectedDate,
    required bool isRoutine,
    @TimeOfDayConverter() required TimeOfDay startTime,
    @TimeOfDayConverter() required TimeOfDay endTime,
    @ColorConverter() Color? color,
    bool? hasAlarm,
    @DurationConverter() Duration? alarmOffset,
    @Default(false) bool isSynced,
  }) = _ScheduleItem;

  factory ScheduleItem.fromJson(Map<String, dynamic> json) =>
      _$ScheduleItemFromJson(json);
}

extension ScheduleItemExt on ScheduleItem {
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'text': text,
      'subText': subText,
      'dayOfWeek': dayOfWeek,
      'selectedDate': selectedDate?.toIso8601String(),
      'isRoutine': isRoutine ? 1 : 0,
      'startTime': '${startTime.hour}:${startTime.minute}',
      'endTime': '${endTime.hour}:${endTime.minute}',
      'color': color?.value,
      'hasAlarm': hasAlarm == true ? 1 : 0,
      'alarmOffset': alarmOffset?.inMilliseconds,
      'isSynced': isSynced ? 1 : 0,
    };
  }

  static ScheduleItem fromMap(Map<String, dynamic> map) {
    final timeOfDay = (String timeStr) {
      final parts = timeStr.split(':');
      return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
    };

    return ScheduleItem(
      id: map['id'],
      userId: map['userId'],
      text: map['text'],
      subText: map['subText'],
      dayOfWeek: map['dayOfWeek'],
      selectedDate: map['selectedDate'] != null
          ? DateTime.parse(map['selectedDate'])
          : null,
      isRoutine: (map['isRoutine'] ?? 0) == 1,
      startTime: timeOfDay(map['startTime']),
      endTime: timeOfDay(map['endTime']),
      color: map['color'] != null ? Color(map['color']) : null,
      hasAlarm: (map['hasAlarm'] ?? 0) == 1,
      alarmOffset: map['alarmOffset'] != null
          ? Duration(milliseconds: map['alarmOffset'])
          : null,
      isSynced: (map['isSynced'] ?? 0) == 1,
    );
  }
}
