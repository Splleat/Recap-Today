import 'package:freezed_annotation/freezed_annotation.dart';

part 'ai_feedback_model.freezed.dart';
part 'ai_feedback_model.g.dart';

@freezed
abstract class AiFeedbackModel with _$AiFeedbackModel {
  const factory AiFeedbackModel({
    int? id,
    required String date,
    required String feedback_text,
    required String userId,
    @Default(false) bool isSynced,
  }) = _AiFeedbackModel;

  factory AiFeedbackModel.fromJson(Map<String, dynamic> json) =>
      _$AiFeedbackModelFromJson(json);
}

/// Extension to help with database operations
extension AiFeedbackModelX on AiFeedbackModel {
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'date': date,
      'feedback_text': feedback_text,
      'user_id': userId,
      'is_synced': isSynced ? 1 : 0,
    };
  }

  static AiFeedbackModel fromMap(Map<String, dynamic> map) {
    return AiFeedbackModel(
      id: map['id'] as int?,
      date: map['date'] as String,
      feedback_text: map['feedback_text'] as String,
      userId: map['user_id'] as String,
      isSynced: (map['is_synced'] as int?) == 1,
    );
  }
}