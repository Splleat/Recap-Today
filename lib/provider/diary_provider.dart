// diary_provider.dart
import 'package:flutter/material.dart';
import 'package:recap_today/model/diary_model.dart';
import 'package:recap_today/utils/file_manager.dart';
import 'package:recap_today/data/abstract_database.dart';

/// 일기 상태 관리 클래스
class DiaryProvider with ChangeNotifier {
  final AbstractDatabase _database;
  List<DiaryModel> _diaries = [];

  /// 일기 목록
  List<DiaryModel> get diaries => _diaries;

  DiaryProvider(this._database) {
    loadDiaries(); // Load diaries on initialization
  }

  /// 일기 목록 가져오기
  Future<void> loadDiaries() async {
    _diaries = await _database.getDiaries();
    notifyListeners();
  }

  /// 오늘의 일기 가져오기
  Future<DiaryModel?> getTodayDiary() async {
    final today = DateTime.now().toIso8601String().substring(0, 10);
    return await _database.getDiaryForDate(today);
  }

  /// 특정 날짜의 일기 가져오기
  Future<DiaryModel?> getDiaryForSpecificDate(DateTime date) async {
    final dateString = date.toIso8601String().substring(0, 10);
    return await _database.getDiaryForDate(dateString);
  }

  /// 일기 저장 (삽입 또는 업데이트)
  Future<DiaryModel> saveDiary(DiaryModel diary) async {
    try {
      final savedDiary = await _database.saveDiary(diary);

      // After the diary and its photos are saved transactionally by DiaryDao,
      // perform a cleanup of orphaned photo files from the filesystem.
      await _cleanupPhotos();

      // Reload diaries to update the provider state and notify listeners.
      await loadDiaries();

      return savedDiary;
    } catch (e) {
      // Consider more specific error handling or logging if needed
      debugPrint('Error in DiaryProvider.saveDiary: $e');
      rethrow; // Propagate the error to the UI or calling layer
    }
  }

  /// 일기 검색
  Future<Map<String, dynamic>> searchDiaries(
    String query, {
    int? limit,
    int? offset,
  }) async {
    return await _database.searchDiaries(query, limit: limit, offset: offset);
  }

  /// 사용되지 않는 사진 정리 (파일 시스템)
  Future<void> _cleanupPhotos() async {
    try {
      // Fetch all photo paths currently active in the database.
      List<String> allActivePhotoPathsInDB = [];
      List<DiaryModel> allDiariesFromDB = await _database.getDiaries();
      for (var d in allDiariesFromDB) {
        allActivePhotoPathsInDB.addAll(d.photoPaths);
      }
      allActivePhotoPathsInDB = allActivePhotoPathsInDB.toSet().toList();

      await FileManager.cleanupUnusedPhotos(allActivePhotoPathsInDB);
    } catch (e) {
      debugPrint('Error during photo cleanup: $e');
      // Non-critical error, so we don't rethrow typically.
    }
  }
}
