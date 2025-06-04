import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:uuid/uuid.dart';

part 'schedule_item.freezed.dart';
part 'schedule_item.g.dart';

// Custom JSON converters for TimeOfDay and Color
class TimeOfDayConverter implements JsonConverter<TimeOfDay, Map<String, dynamic>> {
  const TimeOfDayConverter();

  @override
  TimeOfDay fromJson(Map<String, dynamic> json) {
    return TimeOfDay(hour: json['hour'] as int, minute: json['minute'] as int);
  }

  @override
  Map<String, dynamic> toJson(TimeOfDay time) {
    return {'hour': time.hour, 'minute': time.minute};
  }
}

class ColorConverter implements JsonConverter<Color, int> {
  const ColorConverter();

  @override
  Color fromJson(int json) => Color(json);

  @override
  int toJson(Color color) => color.value;
}

@freezed
abstract class ScheduleItem with _$ScheduleItem {
  const factory ScheduleItem({
    required String id,
    required String text,
    String? subText,
    int? dayOfWeek,
    DateTime? selectedDate,
    required bool isRoutine,
    @TimeOfDayConverter() required TimeOfDay startTime,
    @TimeOfDayConverter() required TimeOfDay endTime,
    @ColorConverter() @Default(Colors.lightBlueAccent) Color? color,
    @Default(false) bool? hasAlarm,
    @Default(Duration(hours: 1)) Duration? alarmOffset,
    required String userId,
    @Default(false) bool isSynced,
  }) = _ScheduleItem;

  factory ScheduleItem.fromJson(Map<String, dynamic> json) => 
      _$ScheduleItemFromJson(json);
      
  /// 신규 일정 생성을 위한 팩토리 생성자
  factory ScheduleItem.create({
    required String text,
    String? subText,
    int? dayOfWeek,
    DateTime? selectedDate,
    required bool isRoutine,
    required TimeOfDay startTime,
    required TimeOfDay endTime,
    Color? color = Colors.lightBlueAccent,
    bool? hasAlarm = false,
    Duration? alarmOffset = const Duration(hours: 1),
    required String userId,
  }) {
    return ScheduleItem(
      id: const Uuid().v4(),
      text: text,
      subText: subText,
      dayOfWeek: dayOfWeek,
      selectedDate: selectedDate,
      isRoutine: isRoutine,
      startTime: startTime,
      endTime: endTime,
      color: color,
      hasAlarm: hasAlarm,
      alarmOffset: alarmOffset,
      userId: userId,
    );
  }
}

extension ScheduleItemX on ScheduleItem {
  /// SQLite를 위한 Map 변환 메서드
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'text': text,
      'sub_text': subText,
      'day_of_week': dayOfWeek,
      'selected_date': selectedDate?.toIso8601String(),
      'is_routine': isRoutine ? 1 : 0,
      'start_time_hour': startTime.hour,
      'start_time_minute': startTime.minute,
      'end_time_hour': endTime.hour,
      'end_time_minute': endTime.minute,
      'color_value': color?.value,
      'has_alarm': hasAlarm == true ? 1 : 0,
      'alarm_offset_in_minutes': alarmOffset?.inMinutes,
      'user_id': userId,
      'is_synced': isSynced ? 1 : 0,
    };
  }

  static ScheduleItem fromMap(Map<String, dynamic> map) {
    DateTime? date;
    if (map['selected_date'] != null) {
      try {
        date = DateTime.parse(map['selected_date']);
      } catch (e) {
        debugPrint('날짜 파싱 오류: $e');
      }
    }

    return ScheduleItem(
      id: map['id'] as String,
      text: map['text'] as String,
      subText: map['sub_text'] as String?,
      dayOfWeek: map['day_of_week'] as int?,
      selectedDate: date,
      isRoutine: (map['is_routine'] as int?) == 1,
      startTime: TimeOfDay(
        hour: (map['start_time_hour'] as int?) ?? 0,
        minute: (map['start_time_minute'] as int?) ?? 0,
      ),
      endTime: TimeOfDay(
        hour: (map['end_time_hour'] as int?) ?? 0,
        minute: (map['end_time_minute'] as int?) ?? 0,
      ),
      color: map['color_value'] != null ? Color(map['color_value'] as int) : Colors.lightBlueAccent,
      hasAlarm: (map['has_alarm'] as int?) == 1,
      alarmOffset: map['alarm_offset_in_minutes'] != null 
          ? Duration(minutes: map['alarm_offset_in_minutes'] as int) 
          : const Duration(hours: 1),
      userId: map['user_id'] as String? ?? '',
      isSynced: (map['is_synced'] as int?) == 1,
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
