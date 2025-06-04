// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'step_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_StepModel _$StepModelFromJson(Map<String, dynamic> json) => _StepModel(
  date: DateTime.parse(json['date'] as String),
  stepCount: (json['stepCount'] as num).toInt(),
  userId: json['userId'] as String,
  isSynced: json['isSynced'] as bool? ?? false,
);

Map<String, dynamic> _$StepModelToJson(_StepModel instance) =>
    <String, dynamic>{
      'date': instance.date.toIso8601String(),
      'stepCount': instance.stepCount,
      'userId': instance.userId,
      'isSynced': instance.isSynced,
    };
