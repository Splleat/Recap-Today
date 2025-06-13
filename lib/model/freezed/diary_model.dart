import 'dart:convert';
import 'package:flutter/material.dart';
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
    if (map['photo_paths'] != null && map['photo_paths'] != '') {
      try {
        final String photoPathsString = map['photo_paths'] as String;
        debugPrint('📸 DiaryModel.fromMap - 원본 photo_paths: $photoPathsString');

        // 빈 문자열이거나 공백만 있는 경우 빈 배열로 처리
        if (photoPathsString.trim().isEmpty) {
          photos = [];
          debugPrint('📸 DiaryModel.fromMap - 빈 문자열로 인해 빈 배열 설정');
        } else {
          final List<dynamic> decoded = jsonDecode(photoPathsString);
          photos = decoded.map((e) => e.toString()).toList();
          debugPrint('📸 DiaryModel.fromMap - 파싱된 사진 경로들: $photos');
        }
      } catch (e) {
        print('사진 경로 파싱 오류: $e');
        debugPrint('📸 DiaryModel.fromMap - JSON 파싱 오류, 빈 배열로 설정: $e');
        // 파싱 오류 시 빈 배열로 설정
        photos = [];
      }
    } else {
      debugPrint('📸 DiaryModel.fromMap - photo_paths 필드가 null 또는 빈 문자열');
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
