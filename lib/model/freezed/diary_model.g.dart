// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'diary_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_DiaryModel _$DiaryModelFromJson(Map<String, dynamic> json) => _DiaryModel(
  id: (json['id'] as num?)?.toInt(),
  date: json['date'] as String,
  title: json['title'] as String,
  content: json['content'] as String? ?? '',
  photoPaths:
      (json['photoPaths'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const [],
  userId: json['userId'] as String,
  isSynced: json['isSynced'] as bool? ?? false,
);

Map<String, dynamic> _$DiaryModelToJson(_DiaryModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'date': instance.date,
      'title': instance.title,
      'content': instance.content,
      'photoPaths': instance.photoPaths,
      'userId': instance.userId,
      'isSynced': instance.isSynced,
    };
