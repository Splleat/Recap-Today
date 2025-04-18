// sqflite_database.dart
import 'package:recap_today/model/diary_model.dart';
import 'package:recap_today/data/abstract_database.dart';
import 'package:recap_today/data/database_helper.dart';

/// sqflite 데이터베이스 구현
class SqfliteDatabase extends AbstractDatabase {
  final DatabaseHelper _helper = DatabaseHelper.instance;

  @override
  Future<int> insertDiary(DiaryModel diary) async {
    return await _helper.insertDiary(diary);
  }

  @override
  Future<int> updateDiary(DiaryModel diary) async {
    return await _helper.updateDiary(diary);
  }

  @override
  Future<List<DiaryModel>> getDiaries() async {
    return await _helper.getDiaries();
  }

  @override
  Future<DiaryModel?> getDiaryForDate(String date) async {
    return await _helper.getDiaryForDate(date);
  }
}
