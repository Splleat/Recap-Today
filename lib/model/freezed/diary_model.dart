import 'package:freezed_annotation/freezed_annotation.dart';

part 'diary_model.freezed.dart';
part 'diary_model.g.dart';

@freezed
abstract class DiaryModel with _$DiaryModel {
  const factory DiaryModel({
    int? id,
    required String date,
    required String title,
    @Default('') String content,
    @Default([]) List<String> photoPaths,
    required String userId,
    @Default(false) bool isSynced,
  }) = _DiaryModel;

  factory DiaryModel.fromJson(Map<String, dynamic> json) => 
      _$DiaryModelFromJson(json);
}

extension DiaryModelX on DiaryModel {
  /// Map으로 변환 (데이터베이스 저장용)
  Map<String, dynamic> toMap() {
    return {
      'id': id, 
      'date': date, 
      'title': title, 
      'content': content,
      'user_id': userId,
      'is_synced': isSynced ? 1 : 0,
      // Note: photoPaths would need to be stored separately
    };
  }

  static DiaryModel fromMap(Map<String, dynamic> map, [List<String> photoPaths = const []]) {
    return DiaryModel(
      id: map['id'] as int?,
      date: map['date'] as String,
      title: map['title'] as String,
      content: map['content'] as String? ?? '',
      photoPaths: photoPaths,
      userId: map['user_id'] as String? ?? '',
      isSynced: (map['is_synced'] as int?) == 1,
    );
  }
}
