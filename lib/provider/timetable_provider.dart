import 'package:flutter/material.dart';
import 'package:recap_today/model/timetable_item.dart'; // TimetableItem 모델 임포트

class TimetableProvider extends ChangeNotifier {
  final List<TimetableItem> _items = []; // 내부에서 관리할 시간표 아이템 리스트

  // 시간표 아이템 리스트 getter (UI에서 접근 가능)
  List<TimetableItem> get items => _items;

  // 새로운 아이템 추가
  void addItem(TimetableItem item) {
    _items.add(item);
    notifyListeners(); // 상태 변경 알림
  }

  // 아이템 업데이트
  void updateItem(TimetableItem updatedItem) {
    final index = _items.indexWhere((item) => item.id == updatedItem.id);
    if (index != -1) {
      _items[index] = updatedItem;
      notifyListeners(); // 상태 변경 알림
    }
  }

  // 아이템 삭제
  void removeItem(String id) {
    _items.removeWhere((item) => item.id == id);
    notifyListeners(); // 상태 변경 알림
  }

  // 특정 요일의 아이템 가져오기 (UI에서 필요할 수 있음)
  List<TimetableItem> getItemsForDay(int dayOfWeek) {
    return _items.where((item) => item.dayOfWeek == dayOfWeek).toList();
  }

  // 특정 시간대의 아이템 가져오기 (UI에서 필요할 수 있음)
  List<TimetableItem> getItemsForTimeRange(TimeOfDay startTime, TimeOfDay endTime) {
    return _items.where((item) =>
    (item.startTime.hour < endTime.hour ||
        (item.startTime.hour == endTime.hour && item.startTime.minute <= endTime.minute)) &&
        (item.endTime.hour > startTime.hour ||
            (item.endTime.hour == startTime.hour && item.endTime.minute >= startTime.minute))).toList();
  }
}