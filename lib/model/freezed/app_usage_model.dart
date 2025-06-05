import 'package:freezed_annotation/freezed_annotation.dart';

part 'app_usage_model.freezed.dart';
part 'app_usage_model.g.dart';

@freezed
abstract class AppUsageModel with _$AppUsageModel {
  const factory AppUsageModel({
    int? id,
    required String date,
    required String packageName,
    required String appName,
    required int usageTimeInMillis,
    String? appIconPath,
    required String userId,
    @Default(false) bool isSynced,
  }) = _AppUsageModel;

  factory AppUsageModel.fromJson(Map<String, dynamic> json) =>
      _$AppUsageModelFromJson(json);
}

@freezed
abstract class AppUsageSummary with _$AppUsageSummary {
  const factory AppUsageSummary({
    required String date,
    required int totalUsageTimeInMillis,
    required List<AppUsageModel> topApps,
    required String userId,
    @Default(false) bool isSynced,
  }) = _AppUsageSummary;

  factory AppUsageSummary.fromJson(Map<String, dynamic> json) =>
      _$AppUsageSummaryFromJson(json);
}

extension AppUsageModelX on AppUsageModel {
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date,
      'package_name': packageName,
      'app_name': appName,
      'usage_time': usageTimeInMillis,
      'app_icon_path': appIconPath,
      'user_id': userId,
      'is_synced': isSynced ? 1 : 0,
    };
  }

  static AppUsageModel fromMap(Map<String, dynamic> map) {
    return AppUsageModel(
      id: map['id'] as int?,
      date: map['date'] as String,
      packageName: map['package_name'] as String,
      appName: map['app_name'] as String,
      usageTimeInMillis: map['usage_time'] as int,
      appIconPath: map['app_icon_path'] as String?,
      userId: map['user_id'] as String,
      isSynced: (map['is_synced'] as int?) == 1,
    );
  }
}

extension AppUsageSummaryX on AppUsageSummary {
  Map<String, dynamic> toMap() {
    return {
      'date': date,
      'total_usage_time': totalUsageTimeInMillis,
      'user_id': userId,
      'is_synced': isSynced ? 1 : 0,
      // Top apps would need to be stored separately
    };
  }

  static AppUsageSummary fromMap(Map<String, dynamic> map, List<AppUsageModel> topApps) {
    return AppUsageSummary(
      date: map['date'] as String,
      totalUsageTimeInMillis: map['total_usage_time'] as int,
      topApps: topApps,
      userId: map['user_id'] as String,
      isSynced: (map['is_synced'] as int?) == 1,
    );
  }
}
