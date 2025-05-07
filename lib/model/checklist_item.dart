import 'package:flutter/material.dart';

/// 체크리스트 항목을 표현하는 모델 클래스
class ChecklistItem {
  final String id;
  String text;
  String? subtext;
  bool isChecked;
  DateTime? dueDate;

  ChecklistItem({
    required this.id,
    required this.text,
    this.isChecked = false,
    this.dueDate,
    this.subtext,
  });

  ChecklistItem copyWith({
    String? id,
    String? text,
    bool? isChecked,
    DateTime? dueDate,
    String? subtext,
  }) {
    return ChecklistItem(
      id: id ?? this.id,
      text: text ?? this.text,
      subtext: subtext ?? this.subtext,
      isChecked: isChecked ?? this.isChecked,
      dueDate: dueDate ?? this.dueDate,
    );
  }

  /// SQLite 데이터베이스를 위한 Map 변환 메서드
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'text': text,
      'subtext': subtext,
      'isChecked':
          isChecked ? 1 : 0, // SQLite에서는 boolean 대신 정수 사용 (0=false, 1=true)
      'dueDate': dueDate?.toIso8601String(), // 날짜를 ISO 8601 형식 문자열로 저장
    };
  }

  /// SQLite 데이터베이스로부터 객체 생성
  /// [map]은 데이터베이스에서 조회한 원시 데이터
  factory ChecklistItem.fromMap(Map<String, dynamic> map) {
    return ChecklistItem(
      id: map['id'] as String,
      text: map['text'] as String,
      subtext: map['subtext'] as String?,
      isChecked: map['isChecked'] == 1, // 정수를 boolean으로 변환
      dueDate:
          map['dueDate'] != null
              ? DateTime.parse(map['dueDate'])
              : null, // 문자열을 DateTime으로 변환
    );
  }

  @override
  String toString() =>
      'ChecklistItem(id: $id, text: $text, isChecked: $isChecked, dueDate: $dueDate)';
}
