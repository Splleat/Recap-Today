import 'package:flutter/material.dart';
import 'package:recap_today/model/freezed/checklist_item.dart';
import 'package:collection/collection.dart';
import 'package:recap_today/data/sqflite_database.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:recap_today/provider/login_provider.dart';

/// 체크리스트 항목을 관리하는 Provider 클래스
/// 앱 전체에서 체크리스트 상태를 관리하고 데이터베이스와 동기화합니다.
class ChecklistProvider extends ChangeNotifier {
  final List<ChecklistItem> _items = [];
  final SqfliteDatabase _database = SqfliteDatabase();
  bool _isLoaded = false;
  bool _isBusy = false; // 데이터베이스 작업 중 상태를 추적하는 플래그
  String _userId = 'default_user'; // 기본값 설정

  // 캐싱을 위한 변수들
  DateTime? _lastRefreshTime;
  List<ChecklistItem>? _cachedTodayCompletedItems;
  String _todayDateString = '';
  Map<String, List<ChecklistItem>> _dateCache = {};

  // 생성자
  ChecklistProvider() {
    _updateTodayDateString();
    _loadItems();
  }

  // LoginProvider에서 userId 설정
  void setUserId(String userId) {
    if (_userId != userId) {
      _userId = userId;
      _isLoaded = false; // userId가 변경되면 데이터 다시 로드
      _invalidateCache(); // 캐시 초기화
      _loadItems(); // 새 userId로 아이템 로드
    }
  }

  // Getter 메서드들
  List<ChecklistItem> get items => List.unmodifiable(_items); // 불변 리스트 반환
  bool get isLoading => !_isLoaded;
  String get userId => _userId;

  /// 특정 날짜에 완료된 항목들을 반환하는 메서드
  List<ChecklistItem> getCompletedItemsForDate(DateTime date) {
    // 캐시 키 생성
    final dateString = DateFormat('yyyy-MM-dd').format(date);
    
    // 캐시에 해당 날짜 데이터가 있으면 반환
    if (_dateCache.containsKey(dateString)) {
      return _dateCache[dateString]!;
    }
    
    // 날짜만 비교하기 위해 시간, 분, 초를 0으로 설정
    final targetDay = DateTime(date.year, date.month, date.day);
    final result = _items.where((item) {
      if (!item.isChecked || item.completedDate == null) {
        return false;
      }
      final completedDay = DateTime(
        item.completedDate!.year,
        item.completedDate!.month,
        item.completedDate!.day,
      );
      return completedDay.isAtSameMomentAs(targetDay);
    }).toList();
    
    // 결과를 캐시에 저장
    _dateCache[dateString] = result;
    return result;
  }

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
          await _database.getAllChecklistItems(_userId);

      _items.clear();
      // 데이터베이스에서 불러온 아이템으로 목록 업데이트
      _items.addAll(loadedItems);
      _sortItems();

      _isLoaded = true;
      _isBusy = false;
      // 캐시 초기화
      _invalidateCache();
      notifyListeners();
    } catch (e) {
      debugPrint('체크리스트 아이템 로드 중 오류 발생: $e');
      _isBusy = false;
      _isLoaded = true;
      notifyListeners();
    }
  }

  /// 캐시 무효화 처리
  void _invalidateCache() {
    _cachedTodayCompletedItems = null;
    _lastRefreshTime = null;
    _dateCache.clear();
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
    
    // userId 설정 확인
    final updatedItem = item.copyWith(userId: _userId);
    
    _items.add(updatedItem);
    _sortItems();
    _invalidateCache();
    notifyListeners();

    // 데이터베이스에 저장
    _isBusy = true;
    await _database.insertChecklistItem(updatedItem);
    _isBusy = false;
  }

  /// 아이템 체크 상태 토글
  Future<void> toggleItem(String id, bool isChecked) async {
    final index = _findIndexById(id);
    if (index == -1 || _isBusy) return;

    final updatedItem = _items[index].copyWith(
      isChecked: isChecked,
      completedDate: isChecked ? DateTime.now() : null,
    );
    
    _items[index] = updatedItem;
    _sortItems();
    _invalidateCache();
    notifyListeners();

    // 데이터베이스 업데이트
    _isBusy = true;
    await _database.updateChecklistItem(updatedItem);
    _isBusy = false;
  }

  /// 아이템 업데이트 통합 메서드 (텍스트, 세부내용, 마감일 등)
  Future<void> updateItem(String id, {String? text, String? subtext, DateTime? dueDate}) async {
    if (_isBusy) return;
    if (text != null && text.isEmpty) return; // 빈 텍스트 허용 안함

    final index = _findIndexById(id);
    if (index == -1) return;

    // freezed 모델의 copyWith 사용하여 필요한 필드만 업데이트
    final updatedItem = _items[index].copyWith(
      text: text ?? _items[index].text,
      subtext: subtext ?? _items[index].subtext,
      dueDate: dueDate != null ? dueDate : _items[index].dueDate,
    );
    
    _items[index] = updatedItem;
    
    // 텍스트나 마감일이 변경된 경우에만 정렬
    if (text != null || dueDate != null) {
      _sortItems();
    }
    
    notifyListeners();

    // 데이터베이스 업데이트
    _isBusy = true;
    await _database.updateChecklistItem(updatedItem);
    _isBusy = false;
  }

  /// 아이템 삭제
  Future<void> removeItem(String id) async {
    if (_isBusy) return;

    final index = _findIndexById(id);
    if (index == -1) return;

    _items.removeAt(index);
    _invalidateCache();
    notifyListeners();

    // 데이터베이스에서 삭제
    _isBusy = true;
    await _database.deleteChecklistItem(id, userId);
    _isBusy = false;
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

  /// 완료된 항목들(체크 표시된 항목들)을 모두 제거
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
      for (final item in completedItems) {
        await _database.deleteChecklistItem(item.id, userId);
      }
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
  Future<List<ChecklistItem>> getCompletedItemsByDate(String date) async {
    try {
      return await _database.getChecklistItemsByCompletedDate(date, _userId);
    } catch (e) {
      debugPrint('날짜별 완료된 항목 조회 중 오류 발생: $e');
      
      // 메모리에서 필터링
      final targetDate = date;
      return _items.where((item) {
        if (!item.isChecked || item.completedDate == null) return false;
        return DateFormat('yyyy-MM-dd').format(item.completedDate!) == targetDate;
      }).toList();
    }
  }

  /// 미완료된 항목들만 가져오기
  Future<List<ChecklistItem>> getIncompleteItems() async {
    try {
      return await _database.getIncompleteChecklistItems(_userId);
    } catch (e) {
      debugPrint('미완료 항목 조회 중 오류 발생: $e');
      // 메모리에서 필터링
      return _items.where((item) => !item.isChecked).toList();
    }
  }

  /// 완료된 항목들만 가져오기
  Future<List<ChecklistItem>> getCompletedItems() async {
    try {
      return await _database.getCompletedChecklistItems(_userId);
    } catch (e) {
      debugPrint('완료된 항목 조회 중 오류 발생: $e');
      // 메모리에서 필터링
      return _items.where((item) => item.isChecked).toList();
    }
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

    // 오늘 날짜 문자열
    final todayString = DateFormat('yyyy-MM-dd').format(DateTime.now());

    // 오늘 완료된 항목 계산
    _cachedTodayCompletedItems = _items.where((item) {
      if (!item.isChecked || item.completedDate == null) return false;
      return DateFormat('yyyy-MM-dd').format(item.completedDate!) == todayString;
    }).toList();
    
    _lastRefreshTime = now;
    return _cachedTodayCompletedItems!;
  }
}
