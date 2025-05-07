import 'package:flutter/material.dart';

/// 체크리스트 항목을 표현하는 모델 클래스
class ChecklistItem {
  final String id;
  String text;
  String? subtext;
  bool isChecked;
  DateTime? dueDate;
  DateTime? completedDate; // 항목이 완료된 날짜 및 시간

  ChecklistItem({
    required this.id,
    required this.text,
    this.isChecked = false,
    this.dueDate,
    this.subtext,
    this.completedDate,
  });

  ChecklistItem copyWith({
    String? id,
    String? text,
    bool? isChecked,
    DateTime? dueDate,
    String? subtext,
    DateTime? completedDate,
  }) {
    return ChecklistItem(
      id: id ?? this.id,
      text: text ?? this.text,
      subtext: subtext ?? this.subtext,
      isChecked: isChecked ?? this.isChecked,
      dueDate: dueDate ?? this.dueDate,
      completedDate: completedDate ?? this.completedDate,
    );
  }

  /// SQLite 데이터베이스를 위한 Map 변환 메서드
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'text': text.trim(), // 공백 제거
      'subtext': subtext?.trim(), // 공백 제거
      'isChecked':
          isChecked ? 1 : 0, // SQLite에서는 boolean 대신 정수 사용 (0=false, 1=true)
      'dueDate': dueDate?.toIso8601String(), // 날짜를 ISO 8601 형식 문자열로 저장
      'completedDate':
          completedDate?.toIso8601String(), // 완료 날짜도 ISO 8601 형식으로 저장
    };
  }

  /// SQLite 데이터베이스로부터 객체 생성
  /// [map]은 데이터베이스에서 조회한 원시 데이터
  factory ChecklistItem.fromMap(Map<String, dynamic> map) {
    try {
      return ChecklistItem(
        id: map['id'] as String,
        text: (map['text'] as String?) ?? '', // null 안전성 추가
        subtext: map['subtext'] as String?,
        isChecked: (map['isChecked'] as int?) == 1, // null 안전성 추가
        dueDate:
            map['dueDate'] != null
                ? DateTime.parse(map['dueDate'] as String)
                : null,
        completedDate:
            map['completedDate'] != null
                ? DateTime.parse(map['completedDate'] as String)
                : null,
      );
    } catch (e) {
      // 데이터 파싱 오류 시 기본값을 사용한 항목 반환
      debugPrint('ChecklistItem 파싱 중 오류 발생: $e');
      return ChecklistItem(
        id: map['id'] as String? ?? UniqueKey().toString(),
        text: (map['text'] as String?) ?? '항목',
        isChecked: false,
      );
    }
  }

  /// 오늘 완료 여부 확인
  bool get isCompletedToday {
    if (completedDate == null) return false;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final completedDay = DateTime(
      completedDate!.year,
      completedDate!.month,
      completedDate!.day,
    );

    return completedDay.isAtSameMomentAs(today);
  }

  @override
  String toString() =>
      'ChecklistItem(id: $id, text: $text, isChecked: $isChecked, '
      'completedDate: ${completedDate?.toIso8601String() ?? "null"})';
}
