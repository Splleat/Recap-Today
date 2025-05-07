// abstract_database.dart
import 'package:recap_today/model/diary_model.dart';
import 'package:recap_today/model/checklist_item.dart';

/// 데이터베이스 접근을 위한 추상 인터페이스
/// 다양한 데이터베이스 구현체를 일관적으로 사용할 수 있도록 정의합니다.
abstract class AbstractDatabase {
  // 일기 관련 메서드
  Future<int> insertDiary(DiaryModel diary);
  Future<int> updateDiary(DiaryModel diary);
  Future<List<DiaryModel>> getDiaries();
  Future<DiaryModel?> getDiaryForDate(String date);

  // 체크리스트 관련 메서드
  Future<int> insertChecklistItem(ChecklistItem item);
  Future<int> updateChecklistItem(ChecklistItem item);
  Future<List<ChecklistItem>> getChecklistItems();
  Future<ChecklistItem?> getChecklistItemById(String id);
  Future<int> deleteChecklistItem(String id);
  Future<int> deleteAllChecklistItems();
  Future<void> saveChecklistItems(List<ChecklistItem> items);
}
