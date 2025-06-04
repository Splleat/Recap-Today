import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:flutter/foundation.dart';

part 'checklist_item.freezed.dart';
part 'checklist_item.g.dart';

@freezed
abstract class ChecklistItem with _$ChecklistItem {
  const factory ChecklistItem({
    required String id,
    required String text,
    String? subtext,
    @Default(false) bool isChecked,
    DateTime? dueDate,
    DateTime? completedDate,
    required String userId,
    @Default(false) bool isSynced,
  }) = _ChecklistItem;

  factory ChecklistItem.fromJson(Map<String, dynamic> json) => 
      _$ChecklistItemFromJson(json);
}

extension ChecklistItemX on ChecklistItem {
  /// SQLite 데이터베이스를 위한 Map 변환 메서드
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'text': text.trim(), // 공백 제거
      'subtext': subtext?.trim(), // 공백 제거
      'is_checked': isChecked ? 1 : 0, // SQLite에서는 boolean 대신 정수 사용 (0=false, 1=true)
      'due_date': dueDate?.toIso8601String(), // 날짜를 ISO 8601 형식 문자열로 저장
      'completed_date': completedDate?.toIso8601String(), // 완료 날짜도 ISO 8601 형식으로 저장
      'user_id': userId,
      'is_synced': isSynced ? 1 : 0,
    };
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

  /// 특정 날짜에 완료 여부 확인
  bool isCompletedOnDate(DateTime date) {
    if (completedDate == null) return false;

    final targetDate = DateTime(date.year, date.month, date.day);
    final completedDay = DateTime(
      completedDate!.year,
      completedDate!.month,
      completedDate!.day,
    );

    return completedDay.isAtSameMomentAs(targetDate);
  }

  /// 특정 기간 내 완료 여부 확인
  bool isCompletedBetween(DateTime startDate, DateTime endDate) {
    if (completedDate == null) return false;

    final start = DateTime(startDate.year, startDate.month, startDate.day);
    final end = DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59);
    final completed = DateTime(
      completedDate!.year,
      completedDate!.month,
      completedDate!.day,
    );

    return completed.isAfter(start) && completed.isBefore(end) || 
      completed.isAtSameMomentAs(start) || 
      completed.isAtSameMomentAs(DateTime(end.year, end.month, end.day));
  }

  /// 지정된 일 수 이내에 완료 여부 확인
  bool isCompletedWithinDays(int days) {
    if (completedDate == null) return false;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final cutoffDate = today.subtract(Duration(days: days));
    final completedDay = DateTime(
      completedDate!.year,
      completedDate!.month,
      completedDate!.day,
    );

    return completedDay.isAfter(cutoffDate) || completedDay.isAtSameMomentAs(cutoffDate);
  }

  static ChecklistItem fromMap(Map<String, dynamic> map) {
    try {
      return ChecklistItem(
        id: map['id'] as String,
        text: (map['text'] as String?) ?? '', // null 안전성 추가
        subtext: map['subtext'] as String?,
        isChecked: (map['is_checked'] as int?) == 1, // null 안전성 추가
        dueDate:
            map['due_date'] != null
                ? DateTime.parse(map['due_date'] as String)
                : null,
        completedDate:
            map['completed_date'] != null
                ? DateTime.parse(map['completed_date'] as String)
                : null,
        userId: map['user_id'] as String? ?? '',
        isSynced: (map['is_synced'] as int?) == 1,
      );
    } catch (e) {
      // 데이터 파싱 오류 시 기본값을 사용한 항목 반환
      debugPrint('ChecklistItem 파싱 중 오류 발생: $e');
      return ChecklistItem(
        id: map['id'] as String? ?? UniqueKey().toString(),
        text: (map['text'] as String?) ?? '항목',
        userId: map['user_id'] as String? ?? '',
      );
    }
  }
}
