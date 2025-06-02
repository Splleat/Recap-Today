// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'checklist_item.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ChecklistItem _$ChecklistItemFromJson(Map<String, dynamic> json) =>
    _ChecklistItem(
      id: json['id'] as String,
      userId: json['userId'] as String,
      text: json['text'] as String,
      subtext: json['subtext'] as String?,
      isChecked: json['isChecked'] as bool? ?? false,
      dueDate:
          json['dueDate'] == null
              ? null
              : DateTime.parse(json['dueDate'] as String),
      completedDate:
          json['completedDate'] == null
              ? null
              : DateTime.parse(json['completedDate'] as String),
      isSynced: json['isSynced'] as bool? ?? false,
    );

Map<String, dynamic> _$ChecklistItemToJson(_ChecklistItem instance) =>
    <String, dynamic>{
      'id': instance.id,
      'userId': instance.userId,
      'text': instance.text,
      'subtext': instance.subtext,
      'isChecked': instance.isChecked,
      'dueDate': instance.dueDate?.toIso8601String(),
      'completedDate': instance.completedDate?.toIso8601String(),
      'isSynced': instance.isSynced,
    };
