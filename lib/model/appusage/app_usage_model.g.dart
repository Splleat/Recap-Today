// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_usage_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_AppUsageModel _$AppUsageModelFromJson(Map<String, dynamic> json) =>
    _AppUsageModel(
      id: json['id'] as String,
      userId: json['userId'] as String,
      date: json['date'] as String,
      packageName: json['packageName'] as String,
      appName: json['appName'] as String,
      usageTimeInMillis: (json['usageTimeInMillis'] as num).toInt(),
      appIconPath: json['appIconPath'] as String?,
      isSynced: json['isSynced'] as bool? ?? false,
    );

Map<String, dynamic> _$AppUsageModelToJson(_AppUsageModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'userId': instance.userId,
      'date': instance.date,
      'packageName': instance.packageName,
      'appName': instance.appName,
      'usageTimeInMillis': instance.usageTimeInMillis,
      'appIconPath': instance.appIconPath,
      'isSynced': instance.isSynced,
    };
