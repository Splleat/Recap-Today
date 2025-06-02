// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'emotion_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_EmotionRecord _$EmotionRecordFromJson(Map<String, dynamic> json) =>
    _EmotionRecord(
      id: json['id'] as String,
      userId: json['userId'] as String,
      date: json['date'] as String,
      hour: (json['hour'] as num).toInt(),
      emotionType: json['emotionType'] as String,
      notes: json['notes'] as String?,
      isSynced: json['isSynced'] as bool? ?? false,
    );

Map<String, dynamic> _$EmotionRecordToJson(_EmotionRecord instance) =>
    <String, dynamic>{
      'id': instance.id,
      'userId': instance.userId,
      'date': instance.date,
      'hour': instance.hour,
      'emotionType': instance.emotionType,
      'notes': instance.notes,
      'isSynced': instance.isSynced,
    };
