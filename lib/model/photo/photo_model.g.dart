// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'photo_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Photo _$PhotoFromJson(Map<String, dynamic> json) => _Photo(
  diaryId: json['diaryId'] as String,
  path: json['path'] as String,
  isSynced: json['isSynced'] as bool? ?? false,
);

Map<String, dynamic> _$PhotoToJson(_Photo instance) => <String, dynamic>{
  'diaryId': instance.diaryId,
  'path': instance.path,
  'isSynced': instance.isSynced,
};
