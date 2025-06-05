import 'package:freezed_annotation/freezed_annotation.dart';

part 'step_model.freezed.dart';
part 'step_model.g.dart';

@freezed
abstract class StepModel with _$StepModel {
  const factory StepModel({
    required String date,
    required int stepCount,
    required String userId,
    @Default(false) bool isSynced,
  }) = _StepModel;

  factory StepModel.fromJson(Map<String, dynamic> json) =>
      _$StepModelFromJson(json);
}

extension StepModelX on StepModel {
  /// Convert StepModel to Map for local storage
  Map<String, dynamic> toMap() {
    // 날짜 포맷을 yyyy-MM-dd로 통일
    return {
      'date': date,
      'step_count': stepCount,
      'user_id': userId,
      'is_synced': isSynced ? 1 : 0,
    };
  }

  static StepModel fromMap(Map<String, dynamic> map) {
    return StepModel(
      date: map['date'] as String,
      stepCount: map['step_count'] as int,
      userId: map['user_id'] as String,
      isSynced: (map['is_synced'] as int?) == 1,
    );
  }
}