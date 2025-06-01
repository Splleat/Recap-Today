import 'package:freezed_annotation/freezed_annotation.dart';

part 'app_usage_model.freezed.dart';
part 'app_usage_model.g.dart';

@freezed
abstract class AppUsageModel with _$AppUsageModel {
  const factory AppUsageModel({
    String? id,
    required String date,
    required String packageName,
    required String appName,
    required int usageTimeInMillis,
    String? appIconPath,
    DateTime?
    lastSynced, // Legacy, consider for removal if updatedAt and syncStatus cover all needs
    @Default(false) bool isDeleted,
    String? clientTempId,
    String? serverId,
    String? syncStatus, // Stores SyncStatus.name (e.g., 'created', 'synced')
    DateTime? updatedAt, // Timestamp of last local modification or sync event
  }) = _AppUsageModel;  factory AppUsageModel.fromJson(Map<String, dynamic> json) =>
      _$AppUsageModelFromJson(json);
}

extension AppUsageModelExtension on AppUsageModel {
  Map<String, dynamic> toSyncMap() {
    return toJson(); // Use the generated toJson method for sync
  }
}

@freezed
abstract class AppUsageSummary with _$AppUsageSummary {
  const factory AppUsageSummary({
    required String date,
    required int totalUsageTimeInMillis,
    required List<AppUsageModel> topApps,
  }) = _AppUsageSummary;

  factory AppUsageSummary.fromJson(Map<String, dynamic> json) =>
      _$AppUsageSummaryFromJson(json);
}
