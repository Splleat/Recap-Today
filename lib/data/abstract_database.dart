// abstract_database.dart
import 'package:recap_today/model/diary_model.dart';

/// 데이터베이스 추상 클래스
abstract class AbstractDatabase {
  Future<int> insertDiary(DiaryModel diary);
  Future<int> updateDiary(DiaryModel diary);
  Future<List<DiaryModel>> getDiaries();
  Future<DiaryModel?> getDiaryForDate(String date);
}
