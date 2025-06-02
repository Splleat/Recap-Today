import 'package:flutter/material.dart';
import 'package:recap_today/model/diary/diary_model.dart';
import 'package:recap_today/utils/file_manager.dart';
import 'package:recap_today/dao/diary_dao.dart';

class DiaryProvider with ChangeNotifier {
  final DiaryDao _diaryDao;
  List<Diary> _diaries = [];

  DiaryProvider({DiaryDao? diaryDao}) : _diaryDao = diaryDao ?? DiaryDao();

  List<Diary> get diaries => _diaries;

  Future<void> loadDiaries() async {
    _diaries = await _diaryDao.getAllDiaries();
    notifyListeners();
  }

  Future<Diary?> getTodayDiary() async {
    final today = DateTime.now().toIso8601String().substring(0, 10);
    return await _diaryDao.getDiaryByDate(today);
  }

  Future<Diary?> getDiaryForSpecificDate(DateTime date) async {
    final dateString = date.toIso8601String().substring(0, 10);
    return await _diaryDao.getDiaryByDate(dateString);
  }

  Future<Diary> saveDiary(Diary diary) async {
    try {
      Diary savedDiary;

      // 기존 일기 확인 (id가 없을 경우)
      Diary? existingDiary = diary.id == null
          ? await _diaryDao.getDiaryByDate(diary.date)
          : null;

      if (existingDiary != null) {
        // 기존 일기 수정
        savedDiary = diary.copyWith(id: existingDiary.id);
        await _diaryDao.updateDiary(savedDiary);
        await _diaryDao.deletePhotosForDiary(savedDiary.id!);
        await _diaryDao.insertPhotos(savedDiary.id!, savedDiary.photoPaths);
      } else if (diary.id == null) {
        // 새로운 일기 추가
        final newId = DateTime.now().millisecondsSinceEpoch.toString();
        final newDiary = diary.copyWith(id: newId);
        await _diaryDao.insertDiary(newDiary);
        savedDiary = newDiary;
        await _diaryDao.insertPhotos(newDiary.id!, newDiary.photoPaths);
      } else {
        // id가 있으나 기존에 없는 경우 (명시적 저장)
        savedDiary = diary;
        await _diaryDao.updateDiary(savedDiary);
        await _diaryDao.deletePhotosForDiary(savedDiary.id!);
        await _diaryDao.insertPhotos(savedDiary.id!, savedDiary.photoPaths);
      }

      await _cleanupPhotos();
      await loadDiaries();
      return savedDiary;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> searchDiaries(String query, {int? limit, int? offset}) async {
    return await _diaryDao.searchDiaries(query, limit: limit, offset: offset);
  }

  Future<void> _cleanupPhotos() async {
    try {
      final allDiaries = await _diaryDao.getAllDiaries();
      final allPhotoPaths = allDiaries.expand((d) => d.photoPaths).toSet().toList();
      await FileManager.cleanupUnusedPhotos(allPhotoPaths);
    } catch (e) {
      // 무시 또는 로그
    }
  }
}
