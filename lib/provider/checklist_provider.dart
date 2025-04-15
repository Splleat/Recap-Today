import 'package:flutter/material.dart';
import 'package:recap_today/model/checklist_item.dart'; // ChecklistItemModel 파일 임포트
import 'package:collection/collection.dart';

class ChecklistProvider extends ChangeNotifier {
  final List<ChecklistItem> _items = []; // 내부에서 관리할 체크리스트 아이템 리스트

  int _findIndexById(String id) => _items.indexWhere((item) => item.id == id); // index 찾는 로직

  ChecklistProvider() {
    // 초기 더미 데이터 추가
    _items.addAll([
      ChecklistItem(id: '1', text: '오늘 할 일 1', isChecked: false),
      ChecklistItem(id: '2', text: '내일 할 일 2', isChecked: true, dueDate: DateTime.now().add(const Duration(days: 1))),
      ChecklistItem(id: '3', text: '이번 주말 할 일 3', isChecked: false, subtext: '세부 내용'),
      ChecklistItem(id: '4', text: '오늘 할 일 1', isChecked: false),
      ChecklistItem(id: '5', text: '내일 할 일 2', isChecked: true, dueDate: DateTime.now().add(const Duration(days: 1))),
      ChecklistItem(id: '6', text: '이번 주말 할 일 3', isChecked: false, subtext: '세부 내용'),
      ChecklistItem(id: '7', text: '오늘 할 일 1', isChecked: false),
      ChecklistItem(id: '8', text: '내일 할 일 2', isChecked: true, dueDate: DateTime.now().add(const Duration(days: 1))),
      ChecklistItem(id: '9', text: '이번 주말 할 일 3', isChecked: false, subtext: '세부 내용'),
    ]);
  }

  // 체크리스트 아이템 리스트 getter (UI에서 접근 가능)
  List<ChecklistItem> get items => _items;

  // 특정 ID 아이템 가져오기
  ChecklistItem? getItemById(String id) {
    return _items.firstWhereOrNull((item) => item.id == id);
  }

  // 새로운 아이템 추가
  void addItem(ChecklistItem item) {
    _items.add(item);
    notifyListeners(); // 상태 변경 알림
  }

  // 아이템 체크 상태 토글
  void toggleItem(String id, bool isChecked) {
    final index = _findIndexById(id);
    if (index != -1) {
      _items[index].isChecked = isChecked;
      notifyListeners(); // 상태 변경 알림
    }
  }

  // 아이템 텍스트 업데이트
  void updateItemText(String id, String newText) {
    final index = _findIndexById(id);
    if (index != -1) {
      _items[index].text = newText;
      notifyListeners();
    }
  }

  void updateItemSubtext(String id, String newSubtext) {
    final index = _findIndexById(id);
    if (index != -1) {
      _items[index].subtext = newSubtext;
      notifyListeners();
    }
  }

  // 아이템 마감일 업데이트
  void updateItemDueDate(String id, DateTime? newDueDate) {
    final index = _findIndexById(id);
    if (index != -1) {
      _items[index].dueDate = newDueDate;
      notifyListeners();
    }
  }

  // 아이템 삭제
  void removeItem(String id) {
    _items.removeWhere((item) => item.id == id);
    notifyListeners(); // 상태 변경 알림
  }
}