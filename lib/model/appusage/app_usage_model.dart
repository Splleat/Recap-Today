import 'package:freezed_annotation/freezed_annotation.dart';

part 'app_usage_model.freezed.dart';
part 'app_usage_model.g.dart';

@freezed
abstract class AppUsageModel with _$AppUsageModel {
  const factory AppUsageModel({
    required String id,
    required String userId,
    required String date,
    required String packageName,
    required String appName,
    required int usageTimeInMillis,
    String? appIconPath,
    @Default(false) bool isSynced,
  }) = _AppUsageModel;

  factory AppUsageModel.fromJson(Map<String, dynamic> json) =>
      _$AppUsageModelFromJson(json);
}

extension AppUsageModelExt on AppUsageModel {
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'date': date,
      'packageName': packageName,
      'appName': appName,
      'usageTimeInMillis': usageTimeInMillis,
      'appIconPath': appIconPath,
      'isSynced': isSynced ? 1 : 0,
    };
  }

  static AppUsageModel fromMap(Map<String, dynamic> map) {
    return AppUsageModel(
      id: map['id'] as String,
      userId: map['userId'] as String,
      date: map['date'] as String,
      packageName: map['packageName'] as String,
      appName: map['appName'] as String,
      usageTimeInMillis: (map['usageTimeInMillis'] as num).toInt(),
      appIconPath: map['appIconPath'] as String?,
      isSynced: (map['isSynced'] as int) == 1,
    );
  }
}



