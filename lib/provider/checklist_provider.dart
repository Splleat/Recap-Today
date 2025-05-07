import 'package:flutter/material.dart';
import 'package:recap_today/model/checklist_item.dart';
import 'package:collection/collection.dart';
import 'package:recap_today/data/database_helper.dart';
import 'package:intl/intl.dart';

/// 체크리스트 항목을 관리하는 Provider 클래스
/// 앱 전체에서 체크리스트 상태를 관리하고 데이터베이스와 동기화합니다.
class ChecklistProvider extends ChangeNotifier {
  final List<ChecklistItem> _items = [];
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  bool _isLoaded = false;
  bool _isBusy = false; // 데이터베이스 작업 중 상태를 추적하는 플래그

  // 캐싱을 위한 변수들
  DateTime? _lastRefreshTime;
  List<ChecklistItem>? _cachedTodayCompletedItems;
  String _todayDateString = '';

  // 생성자
  ChecklistProvider() {
    _updateTodayDateString();
    _loadItems();
  }

  // Getter 메서드들
  List<ChecklistItem> get items => List.unmodifiable(_items); // 불변 리스트 반환으로 변경
  bool get isLoading => !_isLoaded;

  // 오늘 날짜 문자열 업데이트
  void _updateTodayDateString() {
    _todayDateString = DateFormat('yyyy-MM-dd').format(DateTime.now());
  }

  /// 데이터베이스에서 아이템 로드
  Future<void> _loadItems() async {
    if (_isLoaded || _isBusy) return;

    try {
      _isBusy = true;
      // 데이터베이스에서 체크리스트 아이템 불러오기
      final List<ChecklistItem> loadedItems =
          await _dbHelper.getChecklistItems();

      _items.clear();
      if (loadedItems.isEmpty) {
        // 데이터베이스에 아이템이 없는 경우, 더미 데이터 추가
        _addDummyItems();
      } else {
        // 데이터베이스에서 불러온 아이템으로 목록 업데이트
        _items.addAll(loadedItems);
        _sortItems();
      }

      _isLoaded = true;
      _isBusy = false;
      // 캐시 초기화
      _invalidateCache();
      notifyListeners();
    } catch (e) {
      debugPrint('체크리스트 아이템 로드 중 오류 발생: $e');
      // 오류 발생 시 더미 데이터로 폴백
      if (_items.isEmpty) {
        _addDummyItems();
      }
      _isBusy = false;
      _isLoaded = true;
      notifyListeners();
    }
  }

  /// 더미 데이터 추가 헬퍼 메서드
  void _addDummyItems() {
    _items.addAll([
      ChecklistItem(id: '1', text: '오늘 할 일 1', isChecked: false),
      ChecklistItem(
        id: '2',
        text: '내일 할 일 1',
        isChecked: false,
        dueDate: DateTime.now().add(const Duration(days: 1)),
      ),
      ChecklistItem(
        id: '3',
        text: '이번 주말 할 일 1',
        isChecked: false,
        subtext: '세부 내용',
      ),
      ChecklistItem(id: '4', text: '오늘 할 일 2', isChecked: false),
      ChecklistItem(
        id: '5',
        text: '내일 할 일 2',
        isChecked: false,
        dueDate: DateTime.now().add(const Duration(days: 1)),
      ),
      ChecklistItem(
        id: '6',
        text: '이번 주말 할 일 2',
        isChecked: false,
        subtext: '세부 내용',
      ),
      ChecklistItem(id: '7', text: '오늘 할 일 3', isChecked: false),
      ChecklistItem(
        id: '8',
        text: '내일 할 일 3',
        isChecked: false,
        dueDate: DateTime.now().add(const Duration(days: 1)),
      ),
      ChecklistItem(
        id: '9',
        text: '이번 주말 할 일 3',
        isChecked: false,
        subtext: '세부 내용',
      ),
    ]);

    // 더미 데이터를 데이터베이스에 일괄 저장 (개선됨)
    _saveAllItems();
    _sortItems();
  }

  /// 모든 아이템을 데이터베이스에 일괄 저장 (배치 처리 사용)
  Future<void> _saveAllItems() async {
    if (_items.isEmpty) return;

    try {
      // 개선된 일괄 저장 메서드 사용
      await _dbHelper.saveChecklistItems(List<ChecklistItem>.from(_items));
      _invalidateCache();
    } catch (e) {
      debugPrint('체크리스트 아이템 일괄 저장 중 오류 발생: $e');
    }
  }

  /// 캐시 무효화 처리
  void _invalidateCache() {
    _cachedTodayCompletedItems = null;
    _lastRefreshTime = null;
    _updateTodayDateString();
  }

  /// ID로 아이템 인덱스 찾기
  int _findIndexById(String id) => _items.indexWhere((item) => item.id == id);

  /// 특정 ID 아이템 가져오기
  ChecklistItem? getItemById(String id) {
    return _items.firstWhereOrNull((item) => item.id == id);
  }

  /// 새로운 아이템 추가
  Future<void> addItem(ChecklistItem item) async {
    if (_isBusy) return;

    _items.add(item);
    _sortItems();
    _invalidateCache();
    notifyListeners();

    // 데이터베이스에 저장
    try {
      _isBusy = true;
      await _dbHelper.insertChecklistItem(item);
    } catch (e) {
      debugPrint('체크리스트 아이템 추가 중 오류 발생: $e');
    } finally {
      _isBusy = false;
    }
  }

  /// 아이템 체크 상태 토글
  Future<void> toggleItem(String id, bool isChecked) async {
    final index = _findIndexById(id);
    if (index == -1 || _isBusy) return;

    _items[index].isChecked = isChecked;

    // 체크 상태 변경 시 completedDate 업데이트
    if (isChecked) {
      _items[index].completedDate = DateTime.now();
    } else {
      _items[index].completedDate = null;
    }

    _sortItems();
    _invalidateCache();
    notifyListeners();

    // 데이터베이스 업데이트
    try {
      _isBusy = true;
      await _dbHelper.updateChecklistItem(_items[index]);
    } catch (e) {
      debugPrint('체크리스트 아이템 상태 업데이트 중 오류 발생: $e');
      // 실패 시 상태 롤백
      _items[index].isChecked = !isChecked;
      _sortItems();
      notifyListeners();
    } finally {
      _isBusy = false;
    }
  }

  /// 아이템 텍스트 업데이트
  Future<void> updateItemText(String id, String newText) async {
    if (newText.isEmpty || _isBusy) return; // 빈 텍스트 허용 안함

    final index = _findIndexById(id);
    if (index == -1) return;

    final oldText = _items[index].text;
    _items[index].text = newText;
    _sortItems();
    notifyListeners();

    // 데이터베이스 업데이트
    try {
      _isBusy = true;
      await _dbHelper.updateChecklistItem(_items[index]);
    } catch (e) {
      debugPrint('체크리스트 아이템 텍스트 업데이트 중 오류 발생: $e');
      // 실패 시 상태 롤백
      _items[index].text = oldText;
      _sortItems();
      notifyListeners();
    } finally {
      _isBusy = false;
    }
  }

  /// 아이템 세부 내용 업데이트
  Future<void> updateItemSubtext(String id, String newSubtext) async {
    if (_isBusy) return;

    final index = _findIndexById(id);
    if (index == -1) return;

    final oldSubtext = _items[index].subtext;
    _items[index].subtext = newSubtext;
    notifyListeners();

    // 데이터베이스 업데이트
    try {
      _isBusy = true;
      await _dbHelper.updateChecklistItem(_items[index]);
    } catch (e) {
      debugPrint('체크리스트 아이템 세부 내용 업데이트 중 오류 발생: $e');
      // 실패 시 상태 롤백
      _items[index].subtext = oldSubtext;
      notifyListeners();
    } finally {
      _isBusy = false;
    }
  }

  /// 아이템 마감일 업데이트
  Future<void> updateItemDueDate(String id, DateTime? newDueDate) async {
    if (_isBusy) return;

    final index = _findIndexById(id);
    if (index == -1) return;

    final oldDueDate = _items[index].dueDate;
    _items[index].dueDate = newDueDate;
    _sortItems();
    notifyListeners();

    // 데이터베이스 업데이트
    try {
      _isBusy = true;
      await _dbHelper.updateChecklistItem(_items[index]);
    } catch (e) {
      debugPrint('체크리스트 아이템 마감일 업데이트 중 오류 발생: $e');
      // 실패 시 상태 롤백
      _items[index].dueDate = oldDueDate;
      _sortItems();
      notifyListeners();
    } finally {
      _isBusy = false;
    }
  }

  /// 아이템 삭제
  Future<void> removeItem(String id) async {
    if (_isBusy) return;

    final index = _findIndexById(id);
    if (index == -1) return;

    final deletedItem = _items[index];
    _items.removeAt(index);
    notifyListeners();

    // 데이터베이스에서 삭제
    try {
      _isBusy = true;
      await _dbHelper.deleteChecklistItem(id);
    } catch (e) {
      debugPrint('체크리스트 아이템 삭제 중 오류 발생: $e');
      // 실패 시 상태 롤백
      _items.insert(index, deletedItem);
      notifyListeners();
    } finally {
      _isBusy = false;
    }
  }

  /// 내부 정렬 함수
  void _sortItems() {
    _items.sort((a, b) {
      // 1순위: 완료 여부(미완료 아이템이 완료 아이템보다 앞으로)
      int compareResult = (a.isChecked ? 1 : 0).compareTo(b.isChecked ? 1 : 0);
      // 2순위: 마감 시간(마감 시간이 null일 경우 뒤로)
      if (compareResult == 0) {
        compareResult = _compareDueDates(a.dueDate, b.dueDate);
      }
      return compareResult;
    });
  }

  /// 마감일 비교 헬퍼 함수
  int _compareDueDates(DateTime? aDate, DateTime? bDate) {
    if (aDate == null && bDate == null) return 0;
    if (aDate == null) return 1;
    if (bDate == null) return -1;
    return aDate.compareTo(bDate);
  }

  /// 데이터베이스에서 데이터 새로고침
  Future<void> refreshItems() async {
    if (_isBusy) return;

    _isLoaded = false;
    _invalidateCache();
    notifyListeners(); // 로딩 상태 변경 알림
    await _loadItems();
  }

  /// 여러 항목 동시에 상태 변경 (일괄 처리)
  Future<void> toggleMultipleItems(List<String> ids, bool isChecked) async {
    if (ids.isEmpty || _isBusy) return;

    // 메모리 내 상태 업데이트
    for (final id in ids) {
      final index = _findIndexById(id);
      if (index != -1) {
        _items[index].isChecked = isChecked;
      }
    }

    _sortItems();
    notifyListeners();

    // 모든 변경사항 저장
    try {
      _isBusy = true;
      await _saveAllItems();
    } catch (e) {
      debugPrint('여러 항목 상태 변경 중 오류 발생: $e');
      await refreshItems(); // 오류 발생 시 데이터베이스에서 다시 로드
    } finally {
      _isBusy = false;
    }
  }

  /// 완료된 항목들(체크 표시된 항목들)을 모두 제거하고 데이터베이스에는 저장
  Future<void> clearCompletedItems() async {
    if (_isBusy) return;

    // 완료된 항목만 제거하기 전에 현재 상태 백업
    final List<ChecklistItem> completedItems =
        _items.where((item) => item.isChecked).toList();

    if (completedItems.isEmpty) {
      return; // 완료된 항목이 없으면 처리 건너뛰기
    }

    // 완료된 항목 제거
    _items.removeWhere((item) => item.isChecked);
    _invalidateCache();
    notifyListeners();

    // 데이터베이스 업데이트
    try {
      _isBusy = true;
      await _saveAllItems();
    } catch (e) {
      debugPrint('완료된 항목 제거 중 오류 발생: $e');
      // 오류 발생 시 제거된 항목 복원
      _items.addAll(completedItems);
      _sortItems();
      notifyListeners();
    } finally {
      _isBusy = false;
    }
  }

  /// 특정 날짜에 완료된 항목들만 가져오기
  List<ChecklistItem> getCompletedItemsByDate(DateTime date) {
    final String dateString = DateFormat('yyyy-MM-dd').format(date);

    return _items.where((item) {
      if (item.completedDate == null) return false;
      return DateFormat('yyyy-MM-dd').format(item.completedDate!) == dateString;
    }).toList();
  }

  /// 오늘 완료된 항목들만 가져오기 (캐싱 최적화)
  List<ChecklistItem> getTodayCompletedItems() {
    // 날짜가 변경되었는지 확인
    final currentDateString = DateFormat('yyyy-MM-dd').format(DateTime.now());
    if (_todayDateString != currentDateString) {
      _updateTodayDateString();
      _invalidateCache();
    }

    // 캐시된 결과가 있고 마지막 갱신 시간이 1분 이내면 캐시 사용
    final now = DateTime.now();
    if (_cachedTodayCompletedItems != null && _lastRefreshTime != null) {
      final difference = now.difference(_lastRefreshTime!);
      if (difference.inMinutes < 1) {
        return _cachedTodayCompletedItems!;
      }
    }

    // 오늘 완료된 항목 계산
    _cachedTodayCompletedItems =
        _items
            .where((item) => item.isChecked && item.isCompletedToday)
            .toList();
    _lastRefreshTime = now;

    return _cachedTodayCompletedItems!;
  }
}
