import 'package:flutter/material.dart';
import 'package:recap_today/model/schedule_item.dart';
import 'package:collection/collection.dart';

class ScheduleProvider extends ChangeNotifier {
  final List<ScheduleItem> _items = [];

  List<ScheduleItem> get items => _items;

  ScheduleItem? getItemById(String id) {
    return _items.firstWhereOrNull((item) => item.id == id);
  }

  void addItem(ScheduleItem item) {
    _items.add(item);
    notifyListeners();
  }

  void updateItem(ScheduleItem updatedItem) {
    final index = _items.indexWhere((item) => item.id == updatedItem.id);
    if (index != -1) {
      _items[index] = updatedItem;
      notifyListeners();
    }
  }

  void removeItem(String id) {
    _items.removeWhere((item) => item.id == id);
    notifyListeners();
  }

  List<ScheduleItem> getItemsForDay(int dayOfWeek) {
    return _items.where((item) => item.dayOfWeek == dayOfWeek).toList();
  }

  List<ScheduleItem> getRoutineItems() {
    return _items.where((item) => item.isRoutine).toList();
  }

  List<ScheduleItem> getUserItems() {
    return _items.where((item) => !item.isRoutine).toList();
  }
}