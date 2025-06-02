import 'package:freezed_annotation/freezed_annotation.dart';

part 'emotion_model.freezed.dart'; // Corrected part directive
part 'emotion_model.g.dart';

@freezed
abstract class EmotionRecord with _$EmotionRecord {
  @JsonSerializable(explicitToJson: true)
  const factory EmotionRecord({
    required String id,
    required String userId,
    required String date,
    required int hour,
    required String emotionType,
    String? notes,
    @Default(false) bool isSynced,
  }) = _EmotionRecord;

  factory EmotionRecord.fromJson(Map<String, dynamic> json) => _$EmotionRecordFromJson(json);
}

extension EmotionRecordExt on EmotionRecord {
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'date': date,
      'hour': hour,
      'emotionType': emotionType,
      'notes': notes,
      'isSynced': isSynced ? 1 : 0,
    };
  }

  static EmotionRecord fromMap(Map<String, dynamic> map) {
    return EmotionRecord(
      id: map['id'] as String,
      userId: map['userId'] as String,
      date: map['date'] as String,
      hour: map['hour'] as int,
      emotionType: map['emotionType'] as String,
      notes: map['notes'] as String?,
      isSynced: (map['isSynced'] ?? 0) == 1,
    );
  }
}

