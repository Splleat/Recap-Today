import 'package:freezed_annotation/freezed_annotation.dart';

part 'checklist_item.freezed.dart';
part 'checklist_item.g.dart';

@freezed
abstract class ChecklistItem with _$ChecklistItem {
  const factory ChecklistItem({
    required String id,
    required String userId,
    required String text,
    String? subtext,
    @Default(false) bool isChecked,
    DateTime? dueDate,
    DateTime? completedDate,
    @Default(false) bool isSynced,
  }) = _ChecklistItem;

  factory ChecklistItem.fromJson(Map<String, dynamic> json) =>
      _$ChecklistItemFromJson(json);
}

extension ChecklistItemExt on ChecklistItem {
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'text': text,
      'subtext': subtext,
      'isChecked': isChecked ? 1 : 0,
      'dueDate': dueDate?.toIso8601String(),
      'completedDate': completedDate?.toIso8601String(),
      'isSynced': isSynced ? 1 : 0,
    };
  }

  static ChecklistItem fromMap(Map<String, dynamic> map) {
    return ChecklistItem(
      id: map['id'] as String,
      userId: map['userId'] as String,
      text: map['text'] as String,
      subtext: map['subtext'] as String?,
      isChecked: (map['isChecked'] as int) == 1,
      dueDate: map['dueDate'] != null
          ? DateTime.parse(map['dueDate'])
          : null,
      completedDate: map['completedDate'] != null
          ? DateTime.parse(map['completedDate'])
          : null,
      isSynced: (map['isSynced'] as int) == 1,
    );
  }
}
