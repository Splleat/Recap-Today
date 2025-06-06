import 'package:flutter/material.dart';
import 'package:recap_today/model/freezed/schedule_item.dart';
import 'package:recap_today/data/database_helper.dart';
import 'package:collection/collection.dart';
import 'package:recap_today/provider/login_provider.dart';

class ScheduleProvider extends ChangeNotifier {
  final List<ScheduleItem> _items = [];
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final LoginProvider _loginProvider;

  List<ScheduleItem> get items => _items;

  ScheduleProvider({required LoginProvider loginProvider}) 
      : _loginProvider = loginProvider {
      _loginProvider.addListener(() {
        // 로그인 상태가 변경될 때마다 아이템을 새로 로드
        _loadItems();
      });
  }
  
  // userId getter를 LoginProvider에서 가져오도록 수정
  String get userId => _loginProvider.activeUserId;

  Future<void> _loadItems() async {
    try {
      final dbItems = await _dbHelper.getAllScheduleItems(userId);
      debugPrint('로드된 일정 개수: ${dbItems.length}');
      for (var item in dbItems) {
        debugPrint('로드된 일정: ${item.id}, ${item.text}, ${item.selectedDate}');
      }
      _items.clear();
      _items.addAll(dbItems);
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to load schedule items: $e');
    }
  }

  ScheduleItem? getItemById(String id) {
    return _items.firstWhereOrNull((item) => item.id == id);
  }

  Future<void> addItem(ScheduleItem item) async {
    try {
      debugPrint('==== 일정 추가 시작 ====');
      debugPrint('ID: ${item.id}');
      debugPrint('제목: ${item.text}');
      debugPrint('설명: ${item.subText}');
      debugPrint('날짜: ${item.selectedDate}');
      debugPrint('요일: ${item.dayOfWeek}');
      debugPrint('루틴여부: ${item.isRoutine}');
      debugPrint('사용자 ID: ${item.userId ?? "로컬 사용자"}');
      debugPrint('==== 일정 추가 정보 끝 ====');

      await _dbHelper.insertScheduleItem(item);
      _items.add(item);
      debugPrint('일정 추가 완료');
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to add schedule item: $e');
    }
  }

  Future<void> updateItem(ScheduleItem updatedItem) async {
    try {
      final index = _items.indexWhere((item) => item.id == updatedItem.id);
      if (index != -1) {
        await _dbHelper.updateScheduleItem(updatedItem);
        _items[index] = updatedItem;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Failed to update schedule item: $e');
    }
  }

  Future<void> removeItem(String id, String userId) async {
    try {
      await _dbHelper.deleteScheduleItem(id, userId);
      _items.removeWhere((item) => item.id == id);
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to remove schedule item: $e');
    }
  }

  List<ScheduleItem> getItemsForDay(int dayOfWeek) {
    return _items.where((item) => item.dayOfWeek == dayOfWeek).toList();
  }

  // Get items for a specific date (for non-routine items)
  Future<List<ScheduleItem>> getItemsByDate(String date, String userId) async {
    try {
      final items = await _dbHelper.getScheduleItemsByDate(date, userId);
      return items;
    } catch (e) {
      debugPrint('Failed to get schedule items by date: $e');
      return [];
    }
  }

  // Load items for a specific date and update provider state
  Future<void> loadItemsByDate(String date, String userId) async {
    try {
      final dbItems = await _dbHelper.getScheduleItemsByDate(date, userId);
      _items.clear();
      _items.addAll(dbItems);
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to load schedule items by date: $e');
    }
  }

  List<ScheduleItem> getRoutineItems() {
    return _items.where((item) => item.isRoutine).toList();
  }

  List<ScheduleItem> getUserItems() {
    return _items.where((item) => !item.isRoutine).toList();
  }

  // Get both routine items for dayOfWeek and specific date items
  Future<List<ScheduleItem>> getDailySchedule(int dayOfWeek, String date, String userId) async {
    try {
      // Get all items
      await _loadItems();

      // Filter routine items by day of week
      final routineItems = _items.where((item) =>
          item.isRoutine && item.dayOfWeek == dayOfWeek).toList();

      // Get specific date items
      final dateItems = await getItemsByDate(date, userId);

      // Combine and return both
      return [...routineItems, ...dateItems];
    } catch (e) {
      debugPrint('Failed to get daily schedule: $e');
      return [];
    }
  }
}
