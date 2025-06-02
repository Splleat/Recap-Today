import 'package:flutter/material.dart';
import 'package:recap_today/model/checklist/checklist_item.dart';
import 'package:recap_today/dao/checklist_dao.dart';
import 'package:intl/intl.dart';

class ChecklistProvider extends ChangeNotifier {
  final List<ChecklistItem> _items = [];
  final ChecklistDao _checklistDao;

  bool _isLoaded = false;
  bool _isBusy = false;

  // 생성자: 데이터베이스 객체 초기화 및 항목 로드
  ChecklistProvider({ChecklistDao? checklistDao})
      : _checklistDao = checklistDao ?? ChecklistDao() {
    _loadItems();
  }

  // 체크리스트 항목을 읽기 전용으로 반환
  List<ChecklistItem> get items => List.unmodifiable(_items);

  // 데이터 로드 상태를 반환
  bool get isLoading => !_isLoaded;

  // ID로 항목의 인덱스를 찾음
  int _findIndexById(String id) => _items.indexWhere((item) => item.id == id);

  // 데이터베이스에서 체크리스트 항목을 로드
  Future<void> _loadItems() async {
    await _lock(() async {
      if (_isLoaded) return;

      try {
        final loadedItems = await _checklistDao.getAllChecklists();
        _items
          ..clear()
          ..addAll(loadedItems);
        _sortItems();
        _isLoaded = true;
        notifyListeners();
      } catch (e) {
        debugPrint('체크리스트 불러오기 오류: $e');
      }
    });
  }

  // 항목을 새로고침
  Future<void> refreshItems() async {
    await _lock(() async {
      _isLoaded = false;
      notifyListeners();
      await _loadItems();
    });
  }

  // 새로운 항목을 추가
  Future<void> addItem(ChecklistItem item) async {
    await _lock(() async {
      try {
        await _checklistDao.insertChecklist(item);
        _items.add(item);
        _sortItems();
        notifyListeners();
      } catch (e) {
        debugPrint('체크리스트 추가 오류: $e');
      }
    });
  }

  // 특정 항목을 업데이트
  Future<void> updateItem({
    required String id,
    String? newText,
    String? newSubtext,
    DateTime? newDueDate,
    bool? isChecked,
  }) async {
    await _lock(() async {
      final index = _findIndexById(id);
      if (index == -1) return;

      final oldItem = _items[index];
      final updatedItem = oldItem.copyWith(
        text: newText ?? oldItem.text,
        subtext: newSubtext ?? oldItem.subtext,
        dueDate: newDueDate ?? oldItem.dueDate,
        isChecked: isChecked ?? oldItem.isChecked,
        completedDate: isChecked != null
            ? (isChecked ? DateTime.now() : null)
            : oldItem.completedDate,
      );

      _items[index] = updatedItem;
      _sortItems();
      notifyListeners();

      try {
        await _checklistDao.updateChecklist(updatedItem);
      } catch (e) {
        _items[index] = oldItem; // 실패 시 기존 항목 복구
        _sortItems();
        notifyListeners();
        _logError('항목 업데이트', e);
      }
    });
  }

  // 특정 항목을 삭제
  Future<void> removeItem(String id) async {
    await _lock(() async {
      final index = _findIndexById(id);
      if (index == -1) return;

      final deletedItem = _items.removeAt(index);
      notifyListeners();

      try {
        await _checklistDao.deleteChecklist(id);
      } catch (e) {
        _items.insert(index, deletedItem); // 실패 시 항목 복구
        _sortItems();
        notifyListeners();
        _logError('항목 삭제', e);
      }
    });
  }

  // 특정 날짜에 완료된 항목을 반환
  List<ChecklistItem> getCompletedItemsForDate(DateTime date) {
    final targetDate = DateFormat('yyyy-MM-dd').format(date);
    return _items.where((item) {
      if (!item.isChecked || item.completedDate == null) return false;
      return DateFormat('yyyy-MM-dd').format(item.completedDate!) == targetDate;
    }).toList();
  }

  // 항목을 정렬
  void _sortItems() {
    _items.sort((a, b) {
      int result = (a.isChecked ? 1 : 0).compareTo(b.isChecked ? 1 : 0);
      if (result == 0) result = _compareDueDates(a.dueDate, b.dueDate);
      return result;
    });
  }

  // 두 마감일을 비교
  int _compareDueDates(DateTime? a, DateTime? b) {
    if (a == null && b == null) return 0;
    if (a == null) return 1;
    if (b == null) return -1;
    return a.compareTo(b);
  }

  // 작업 중 상태를 관리하는 메소드
  Future<void> _lock(Future<void> Function() action) async {
    if (_isBusy) return;
    _isBusy = true;
    try {
      await action();
    } finally {
      _isBusy = false;
    }
  }

  // 오류를 로그로 출력하는 메서드
  void _logError(String message, Object error) {
    debugPrint('$message 오류: $error');
  }
}
