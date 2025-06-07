// sqflite_database.dart
import 'package:flutter/foundation.dart';
import 'package:recap_today/model/freezed/diary_model.dart';
import 'package:recap_today/model/freezed/checklist_item.dart';
import 'package:recap_today/model/freezed/app_usage_model.dart';
import 'package:recap_today/model/freezed/schedule_item.dart';
import 'package:recap_today/model/freezed/emotion_model.dart';
import 'package:recap_today/model/freezed/location_model.dart';
import 'package:recap_today/model/freezed/step_model.dart';
import 'package:recap_today/model/freezed/ai_feedback_model.dart';
import 'package:recap_today/data/abstract_database.dart';
import 'package:recap_today/data/database_helper.dart';
import 'package:sqflite/sqflite.dart';
import 'dart:developer' as developer;

// SQLite 데이터베이스 접근을 위한 구현 클래스
// AbstractDatabase 인터페이스를 구현하여 애플리케이션과 데이터베이스 사이의 중간 계층 역할
class SqfliteDatabase implements AbstractDatabase {
  final DatabaseHelper _helper = DatabaseHelper.instance;

  // 데이터베이스 기본 메서드
  @override
  Future<Database> get database => _helper.database;

  @override
  Future close() async {
    await _helper.close();
  }

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
  Future<DiaryModel?> getDiaryByDate(String date, String userId) async {
    try {
      return await _helper.getDiaryByDate(date, userId);
    } catch (e) {
      debugPrint('날짜별 일기 조회 중 오류 발생: $e');
      return null;
    }
  }

  @override
  Future<List<DiaryModel>> getAllDiaries(String userId) async {
    try {
      return await _helper.getAllDiaries(userId);
    } catch (e) {
      debugPrint('전체 일기 목록 조회 중 오류 발생: $e');
      return [];
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
  Future<int> deleteDiary(int id, String userId) async {
    try {
      return await _helper.deleteDiary(id, userId);
    } catch (e) {
      debugPrint('일기 삭제 중 오류 발생: $e');
      rethrow;
    }
  }

  @override
  Future<Map<String, dynamic>> searchDiaries(
    String query,
    String userId, {
    int? limit,
    int? offset,
  }) async {
    try {
      return await _helper.searchDiaries(
        query,
        userId,
        limit: limit,
        offset: offset,
      );
    } catch (e) {
      debugPrint('일기 검색 중 오류 발생: $e');
      return {'diaries': [], 'totalCount': 0};
    }
  }

  // 체크리스트 관련 메서드
  @override
  Future<int> insertChecklistItem(ChecklistItem item) async {
    try {
      return await _helper.insertChecklistItem(item);
    } catch (e) {
      debugPrint('체크리스트 항목 추가 중 오류 발생: $e');
      rethrow;
    }
  }

  @override
  Future<List<ChecklistItem>> getAllChecklistItems(String userId) async {
    try {
      return await _helper.getAllChecklistItems(userId);
    } catch (e) {
      debugPrint('체크리스트 항목 전체 조회 중 오류 발생: $e');
      return [];
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
  Future<int> deleteChecklistItem(String id, String userId) async {
    try {
      return await _helper.deleteChecklistItem(id, userId);
    } catch (e) {
      debugPrint('체크리스트 항목 삭제 중 오류 발생: $e');
      rethrow;
    }
  }

  @override
  Future<List<ChecklistItem>> getChecklistItemsByCompletedDate(
    String date,
    String userId,
  ) async {
    try {
      return await _helper.getChecklistItemsByCompletedDate(date, userId);
    } catch (e) {
      debugPrint('완료일 기준 체크리스트 항목 조회 중 오류 발생: $e');
      return [];
    }
  }

  @override
  Future<List<ChecklistItem>> getIncompleteChecklistItems(String userId) async {
    try {
      return await _helper.getIncompleteChecklistItems(userId);
    } catch (e) {
      debugPrint('미완료 체크리스트 항목 조회 중 오류 발생: $e');
      return [];
    }
  }

  @override
  Future<List<ChecklistItem>> getCompletedChecklistItems(String userId) async {
    try {
      return await _helper.getCompletedChecklistItems(userId);
    } catch (e) {
      debugPrint('완료된 체크리스트 항목 조회 중 오류 발생: $e');
      return [];
    }
  }

  @override
  Future<void> saveChecklistItems(List<ChecklistItem> items) async {
    try {
      return await _helper.saveChecklistItems(items);
    } catch (e) {
      debugPrint('체크리스트 항목 일괄 저장 중 오류 발생: $e');
      rethrow;
    }
  }

  // 앱 사용량 관련 메서드
  @override
  Future<int> insertAppUsage(AppUsageModel appUsage) async {
    try {
      return await _helper.insertAppUsage(appUsage);
    } catch (e) {
      debugPrint('앱 사용 기록 추가 중 오류 발생: $e');
      rethrow;
    }
  }

  @override
  Future<List<AppUsageModel>> getAppUsageByDate(
    String date,
    String userId,
  ) async {
    try {
      return await _helper.getAppUsageByDate(date, userId);
    } catch (e) {
      debugPrint('일자별 앱 사용 기록 조회 중 오류 발생: $e');
      return [];
    }
  }

  @override
  Future<int> deleteAppUsageByDate(String date, String userId) async {
    try {
      return await _helper.deleteAppUsageByDate(date, userId);
    } catch (e) {
      debugPrint('일자별 앱 사용 기록 삭제 중 오류 발생: $e');
      rethrow;
    }
  }

  @override
  Future<int> insertAppUsageBatch(
    List<AppUsageModel> appUsages,
    String userId,
  ) async {
    try {
      return await _helper.insertAppUsageBatch(appUsages, userId);
    } catch (e) {
      debugPrint('앱 사용 기록 일괄 추가 중 오류 발생: $e');
      rethrow;
    }
  }

  // 일정 관련 메서드
  @override
  Future<int> insertScheduleItem(ScheduleItem item) async {
    try {
      return await _helper.insertScheduleItem(item);
    } catch (e) {
      debugPrint('일정 추가 중 오류 발생: $e');
      rethrow;
    }
  }

  @override
  Future<List<ScheduleItem>> getScheduleItemsByDate(
    String date,
    String userId,
  ) async {
    try {
      return await _helper.getScheduleItemsByDate(date, userId);
    } catch (e) {
      debugPrint('일자별 일정 조회 중 오류 발생: $e');
      return [];
    }
  }

  @override
  Future<List<ScheduleItem>> getAllScheduleItems(String userId) async {
    try {
      return await _helper.getAllScheduleItems(userId);
    } catch (e) {
      debugPrint('전체 일정 조회 중 오류 발생: $e');
      return [];
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
  Future<int> deleteScheduleItem(String id, String userId) async {
    try {
      return await _helper.deleteScheduleItem(id, userId);
    } catch (e) {
      debugPrint('일정 삭제 중 오류 발생: $e');
      rethrow;
    }
  }

  // 감정 기록 관련 메서드
  @override
  Future<int> insertEmotionRecord(EmotionRecord emotion) async {
    try {
      return await _helper.insertEmotionRecord(emotion);
    } catch (e) {
      debugPrint('감정 기록 추가 중 오류 발생: $e');
      rethrow;
    }
  }

  @override
  Future<List<EmotionRecord>> getEmotionsByDate(
    String date,
    String userId,
  ) async {
    try {
      return await _helper.getEmotionsByDate(date, userId);
    } catch (e) {
      debugPrint('일자별 감정 기록 조회 중 오류 발생: $e');
      return [];
    }
  }

  @override
  Future<EmotionRecord?> getEmotionByDateAndHour(
    String date,
    int hour,
    String userId,
  ) async {
    try {
      return await _helper.getEmotionByDateAndHour(date, hour, userId);
    } catch (e) {
      debugPrint('특정 시간 감정 기록 조회 중 오류 발생: $e');
      return null;
    }
  }

  @override
  Future<int> updateEmotionRecord(EmotionRecord emotion) async {
    try {
      return await _helper.updateEmotionRecord(emotion);
    } catch (e) {
      debugPrint('감정 기록 업데이트 중 오류 발생: $e');
      rethrow;
    }
  }

  @override
  Future<int> deleteEmotionRecord(String id, String userId) async {
    try {
      return await _helper.deleteEmotionRecord(id, userId);
    } catch (e) {
      debugPrint('감정 기록 삭제 중 오류 발생: $e');
      rethrow;
    }
  }

  // 위치 로그 관련 메서드
  @override
  Future<int> insertLocationLog(Map<String, dynamic> locationLog) async {
    try {
      return await _helper.insertLocationLog(locationLog);
    } catch (e) {
      debugPrint('위치 로그 추가 중 오류 발생: $e');
      rethrow;
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getLocationLogsForUserAndDate(
    String userId,
    String date,
  ) async {
    try {
      return await _helper.getLocationLogsForUserAndDate(userId, date);
    } catch (e) {
      debugPrint('일자별 위치 로그 조회 중 오류 발생: $e');
      return [];
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getLocationLogsForUser(
    String userId,
  ) async {
    try {
      return await _helper.getLocationLogsForUser(userId);
    } catch (e) {
      debugPrint('사용자 위치 로그 조회 중 오류 발생: $e');
      return [];
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getAllLocationLogsForUser(
    String userId,
  ) async {
    try {
      return await _helper.getAllLocationLogsForUser(userId);
    } catch (e) {
      debugPrint('사용자 전체 위치 로그 조회 중 오류 발생: $e');
      return [];
    }
  }

  @override
  Future<int> deleteAllLocationLogsForUser(String userId) async {
    try {
      return await _helper.deleteAllLocationLogsForUser(userId);
    } catch (e) {
      debugPrint('사용자 위치 로그 전체 삭제 중 오류 발생: $e');
      return 0;
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getLocationLogsForUserInRange(
    String userId,
    DateTime start,
    DateTime end,
  ) async {
    try {
      return await _helper.getLocationLogsForUserInRange(userId, start, end);
    } catch (e) {
      debugPrint('날짜 범위 위치 로그 조회 중 오류 발생: $e');
      return [];
    }
  }

  @override
  Future<int> deleteLocationLogsInRange(
    String userId,
    DateTime start,
    DateTime end,
  ) async {
    try {
      return await _helper.deleteLocationLogsInRange(userId, start, end);
    } catch (e) {
      debugPrint('날짜 범위 위치 로그 삭제 중 오류 발생: $e');
      return 0;
    }
  }

  // 걸음 수 관련 메서드
  @override
  Future<int> insertStepCount(StepModel step) async {
    try {
      return await _helper.insertStepCount(step);
    } catch (e) {
      debugPrint('걸음 수 기록 추가 중 오류 발생: $e');
      rethrow;
    }
  }

  @override
  Future<StepModel?> getStepsByDate(String date, String userId) async {
    try {
      return await _helper.getStepsByDate(date, userId);
    } catch (e) {
      debugPrint('일자별 걸음 수 조회 중 오류 발생: $e');
      return null;
    }
  }

  // 사진 관련 메서드
  @override
  Future<int> insertPhoto(int diaryId, String path, String userId) async {
    try {
      return await _helper.insertPhoto(diaryId, path, userId);
    } catch (e) {
      debugPrint('사진 추가 중 오류 발생: $e');
      rethrow;
    }
  }

  @override
  Future<List<String>> getPhotosByDiaryId(int diaryId) async {
    try {
      return await _helper.getPhotosByDiaryId(diaryId);
    } catch (e) {
      debugPrint('일기 사진 조회 중 오류 발생: $e');
      return [];
    }
  }

  @override
  Future<int> deletePhoto(int id, String userId) async {
    try {
      return await _helper.deletePhoto(id, userId);
    } catch (e) {
      debugPrint('사진 삭제 중 오류 발생: $e');
      rethrow;
    }
  }

  @override
  Future<int> deleteAllPhotosForDiary(int diaryId, String userId) async {
    try {
      return await _helper.deleteAllPhotosForDiary(diaryId, userId);
    } catch (e) {
      debugPrint('일기 사진 전체 삭제 중 오류 발생: $e');
      rethrow;
    }
  }

  // 동기화 관련 메서드
  @override
  Future<int> updateSyncStatus(String table, dynamic id, bool isSynced) async {
    try {
      return await _helper.updateSyncStatus(table, id, isSynced);
    } catch (e) {
      debugPrint('동기화 상태 업데이트 중 오류 발생: $e');
      rethrow;
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getUnsyncedItems(String table) async {
    try {
      return await _helper.getUnsyncedItems(table);
    } catch (e) {
      debugPrint('미동기화 항목 조회 중 오류 발생: $e');
      return [];
    }
  }

  // AI 피드백 관련 메서드
  @override
  Future<int> insertAiFeedback(AiFeedbackModel feedback) async {
    try {
      return await _helper.insertAiFeedback(feedback);
    } catch (e) {
      debugPrint('AI 피드백 추가 중 오류 발생: $e');
      rethrow;
    }
  }

  @override
  Future<List<AiFeedbackModel>> getAiFeedbackByDate(
    String date,
    String userId,
  ) async {
    try {
      return await _helper.getAiFeedbackByDate(date, userId);
    } catch (e) {
      debugPrint('일자별 AI 피드백 조회 중 오류 발생: $e');
      return [];
    }
  }

  @override
  Future<AiFeedbackModel?> getAiFeedbackById(int id, String userId) async {
    try {
      return await _helper.getAiFeedbackById(id, userId);
    } catch (e) {
      debugPrint('ID별 AI 피드백 조회 중 오류 발생: $e');
      return null;
    }
  }

  @override
  Future<List<AiFeedbackModel>> getAllAiFeedback(String userId) async {
    try {
      return await _helper.getAllAiFeedback(userId);
    } catch (e) {
      debugPrint('모든 AI 피드백 조회 중 오류 발생: $e');
      return [];
    }
  }

  @override
  Future<int> updateAiFeedback(AiFeedbackModel feedback) async {
    try {
      return await _helper.updateAiFeedback(feedback);
    } catch (e) {
      debugPrint('AI 피드백 업데이트 중 오류 발생: $e');
      rethrow;
    }
  }

  @override
  Future<int> deleteAiFeedback(int id, String userId) async {
    try {
      return await _helper.deleteAiFeedback(id, userId);
    } catch (e) {
      debugPrint('AI 피드백 삭제 중 오류 발생: $e');
      rethrow;
    }
  }

  // 백업을 위한 전체 데이터 조회 메서드들
  Future<List<Map<String, dynamic>>> getAllDiariesForBackup() async {
    developer.log('모든 일기 백업 데이터 조회 시작', name: 'SqfliteDatabase');
    try {
      final db = await database;
      final result = await db.query('diaries');
      developer.log(
        '일기 백업 데이터 조회 완료: ${result.length}개',
        name: 'SqfliteDatabase',
      );
      return result;
    } catch (e) {
      developer.log('모든 일기 조회 중 오류 발생: $e', name: 'SqfliteDatabase');
      debugPrint('모든 일기 조회 중 오류 발생: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getAllChecklistItemsForBackup() async {
    developer.log('모든 체크리스트 백업 데이터 조회 시작', name: 'SqfliteDatabase');
    try {
      final db = await database;
      final result = await db.query('checklist_items');
      developer.log(
        '체크리스트 백업 데이터 조회 완료: ${result.length}개',
        name: 'SqfliteDatabase',
      );
      return result;
    } catch (e) {
      developer.log('모든 체크리스트 조회 중 오류 발생: $e', name: 'SqfliteDatabase');
      debugPrint('모든 체크리스트 조회 중 오류 발생: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getAllScheduleItemsForBackup() async {
    developer.log('모든 일정 백업 데이터 조회 시작', name: 'SqfliteDatabase');
    try {
      final db = await database;
      final result = await db.query('schedule_items');
      developer.log(
        '일정 백업 데이터 조회 완료: ${result.length}개',
        name: 'SqfliteDatabase',
      );
      return result;
    } catch (e) {
      developer.log('모든 일정 조회 중 오류 발생: $e', name: 'SqfliteDatabase');
      debugPrint('모든 일정 조회 중 오류 발생: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getAllAppUsageRecords() async {
    developer.log('모든 앱 사용량 백업 데이터 조회 시작', name: 'SqfliteDatabase');
    try {
      final db = await database;
      final result = await db.query('app_usage');
      developer.log(
        '앱 사용량 백업 데이터 조회 완료: ${result.length}개',
        name: 'SqfliteDatabase',
      );
      return result;
    } catch (e) {
      developer.log('모든 앱 사용량 조회 중 오류 발생: $e', name: 'SqfliteDatabase');
      debugPrint('모든 앱 사용량 조회 중 오류 발생: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getAllEmotionRecords() async {
    developer.log('모든 감정 기록 백업 데이터 조회 시작', name: 'SqfliteDatabase');
    try {
      final db = await database;
      final result = await db.query(
        'emotion_records',
      ); // 수정: emotions -> emotion_records
      developer.log(
        '감정 기록 백업 데이터 조회 완료: ${result.length}개',
        name: 'SqfliteDatabase',
      );
      return result;
    } catch (e) {
      developer.log('모든 감정 기록 조회 중 오류 발생: $e', name: 'SqfliteDatabase');
      debugPrint('모든 감정 기록 조회 중 오류 발생: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getAllLocationRecords() async {
    developer.log('모든 위치 기록 백업 데이터 조회 시작', name: 'SqfliteDatabase');
    try {
      final db = await database;
      final result = await db.query(
        'location_logs',
      ); // 수정: locations -> location_logs
      developer.log(
        '위치 기록 백업 데이터 조회 완료: ${result.length}개',
        name: 'SqfliteDatabase',
      );
      return result;
    } catch (e) {
      developer.log('모든 위치 기록 조회 중 오류 발생: $e', name: 'SqfliteDatabase');
      debugPrint('모든 위치 기록 조회 중 오류 발생: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getAllStepRecords() async {
    developer.log('모든 걸음 수 백업 데이터 조회 시작', name: 'SqfliteDatabase');
    try {
      final db = await database;
      final result = await db.query('steps');
      developer.log(
        '걸음 수 백업 데이터 조회 완료: ${result.length}개',
        name: 'SqfliteDatabase',
      );
      return result;
    } catch (e) {
      developer.log('모든 걸음 수 기록 조회 중 오류 발생: $e', name: 'SqfliteDatabase');
      debugPrint('모든 걸음 수 기록 조회 중 오류 발생: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getAllAiFeedbackRecords() async {
    developer.log('모든 AI 피드백 백업 데이터 조회 시작', name: 'SqfliteDatabase');
    try {
      final db = await database;
      final result = await db.query('ai_feedback');
      developer.log(
        'AI 피드백 백업 데이터 조회 완료: ${result.length}개',
        name: 'SqfliteDatabase',
      );
      return result;
    } catch (e) {
      developer.log('모든 AI 피드백 조회 중 오류 발생: $e', name: 'SqfliteDatabase');
      debugPrint('모든 AI 피드백 조회 중 오류 발생: $e');
      return [];
    }
  }

  // 모든 데이터 삭제 메서드
  Future<void> clearAllData() async {
    developer.log('모든 데이터 삭제 시작', name: 'SqfliteDatabase');
    try {
      final db = await database;
      final batch = db.batch();

      developer.log('데이터 삭제 배치 작업 준비 중', name: 'SqfliteDatabase');

      // 모든 테이블의 데이터 삭제 (실제 테이블 이름 사용)
      batch.delete('diaries');
      developer.log('일기 테이블 삭제 배치 추가', name: 'SqfliteDatabase');

      batch.delete('checklist_items');
      developer.log('체크리스트 테이블 삭제 배치 추가', name: 'SqfliteDatabase');

      batch.delete('schedule_items');
      developer.log('일정 테이블 삭제 배치 추가', name: 'SqfliteDatabase');

      batch.delete('app_usage');
      developer.log('앱 사용량 테이블 삭제 배치 추가', name: 'SqfliteDatabase');

      batch.delete('emotion_records'); // 수정: emotions -> emotion_records
      developer.log('감정 기록 테이블 삭제 배치 추가', name: 'SqfliteDatabase');

      batch.delete('location_logs'); // 수정: locations -> location_logs
      developer.log('위치 기록 테이블 삭제 배치 추가', name: 'SqfliteDatabase');

      batch.delete('steps');
      developer.log('걸음 수 테이블 삭제 배치 추가', name: 'SqfliteDatabase');

      batch.delete('ai_feedback');
      developer.log('AI 피드백 테이블 삭제 배치 추가', name: 'SqfliteDatabase');

      batch.delete('photos'); // 추가: 사진 테이블도 삭제
      developer.log('사진 테이블 삭제 배치 추가', name: 'SqfliteDatabase');

      developer.log('배치 작업 실행 중', name: 'SqfliteDatabase');
      await batch.commit();

      developer.log('모든 데이터가 성공적으로 삭제되었습니다.', name: 'SqfliteDatabase');
      debugPrint('모든 데이터가 성공적으로 삭제되었습니다.');
    } catch (e) {
      developer.log('데이터 삭제 중 오류 발생: $e', name: 'SqfliteDatabase');
      debugPrint('데이터 삭제 중 오류 발생: $e');
      rethrow;
    }
  }
}
