// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'daily_location_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_DailyLocationData _$DailyLocationDataFromJson(Map<String, dynamic> json) =>
    _DailyLocationData(
      date: json['date'] as String,
      locations:
          (json['locations'] as List<dynamic>)
              .map((e) => LocationModel.fromJson(e as Map<String, dynamic>))
              .toList(),
    );

Map<String, dynamic> _$DailyLocationDataToJson(_DailyLocationData instance) =>
    <String, dynamic>{'date': instance.date, 'locations': instance.locations};
