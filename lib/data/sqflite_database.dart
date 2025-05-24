// sqflite_database.dart
import 'package:flutter/foundation.dart';
import 'package:recap_today/model/diary_model.dart';
import 'package:recap_today/model/checklist_item.dart';
import 'package:recap_today/model/app_usage_model.dart';
import 'package:recap_today/model/schedule_item.dart';
import 'package:recap_today/data/abstract_database.dart';
import 'package:recap_today/data/database_helper.dart';
import 'package:sqflite/sqflite.dart'; // sqflite import 추가
import 'package:recap_today/model/emotion_model.dart'; // Added import for EmotionRecord

// SQLite 데이터베이스 접근을 위한 구현 클래스
// AbstractDatabase 인터페이스를 구현하여 애플리케이션과 데이터베이스 사이의 중간 계층 역할
class SqfliteDatabase extends AbstractDatabase {
  final DatabaseHelper _helper = DatabaseHelper.instance;

  // database getter 구현
  @override
  Future<Database> get database => _helper.database;

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

  @override
  // Future<List<DiaryModel>> searchDiaries(String query) async { // Old signature
  Future<Map<String, dynamic>> searchDiaries(
    String query, {
    int? limit,
    int? offset,
  }) async {
    try {
      // return await _helper.searchDiaries(query); // Old call
      return await _helper.searchDiaries(
        query,
        limit: limit,
        offset: offset,
      ); // New call
    } catch (e) {
      debugPrint('일기 검색 중 오류 발생: $e');
      // return []; // Old return
      return {'diaries': [], 'totalCount': 0}; // New return for error case
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
      return [];
    }
  }

  @override
  Future<List<ScheduleItem>> getScheduleItemsForDate(DateTime date) async {
    try {
      return await _helper.getScheduleItemsForDate(date);
    } catch (e) {
      debugPrint('특정 날짜 일정 목록 조회 중 오류 발생: $e');
      return [];
    }
  }

  @override
  Future<List<ScheduleItem>> getRoutineScheduleItems() async {
    try {
      return await _helper.getRoutineScheduleItems();
    } catch (e) {
      debugPrint('루틴 일정 목록 조회 중 오류 발생: $e');
      return [];
    }
  }

  @override
  Future<ScheduleItem?> getScheduleItemById(String id) async {
    try {
      return await _helper.getScheduleItemById(id);
    } catch (e) {
      debugPrint('특정 ID 일정 조회 중 오류 발생: $e');
      return null;
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

  @override
  Future<List<ScheduleItem>> getScheduleItemsForRange(
    DateTime start,
    DateTime end,
  ) async {
    try {
      return await _helper.getScheduleItemsForRange(start, end);
    } catch (e) {
      debugPrint('기간별 일정 목록 조회 중 오류 발생: $e');
      return [];
    }
  }

  @override
  Future<List<DateTime>> getScheduleDatesForMonth(int year, int month) async {
    try {
      return await _helper.getScheduleDatesForMonth(year, month);
    } catch (e) {
      debugPrint('월별 일정 날짜 목록 조회 중 오류 발생: $e');
      return [];
    }
  }

  @override
  Future<bool> hasSchedule() async {
    try {
      return await _helper.hasSchedule();
    } catch (e) {
      debugPrint('일정 존재 여부 확인 중 오류 발생: $e');
      return false;
    }
  }

  @override
  Future<int> deleteScheduleItemsInRange(DateTime start, DateTime end) async {
    try {
      return await _helper.deleteScheduleItemsInRange(start, end);
    } catch (e) {
      debugPrint('기간별 일정 삭제 중 오류 발생: $e');
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

  // Emotion Timeline 관련 메서드 구현
  @override
  Future<int> addEmotionRecord(EmotionRecord record) async {
    final db = await database;
    // Ensure id is not null, as it's a primary key.
    // The EmotionRecord model should handle UUID generation if id is null upon creation.
    if (record.id == null) {
      // This case should ideally be handled by the model/repository layer
      // by ensuring EmotionRecord always has an ID before DB insertion.
      // For safety, we can log or throw an error, but for now, let's assume
      // the model populates it.
      debugPrint(
        "Error: EmotionRecord ID is null during addEmotionRecord. This should not happen.",
      );
      // throw Exception("Cannot insert EmotionRecord with null ID");
      // Or, let the insert proceed if the model now auto-generates it.
    }
    await db.insert(
      DatabaseHelper.tableEmotionRecords,
      record.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    return 1; // Return 1 as a generic success indicator, though not strictly used for ID.
  }

  @override
  Future<int> updateEmotionRecord(EmotionRecord record) async {
    final db = await database;
    try {
      return await db.update(
        DatabaseHelper.tableEmotionRecords, // DatabaseHelper의 상수 사용
        record.toMap(),
        where: 'id = ?',
        whereArgs: [record.id],
      );
    } catch (e) {
      debugPrint('감정 기록 업데이트 중 오류 발생: $e');
      rethrow;
    }
  }

  @override
  Future<EmotionRecord?> getEmotionRecordForHour(String date, int hour) async {
    final db = await database;
    try {
      final List<Map<String, dynamic>> maps = await db.query(
        DatabaseHelper.tableEmotionRecords, // DatabaseHelper의 상수 사용
        where: 'date = ? AND hour = ?',
        whereArgs: [date, hour],
        limit: 1,
      );
      if (maps.isNotEmpty) {
        return EmotionRecord.fromMap(maps.first);
      }
      return null;
    } catch (e) {
      debugPrint('특정 시간 감정 기록 조회 중 오류 발생: $e');
      return null;
    }
  }

  @override
  Future<List<EmotionRecord>> getEmotionRecordsForDay(String date) async {
    final db = await database;
    try {
      final List<Map<String, dynamic>> maps = await db.query(
        DatabaseHelper.tableEmotionRecords, // DatabaseHelper의 상수 사용
        where: 'date = ?',
        whereArgs: [date],
        orderBy: 'hour ASC', // 시간순으로 정렬
      );
      return maps.map((map) => EmotionRecord.fromMap(map)).toList();
    } catch (e) {
      debugPrint('하루 감정 기록 목록 조회 중 오류 발생: $e');
      return [];
    }
  }

  @override
  Future<int> deleteEmotionRecord(String id) async {
    final db = await database;
    try {
      return await db.delete(
        DatabaseHelper.tableEmotionRecords, // DatabaseHelper의 상수 사용
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      debugPrint('감정 기록 삭제 중 오류 발생: $e');
      rethrow;
    }
  }
}
