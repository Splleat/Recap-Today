import 'dart:convert';
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
      'photo_paths': jsonEncode(photoPaths), // JSON 문자열로 변환
    };
  }

  static DiaryModel fromMap(Map<String, dynamic> map) {
    List<String> photos = [];
    
    // photo_paths 필드가 존재하고 null이 아니면 파싱
    if (map['photo_paths'] != null) {
      try {
        final List<dynamic> decoded = jsonDecode(map['photo_paths']);
        photos = decoded.map((e) => e.toString()).toList();
      } catch (e) {
        print('사진 경로 파싱 오류: $e');
      }
    }
    
    return DiaryModel(
      id: map['id'] as int?,
      date: map['date'] as String,
      title: map['title'] as String,
      content: map['content'] as String? ?? '',
      photoPaths: photos,
      userId: map['user_id'] as String? ?? '',
      isSynced: (map['is_synced'] as int?) == 1,
    );
  }
}
