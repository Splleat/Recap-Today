import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'diary_model.freezed.dart';
part 'diary_model.g.dart';

@freezed
abstract class Diary with _$Diary {
  const factory Diary({
    String? id,
    required String userId,
    required String date,
    required String title,
    String? content,
    required List<String> photoPaths,
    required DateTime createdAt,
    @Default(false) bool isSynced,
  }) = _Diary;

  factory Diary.fromJson(Map<String, dynamic> json) => _$DiaryFromJson(json);
}

extension DiaryExt on Diary {
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'date': date,
      'title': title,
      'content': content,
      'photoPaths': json.encode(photoPaths),
      'createdAt': createdAt.toIso8601String(),
      'isSynced': isSynced ? 1 : 0,
    };
  }

  static Diary fromMap(Map<String, dynamic> map) {
    return Diary(
      id: map['id'] as String?,
      userId: map['userId'] as String,
      date: map['date'] as String,
      title: map['title'] as String,
      content: map['content'] as String?,
      photoPaths: List<String>.from(json.decode(map['photoPaths'])),
      createdAt: DateTime.parse(map['createdAt'] as String),
      isSynced: (map['isSynced'] as int) == 1,
    );
  }

  /// 새 일기 생성 도우미
  static Diary createNew({
    required String userId,
    required String date,
    required String title,
    String? content,
    List<String> photoPaths = const [],
  }) {
    return Diary(
      id: null,
      userId: userId,
      date: date,
      title: title,
      content: content,
      photoPaths: photoPaths,
      createdAt: DateTime.now(),
    );
  }
}
