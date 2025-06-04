// diary_provider.dart
import 'package:flutter/material.dart';
import 'package:recap_today/data/sqflite_database.dart';
import 'package:recap_today/model/freezed/diary_model.dart';
import 'package:recap_today/utils/file_manager.dart';

/// 일기 상태 관리 클래스
class DiaryProvider with ChangeNotifier {
  List<DiaryModel> _diaries = [];
  final SqfliteDatabase _database = SqfliteDatabase();
  String userId;
  bool _isLoading = false;

  DiaryProvider({required this.userId}) {
    loadDiaries(); // 초기 로드
  }

  /// 일기 목록
  List<DiaryModel> get diaries => _diaries;
  bool get isLoading => _isLoading;

  // 로그인 사용자 ID 설정
  void setUserId(String userId) {
    if (this.userId != userId) {
      this.userId = userId;
      loadDiaries(); // 사용자 변경 시 일기 목록 다시 로드
    }
  }

  /// 일기 목록 가져오기
  Future<void> loadDiaries() async {
    try {
      _isLoading = true;
      notifyListeners();
      
      _diaries = await _database.getAllDiaries(userId);
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      debugPrint('일기 목록 로드 중 오류 발생: $e');
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 오늘의 일기 가져오기
  Future<DiaryModel?> getTodayDiary() async {
    final today = DateTime.now().toIso8601String().substring(0, 10);
    return await _database.getDiaryByDate(today, userId);
  }

  /// 특정 날짜의 일기 가져오기
  Future<DiaryModel?> getDiaryForSpecificDate(DateTime date) async {
    final dateString = date.toIso8601String().substring(0, 10);
    return await _database.getDiaryByDate(dateString, userId);
  }

  /// 일기 저장 (삽입 또는 업데이트)
  Future<DiaryModel> saveDiary(DiaryModel diary) async {
    // userId 설정하여 일기 모델 업데이트
    final diaryWithUserId = diary.copyWith(userId: userId);
    
    try {
      int diaryId;
      
      // 기존 일기가 있는지 확인
      final existingDiary = diary.id == null 
          ? await _database.getDiaryByDate(diary.date, userId)
          : null;
          
      if (existingDiary != null) {
        // 날짜에 해당하는 기존 일기 업데이트
        final updatedDiary = diaryWithUserId.copyWith(id: existingDiary.id);
        await _database.updateDiary(updatedDiary);
        diaryId = updatedDiary.id!;
      } else if (diary.id != null) {
        // 기존 일기 업데이트
        await _database.updateDiary(diaryWithUserId);
        diaryId = diary.id!;
      } else {
        // 새 일기 삽입
        diaryId = await _database.insertDiary(diaryWithUserId);
      }
      
      // 기존 사진 정보 삭제
      if (diaryId != null) {
        await _database.deleteAllPhotosForDiary(diaryId, userId);

        // 새 사진 정보 저장
        for (final path in diaryWithUserId.photoPaths) {
          await _database.insertPhoto(diaryId, path, userId);
        }
      }

      // 사용되지 않는 사진 정리
      await _cleanupPhotos();
      
      // 일기 목록 갱신
      await loadDiaries();
      
      // 저장된 일기 반환
      final savedDiary = diaryWithUserId.copyWith(id: diaryId);
      return savedDiary;
      
    } catch (e) {
      debugPrint('일기 저장 중 오류 발생: $e');
      rethrow;
    }
  }

  /// 일기 삭제
  Future<bool> deleteDiary(int id, String userId) async {
    try {
      await _database.deleteDiary(id, userId);
      await loadDiaries(); // 목록 갱신
      await _cleanupPhotos(); // 사진 정리
      return true;
    } catch (e) {
      debugPrint('일기 삭제 중 오류 발생: $e');
      return false;
    }
  }

  /// 일기 검색
  Future<Map<String, dynamic>> searchDiaries(
    String query, {
    int? limit,
    int? offset,
  }) async {
    return await _database.searchDiaries(
      query,
      userId,
      limit: limit,
      offset: offset,
    );
  }

  /// 사용되지 않는 사진 정리
  Future<void> _cleanupPhotos() async {
    try {
      // 모든 일기의 사진 경로 수집
      List<String> allActivePhotoPathsInDB = [];
      final allDiaries = await _database.getAllDiaries(userId);
      
      for (var diary in allDiaries) {
        allActivePhotoPathsInDB.addAll(diary.photoPaths);
      }
      
      // 중복 제거
      allActivePhotoPathsInDB = allActivePhotoPathsInDB.toSet().toList();
      
      // 파일 시스템에서 사용되지 않는 사진 파일 정리
      await FileManager.cleanupUnusedPhotos(allActivePhotoPathsInDB);
    } catch (e) {
      debugPrint('사진 정리 중 오류 발생: $e');
      // 사진 정리 오류는 크리티컬하지 않으므로 무시
    }
  }
}
