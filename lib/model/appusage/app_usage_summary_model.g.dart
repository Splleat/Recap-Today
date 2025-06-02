// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_usage_summary_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_AppUsageSummary _$AppUsageSummaryFromJson(Map<String, dynamic> json) =>
    _AppUsageSummary(
      date: json['date'] as String,
      totalUsageTimeInMillis: (json['totalUsageTimeInMillis'] as num).toInt(),
      topApps:
          (json['topApps'] as List<dynamic>?)
              ?.map((e) => AppUsageModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );

Map<String, dynamic> _$AppUsageSummaryToJson(_AppUsageSummary instance) =>
    <String, dynamic>{
      'date': instance.date,
      'totalUsageTimeInMillis': instance.totalUsageTimeInMillis,
      'topApps': instance.topApps,
    };
