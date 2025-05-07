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

  /// 일기 저장 (삽입 또는 업데이트)
  Future<DiaryModel> saveDiary(DiaryModel diary) async {
    final dbHelper = DatabaseHelper.instance;
    DiaryModel savedDiary;

    try {
      if (diary.id == null) {
        // 새 일기 삽입
        final id = await dbHelper.insertDiary(diary);
        savedDiary = DiaryModel(
          id: id,
          date: diary.date,
          title: diary.title,
          content: diary.content,
          photoPaths: List<String>.from(diary.photoPaths),
        );

        // 사진 삽입
        await _savePhotos(savedDiary);
      } else {
        // 기존 일기의 사진 경로 가져오기
        final existingPhotos = await dbHelper.getPhotosForDiary(diary.id!);
        final existingPaths =
            existingPhotos.map((photo) => photo.path).toList();

        // 기존 일기 업데이트
        await dbHelper.updateDiary(diary);
        savedDiary = DiaryModel(
          id: diary.id,
          date: diary.date,
          title: diary.title,
          content: diary.content,
          photoPaths: List<String>.from(diary.photoPaths),
        );

        // 기존 사진 삭제 후 새 사진 삽입
        await dbHelper.deletePhotosForDiary(diary.id!);
        await _savePhotos(savedDiary);

        // 더 이상 사용되지 않는 파일 정리
        if (existingPaths.isNotEmpty) {
          // 사용되지 않는 경로 필터링
          final unusedPaths =
              existingPaths
                  .where((path) => !diary.photoPaths.contains(path))
                  .toList();

          if (unusedPaths.isNotEmpty) {
            try {
              await FileManager.cleanupUnusedPhotos(diary.photoPaths);
            } catch (e) {
              debugPrint('Error cleaning up unused photos: $e');
              // 파일 정리 실패는 일기 저장 실패로 간주하지 않음
            }
          }
        }
      }

      await loadDiaries();
      return savedDiary;
    } catch (e) {
      debugPrint('Error saving diary: $e');
      rethrow; // 오류를 상위 레벨로 전파
    }
  }

  /// 일기에 속한 사진들을 저장
  Future<void> _savePhotos(DiaryModel diary) async {
    if (diary.id == null) return;

    final dbHelper = DatabaseHelper.instance;
    for (var path in diary.photoPaths) {
      await dbHelper.insertPhoto(Photo(diaryId: diary.id!, path: path));
    }
  }
}
