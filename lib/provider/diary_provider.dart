// diary_provider.dart
import 'package:flutter/material.dart';
import 'package:recap_today/data/database_helper.dart';
import 'package:recap_today/model/diary_model.dart';
import 'package:recap_today/model/photo_model.dart';
import 'package:recap_today/utils/file_manager.dart';

/// 일기 상태 관리 클래스
class DiaryProvider with ChangeNotifier {
  List<DiaryModel> _diaries = [];

  /// 일기 목록
  List<DiaryModel> get diaries => _diaries;

  /// 일기 목록 가져오기
  Future<void> loadDiaries() async {
    _diaries = await DatabaseHelper.instance.getDiaries();
    notifyListeners();
  }

  /// 오늘의 일기 가져오기
  Future<DiaryModel?> getTodayDiary() async {
    final today = DateTime.now().toIso8601String().substring(0, 10);
    return await DatabaseHelper.instance.getDiaryForDate(today);
  }

  /// 특정 날짜의 일기 가져오기
  Future<DiaryModel?> getDiaryForSpecificDate(DateTime date) async {
    final dateString = date.toIso8601String().substring(0, 10);
    return await DatabaseHelper.instance.getDiaryForDate(dateString);
  }

  /// 일기 저장 (삽입 또는 업데이트)
  Future<DiaryModel> saveDiary(DiaryModel diary) async {
    final dbHelper = DatabaseHelper.instance;
    DiaryModel savedDiary;

    // Check if a diary for this date already exists if the incoming diary.id is null
    DiaryModel? existingDiaryForDate;
    if (diary.id == null) {
      existingDiaryForDate = await dbHelper.getDiaryForDate(diary.date);
    }

    try {
      if (existingDiaryForDate != null) {
        // A diary for this date exists, but the input diary has id=null.
        // Treat as an update to the existing diary.
        savedDiary = DiaryModel(
          id: existingDiaryForDate.id, // Use the ID of the existing diary
          date:
              existingDiaryForDate
                  .date, // Use existing date (should match diary.date)
          title: diary.title, // Use new title from input
          content: diary.content, // Use new content from input
          photoPaths: List<String>.from(
            diary.photoPaths,
          ), // Use new photo paths
        );
        // Perform update operations
        await dbHelper.updateDiary(savedDiary);
        await dbHelper.deletePhotosForDiary(
          savedDiary.id!,
        ); // Delete old photos for this diary
        await _savePhotos(savedDiary); // Save new photo associations
      } else if (diary.id == null) {
        // This is a new diary (no existing ID) and no diary found for this date.
        // Proceed with inserting a new diary.
        final id = await dbHelper.insertDiary(
          diary,
        ); // insertDiary handles potential conflict by date
        savedDiary = DiaryModel(
          id: id,
          date: diary.date,
          title: diary.title,
          content: diary.content,
          photoPaths: List<String>.from(diary.photoPaths),
        );
        await _savePhotos(savedDiary); // 사진 정보 DB에 저장
      } else {
        // This is an update to an existing diary (diary.id is not null).
        await dbHelper.updateDiary(diary); // 일기 내용 업데이트
        savedDiary = DiaryModel(
          id: diary.id,
          date: diary.date,
          title: diary.title,
          content: diary.content,
          photoPaths: List<String>.from(diary.photoPaths),
        );
        // 기존 사진 정보 DB에서 삭제 후 새 정보 저장
        await dbHelper.deletePhotosForDiary(diary.id!);
        await _savePhotos(savedDiary);
      }

      // 데이터베이스 작업 완료 후, 전역 사진 파일 정리 수행
      await _cleanupPhotos();

      // Provider 상태 업데이트 및 리스너에게 알림
      await loadDiaries();

      return savedDiary;
    } catch (e) {
      rethrow; // 오류를 상위 레벨로 전파
    }
  }

  /// 일기 검색
  Future<Map<String, dynamic>> searchDiaries(
    String query, {
    int? limit,
    int? offset,
  }) async {
    return await DatabaseHelper.instance.searchDiaries(
      query,
      limit: limit,
      offset: offset,
    );
  }

  /// 일기에 속한 사진들을 저장
  Future<void> _savePhotos(DiaryModel diary) async {
    if (diary.id == null) return;

    final dbHelper = DatabaseHelper.instance;
    for (var path in diary.photoPaths) {
      await dbHelper.insertPhoto(Photo(diaryId: diary.id!, path: path));
    }
  }

  /// 사용되지 않는 사진 정리
  Future<void> _cleanupPhotos() async {
    final dbHelper = DatabaseHelper.instance;
    List<String> allActivePhotoPathsInDB = [];

    try {
      // 데이터베이스에서 모든 일기를 다시 가져와 최신 사진 경로 목록을 확보합니다.
      List<DiaryModel> allDiariesFromDB = await dbHelper.getDiaries();
      for (var d in allDiariesFromDB) {
        allActivePhotoPathsInDB.addAll(d.photoPaths);
      }
      // 중복 제거
      allActivePhotoPathsInDB = allActivePhotoPathsInDB.toSet().toList();

      // 파일 시스템에서 사용되지 않는 사진 파일 정리
      await FileManager.cleanupUnusedPhotos(allActivePhotoPathsInDB);
    } catch (e) {
      // 사진 정리 중 오류가 발생해도 일기 저장 자체는 성공한 것으로 간주할 수 있습니다.
      // 필요에 따라 오류를 다르게 처리할 수 있습니다.
    }
  }
}
