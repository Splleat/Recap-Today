// diary_provider.dart
import 'package:flutter/material.dart';
import 'package:recap_today/data/database_helper.dart';
import 'package:recap_today/model/diary_model.dart';
import 'package:recap_today/model/photo_model.dart';

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

    if (diary.id == null) {
      // 새 일기 삽입
      final id = await dbHelper.insertDiary(diary);
      savedDiary = DiaryModel(
        id: id,
        date: diary.date,
        title: diary.title,
        content: diary.content,
        photoPaths: diary.photoPaths,
      );

      // 사진 삽입
      await _savePhotos(savedDiary);
    } else {
      // 기존 일기 업데이트
      await dbHelper.updateDiary(diary);
      savedDiary = diary;

      // 기존 사진 삭제 후 새 사진 삽입
      await dbHelper.deletePhotosForDiary(diary.id!);
      await _savePhotos(savedDiary);
    }

    await loadDiaries();
    return savedDiary;
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
