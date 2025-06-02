import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:recap_today/model/appusage/app_usage_model.dart';

part 'app_usage_summary_model.freezed.dart';
part 'app_usage_summary_model.g.dart';

@freezed
abstract class AppUsageSummary with _$AppUsageSummary {
  const factory AppUsageSummary({
    required String date,
    required int totalUsageTimeInMillis,
    @Default([]) List<AppUsageModel> topApps,
  }) = _AppUsageSummary;

  factory AppUsageSummary.fromJson(Map<String, dynamic> json) =>
      _$AppUsageSummaryFromJson(json);
}

extension AppUsageSummaryExt on AppUsageSummary {
  Map<String, dynamic> toMap() {
    return {
      'date': date,
      'totalUsageTimeInMillis': totalUsageTimeInMillis,
      'topApps': topApps.map((app) => app.toMap()).toList(),
    };
  }

  static AppUsageSummary fromMap(Map<String, dynamic> map) {
    final List<dynamic> rawApps = map['topApps'] ?? [];
    return AppUsageSummary(
      date: map['date'] as String,
      totalUsageTimeInMillis: (map['totalUsageTimeInMillis'] as num).toInt(),
      topApps: rawApps
          .map((app) => AppUsageModelExt.fromMap(app as Map<String, dynamic>))
          .toList(),
    );
  }
}