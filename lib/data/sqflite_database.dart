// sqflite_database.dart
import 'package:flutter/foundation.dart';
import 'package:recap_today/model/diary_model.dart';
import 'package:recap_today/model/checklist_item.dart';
import 'package:recap_today/model/app_usage_model.dart';
import 'package:recap_today/model/schedule_item.dart';
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

  // 앱 사용 기록 관련 메서드 구현
  @override
  Future<int> insertAppUsage(AppUsageModel appUsage) async {
    try {
      return await _helper.insertAppUsage(appUsage);
    } catch (e) {
      debugPrint('앱 사용 기록 삽입 중 오류 발생: $e');
      rethrow;
    }
  }

  @override
  Future<int> insertAppUsageBatch(List<AppUsageModel> appUsages) async {
    try {
      return await _helper.insertAppUsageBatch(appUsages);
    } catch (e) {
      debugPrint('앱 사용 기록 일괄 삽입 중 오류 발생: $e');
      rethrow;
    }
  }

  @override
  Future<List<AppUsageModel>> getAppUsageForDate(String date) async {
    try {
      return await _helper.getAppUsageForDate(date);
    } catch (e) {
      debugPrint('특정 날짜 앱 사용 기록 조회 중 오류 발생: $e');
      return []; // 오류 발생 시 빈 목록 반환
    }
  }

  @override
  Future<AppUsageSummary?> getAppUsageSummaryForDate(String date) async {
    try {
      return await _helper.getAppUsageSummaryForDate(date);
    } catch (e) {
      debugPrint('특정 날짜 앱 사용 요약 정보 조회 중 오류 발생: $e');
      return null; // 오류 발생 시 null 반환
    }
  }

  @override
  Future<int> deleteAppUsageForDate(String date) async {
    try {
      return await _helper.deleteAppUsageForDate(date);
    } catch (e) {
      debugPrint('특정 날짜 앱 사용 기록 삭제 중 오류 발생: $e');
      rethrow;
    }
  }

  // 일정 관련 메서드 구현
  @override
  Future<int> insertScheduleItem(ScheduleItem item) async {
    try {
      return await _helper.insertScheduleItem(item);
    } catch (e) {
      debugPrint('일정 삽입 중 오류 발생: $e');
      rethrow;
    }
  }

  @override
  Future<int> updateScheduleItem(ScheduleItem item) async {
    try {
      return await _helper.updateScheduleItem(item);
    } catch (e) {
      debugPrint('일정 업데이트 중 오류 발생: $e');
      rethrow;
    }
  }

  @override
  Future<List<ScheduleItem>> getScheduleItems() async {
    try {
      return await _helper.getScheduleItems();
    } catch (e) {
      debugPrint('일정 목록 조회 중 오류 발생: $e');
      return []; // 오류 발생 시 빈 목록 반환
    }
  }

  @override
  Future<List<ScheduleItem>> getScheduleItemsForDate(DateTime date) async {
    try {
      return await _helper.getScheduleItemsForDate(date);
    } catch (e) {
      debugPrint('특정 날짜 일정 조회 중 오류 발생: $e');
      return []; // 오류 발생 시 빈 목록 반환
    }
  }

  @override
  Future<List<ScheduleItem>> getRoutineScheduleItems() async {
    try {
      return await _helper.getRoutineScheduleItems();
    } catch (e) {
      debugPrint('반복 일정 조회 중 오류 발생: $e');
      return []; // 오류 발생 시 빈 목록 반환
    }
  }

  @override
  Future<ScheduleItem?> getScheduleItemById(String id) async {
    try {
      return await _helper.getScheduleItemById(id);
    } catch (e) {
      debugPrint('특정 ID 일정 조회 중 오류 발생: $e');
      return null; // 오류 발생 시 null 반환
    }
  }

  @override
  Future<int> deleteScheduleItem(String id) async {
    try {
      return await _helper.deleteScheduleItem(id);
    } catch (e) {
      debugPrint('일정 삭제 중 오류 발생: $e');
      rethrow;
    }
  }

  @override
  Future<int> deleteAllScheduleItems() async {
    try {
      return await _helper.deleteAllScheduleItems();
    } catch (e) {
      debugPrint('모든 일정 삭제 중 오류 발생: $e');
      rethrow;
    }
  }

  // 일정 관련 추가 메서드
  @override
  Future<List<ScheduleItem>> getScheduleItemsForRange(
    DateTime start,
    DateTime end,
  ) async {
    try {
      return await _helper.getScheduleItemsForRange(start, end);
    } catch (e) {
      debugPrint('기간 내 일정 조회 중 오류 발생: $e');
      return []; // 오류 발생 시 빈 목록 반환
    }
  }

  @override
  Future<List<DateTime>> getScheduleDatesForMonth(int year, int month) async {
    try {
      return await _helper.getScheduleDatesForMonth(year, month);
    } catch (e) {
      debugPrint('월간 일정 날짜 조회 중 오류 발생: $e');
      return []; // 오류 발생 시 빈 목록 반환
    }
  }

  @override
  Future<bool> hasSchedule() async {
    try {
      return await _helper.hasSchedule();
    } catch (e) {
      debugPrint('일정 존재 여부 확인 중 오류 발생: $e');
      return false; // 오류 발생 시 false 반환
    }
  }

  @override
  Future<int> deleteScheduleItemsInRange(DateTime start, DateTime end) async {
    try {
      return await _helper.deleteScheduleItemsInRange(start, end);
    } catch (e) {
      debugPrint('기간 내 일정 삭제 중 오류 발생: $e');
      rethrow;
    }
  }

  @override
  Future<void> saveScheduleItems(List<ScheduleItem> items) async {
    try {
      await _helper.saveScheduleItems(items);
    } catch (e) {
      debugPrint('일정 일괄 저장 중 오류 발생: $e');
      rethrow;
    }
  }
}
