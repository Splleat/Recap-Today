// sqflite_database.dart
import 'package:flutter/foundation.dart';
import 'package:recap_today/model/diary_model.dart';
import 'package:recap_today/model/checklist_item.dart';
import 'package:recap_today/data/abstract_database.dart';
import 'package:recap_today/data/database_helper.dart';

// SQLite 데이터베이스 접근을 위한 구현 클래스
// AbstractDatabase 인터페이스를 구현하여 애플리케이션과 데이터베이스 사이의 중간 계층 역할
class SqfliteDatabase extends AbstractDatabase {
  final DatabaseHelper _helper = DatabaseHelper.instance;

  // 일기 관련 메서드
  @override
  Future<int> insertDiary(DiaryModel diary) async {
    try {
      return await _helper.insertDiary(diary);
    } catch (e) {
      debugPrint('일기 삽입 중 오류 발생: $e');
      rethrow;
    }
  }

  @override
  Future<int> updateDiary(DiaryModel diary) async {
    try {
      return await _helper.updateDiary(diary);
    } catch (e) {
      debugPrint('일기 업데이트 중 오류 발생: $e');
      rethrow;
    }
  }

  @override
  Future<List<DiaryModel>> getDiaries() async {
    try {
      return await _helper.getDiaries();
    } catch (e) {
      debugPrint('일기 목록 조회 중 오류 발생: $e');
      return []; // 오류 발생 시 빈 목록 반환
    }
  }

  @override
  Future<DiaryModel?> getDiaryForDate(String date) async {
    try {
      return await _helper.getDiaryForDate(date);
    } catch (e) {
      debugPrint('특정 날짜 일기 조회 중 오류 발생: $e');
      return null; // 오류 발생 시 null 반환
    }
  }

  // 체크리스트 관련 메서드 구현
  @override
  Future<int> insertChecklistItem(ChecklistItem item) async {
    try {
      return await _helper.insertChecklistItem(item);
    } catch (e) {
      debugPrint('체크리스트 항목 삽입 중 오류 발생: $e');
      rethrow;
    }
  }

  @override
  Future<int> updateChecklistItem(ChecklistItem item) async {
    try {
      return await _helper.updateChecklistItem(item);
    } catch (e) {
      debugPrint('체크리스트 항목 업데이트 중 오류 발생: $e');
      rethrow;
    }
  }

  @override
  Future<List<ChecklistItem>> getChecklistItems() async {
    try {
      return await _helper.getChecklistItems();
    } catch (e) {
      debugPrint('체크리스트 항목 목록 조회 중 오류 발생: $e');
      return []; // 오류 발생 시 빈 목록 반환
    }
  }

  @override
  Future<ChecklistItem?> getChecklistItemById(String id) async {
    try {
      return await _helper.getChecklistItemById(id);
    } catch (e) {
      debugPrint('체크리스트 항목 조회 중 오류 발생: $e');
      return null; // 오류 발생 시 null 반환
    }
  }

  @override
  Future<int> deleteChecklistItem(String id) async {
    try {
      return await _helper.deleteChecklistItem(id);
    } catch (e) {
      debugPrint('체크리스트 항목 삭제 중 오류 발생: $e');
      rethrow;
    }
  }

  @override
  Future<int> deleteAllChecklistItems() async {
    try {
      return await _helper.deleteAllChecklistItems();
    } catch (e) {
      debugPrint('모든 체크리스트 항목 삭제 중 오류 발생: $e');
      rethrow;
    }
  }

  @override
  Future<void> saveChecklistItems(List<ChecklistItem> items) async {
    try {
      await _helper.saveChecklistItems(items);
    } catch (e) {
      debugPrint('체크리스트 항목 일괄 저장 중 오류 발생: $e');
      rethrow;
    }
  }
}
