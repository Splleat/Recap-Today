import 'package:freezed_annotation/freezed_annotation.dart';

part 'emotion_model.freezed.dart';
part 'emotion_model.g.dart';

@freezed
abstract class EmotionRecord with _$EmotionRecord {
  const factory EmotionRecord({
    String? id,
    required String date,
    required int hour,
    required String emotionType,
    String? notes,
    required String userId,
    @Default(false) bool isSynced,
  }) = _EmotionRecord;

  factory EmotionRecord.fromJson(Map<String, dynamic> json) =>
      _$EmotionRecordFromJson(json);
}

extension EmotionRecordX on EmotionRecord {
  /// Method to convert EmotionRecord to a Map for database insertion
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date,
      'hour': hour,
      'emotion_type': emotionType,
      'notes': notes,
      'user_id': userId,
      'is_synced': isSynced ? 1 : 0,
    };
  }

  static EmotionRecord fromMap(Map<String, dynamic> map) {
    return EmotionRecord(
      id: map['id'] as String?,
      date: map['date'] as String,
      hour: map['hour'] as int,
      emotionType: map['emotion_type'] as String,
      notes: map['notes'] as String?,
      userId: map['user_id'] as String? ?? '',
      isSynced: (map['is_synced'] as int?) == 1,
    );
  }
}
