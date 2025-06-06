// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ai_feedback_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_AiFeedbackModel _$AiFeedbackModelFromJson(Map<String, dynamic> json) =>
    _AiFeedbackModel(
      id: (json['id'] as num?)?.toInt(),
      date: json['date'] as String,
      feedback_text: json['feedback_text'] as String,
      userId: json['userId'] as String,
      isSynced: json['isSynced'] as bool? ?? false,
    );

Map<String, dynamic> _$AiFeedbackModelToJson(_AiFeedbackModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'date': instance.date,
      'feedback_text': instance.feedback_text,
      'userId': instance.userId,
      'isSynced': instance.isSynced,
    };
