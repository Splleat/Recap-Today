// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'diary_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Diary _$DiaryFromJson(Map<String, dynamic> json) => _Diary(
  id: json['id'] as String?,
  userId: json['userId'] as String,
  date: json['date'] as String,
  title: json['title'] as String,
  content: json['content'] as String?,
  photoPaths:
      (json['photoPaths'] as List<dynamic>).map((e) => e as String).toList(),
  createdAt: DateTime.parse(json['createdAt'] as String),
  isSynced: json['isSynced'] as bool? ?? false,
);

Map<String, dynamic> _$DiaryToJson(_Diary instance) => <String, dynamic>{
  'id': instance.id,
  'userId': instance.userId,
  'date': instance.date,
  'title': instance.title,
  'content': instance.content,
  'photoPaths': instance.photoPaths,
  'createdAt': instance.createdAt.toIso8601String(),
  'isSynced': instance.isSynced,
};
