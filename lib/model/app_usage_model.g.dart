// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_usage_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_AppUsageModel _$AppUsageModelFromJson(Map<String, dynamic> json) =>
    _AppUsageModel(
      id: json['id'] as String?,
      date: json['date'] as String,
      packageName: json['packageName'] as String,
      appName: json['appName'] as String,
      usageTimeInMillis: (json['usageTimeInMillis'] as num).toInt(),
      appIconPath: json['appIconPath'] as String?,
      lastSynced:
          json['lastSynced'] == null
              ? null
              : DateTime.parse(json['lastSynced'] as String),
      isDeleted: json['isDeleted'] as bool? ?? false,
      clientTempId: json['clientTempId'] as String?,
      serverId: json['serverId'] as String?,
      syncStatus: json['syncStatus'] as String?,
      updatedAt:
          json['updatedAt'] == null
              ? null
              : DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$AppUsageModelToJson(_AppUsageModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'date': instance.date,
      'packageName': instance.packageName,
      'appName': instance.appName,
      'usageTimeInMillis': instance.usageTimeInMillis,
      'appIconPath': instance.appIconPath,
      'lastSynced': instance.lastSynced?.toIso8601String(),
      'isDeleted': instance.isDeleted,
      'clientTempId': instance.clientTempId,
      'serverId': instance.serverId,
      'syncStatus': instance.syncStatus,
      'updatedAt': instance.updatedAt?.toIso8601String(),
    };

_AppUsageSummary _$AppUsageSummaryFromJson(Map<String, dynamic> json) =>
    _AppUsageSummary(
      date: json['date'] as String,
      totalUsageTimeInMillis: (json['totalUsageTimeInMillis'] as num).toInt(),
      topApps:
          (json['topApps'] as List<dynamic>)
              .map((e) => AppUsageModel.fromJson(e as Map<String, dynamic>))
              .toList(),
    );

Map<String, dynamic> _$AppUsageSummaryToJson(_AppUsageSummary instance) =>
    <String, dynamic>{
      'date': instance.date,
      'totalUsageTimeInMillis': instance.totalUsageTimeInMillis,
      'topApps': instance.topApps,
    };
