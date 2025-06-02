// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'schedule_item.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ScheduleItem _$ScheduleItemFromJson(Map<String, dynamic> json) =>
    _ScheduleItem(
      id: json['id'] as String,
      userId: json['userId'] as String,
      text: json['text'] as String,
      subText: json['subText'] as String?,
      dayOfWeek: (json['dayOfWeek'] as num?)?.toInt(),
      selectedDate:
          json['selectedDate'] == null
              ? null
              : DateTime.parse(json['selectedDate'] as String),
      isRoutine: json['isRoutine'] as bool,
      startTime: const TimeOfDayConverter().fromJson(
        json['startTime'] as String,
      ),
      endTime: const TimeOfDayConverter().fromJson(json['endTime'] as String),
      color: const ColorConverter().fromJson((json['color'] as num?)?.toInt()),
      hasAlarm: json['hasAlarm'] as bool?,
      alarmOffset: const DurationConverter().fromJson(
        (json['alarmOffset'] as num?)?.toInt(),
      ),
      isSynced: json['isSynced'] as bool? ?? false,
    );

Map<String, dynamic> _$ScheduleItemToJson(_ScheduleItem instance) =>
    <String, dynamic>{
      'id': instance.id,
      'userId': instance.userId,
      'text': instance.text,
      'subText': instance.subText,
      'dayOfWeek': instance.dayOfWeek,
      'selectedDate': instance.selectedDate?.toIso8601String(),
      'isRoutine': instance.isRoutine,
      'startTime': const TimeOfDayConverter().toJson(instance.startTime),
      'endTime': const TimeOfDayConverter().toJson(instance.endTime),
      'color': const ColorConverter().toJson(instance.color),
      'hasAlarm': instance.hasAlarm,
      'alarmOffset': const DurationConverter().toJson(instance.alarmOffset),
      'isSynced': instance.isSynced,
    };
