// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'schedule_item.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ScheduleItem _$ScheduleItemFromJson(Map<String, dynamic> json) =>
    _ScheduleItem(
      id: json['id'] as String,
      text: json['text'] as String,
      subText: json['subText'] as String?,
      dayOfWeek: (json['dayOfWeek'] as num?)?.toInt(),
      selectedDate:
          json['selectedDate'] == null
              ? null
              : DateTime.parse(json['selectedDate'] as String),
      isRoutine: json['isRoutine'] as bool,
      startTime: const TimeOfDayConverter().fromJson(
        json['startTime'] as Map<String, dynamic>,
      ),
      endTime: const TimeOfDayConverter().fromJson(
        json['endTime'] as Map<String, dynamic>,
      ),
      color:
          _$JsonConverterFromJson<int, Color>(
            json['color'],
            const ColorConverter().fromJson,
          ) ??
          Colors.lightBlueAccent,
      hasAlarm: json['hasAlarm'] as bool? ?? false,
      alarmOffset:
          json['alarmOffset'] == null
              ? const Duration(hours: 1)
              : Duration(microseconds: (json['alarmOffset'] as num).toInt()),
      userId: json['userId'] as String,
      isSynced: json['isSynced'] as bool? ?? false,
    );

Map<String, dynamic> _$ScheduleItemToJson(_ScheduleItem instance) =>
    <String, dynamic>{
      'id': instance.id,
      'text': instance.text,
      'subText': instance.subText,
      'dayOfWeek': instance.dayOfWeek,
      'selectedDate': instance.selectedDate?.toIso8601String(),
      'isRoutine': instance.isRoutine,
      'startTime': const TimeOfDayConverter().toJson(instance.startTime),
      'endTime': const TimeOfDayConverter().toJson(instance.endTime),
      'color': _$JsonConverterToJson<int, Color>(
        instance.color,
        const ColorConverter().toJson,
      ),
      'hasAlarm': instance.hasAlarm,
      'alarmOffset': instance.alarmOffset?.inMicroseconds,
      'userId': instance.userId,
      'isSynced': instance.isSynced,
    };

Value? _$JsonConverterFromJson<Json, Value>(
  Object? json,
  Value? Function(Json json) fromJson,
) => json == null ? null : fromJson(json as Json);

Json? _$JsonConverterToJson<Json, Value>(
  Value? value,
  Json? Function(Value value) toJson,
) => value == null ? null : toJson(value);
