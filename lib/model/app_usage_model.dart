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
  }) = _AppUsageSummary;

  factory AppUsageSummary.fromJson(Map<String, dynamic> json) =>
      _$AppUsageSummaryFromJson(json);
}
