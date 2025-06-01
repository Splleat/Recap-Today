import 'package:flutter/material.dart';
import 'package:recap_today/model/schedule_item.dart';
import 'package:collection/collection.dart';
import 'package:recap_today/data/abstract_database.dart';

class ScheduleProvider extends ChangeNotifier {
  List<ScheduleItem> _items = [];
  final AbstractDatabase _database;

  ScheduleProvider(this._database) {
    loadItems();
  }

  List<ScheduleItem> get items => _items;

  Future<void> loadItems() async {
    _items = await _database.getScheduleItems();
    notifyListeners();
  }

  ScheduleItem? getItemById(String id) {
    return _items.firstWhereOrNull((item) => item.id == id);
  }

  Future<void> addItem(ScheduleItem item) async {
    await _database.insertScheduleItem(item);
    await loadItems();
  }

  Future<void> updateItem(ScheduleItem updatedItem) async {
    await _database.updateScheduleItem(updatedItem);
    await loadItems();
  }

  Future<void> removeItem(String id) async {
    await _database.deleteScheduleItem(id);
    await loadItems();
  }

  List<ScheduleItem> getItemsForDay(int dayOfWeek) {
    return _items
        .where((item) => item.dayOfWeek == dayOfWeek && item.isRoutine)
        .toList();
  }

  List<ScheduleItem> getItemsForDate(DateTime date) {
    final String dateString = date.toIso8601String().substring(0, 10);
    return _items.where((item) {
      if (!item.isRoutine) {
        return item.selectedDate?.toIso8601String().substring(0, 10) ==
            dateString;
      } else {
        return item.dayOfWeek == date.weekday;
      }
    }).toList();
  }

  List<ScheduleItem> getRoutineItems() {
    return _items.where((item) => item.isRoutine).toList();
  }

  List<ScheduleItem> getUserItems() {
    return _items.where((item) => !item.isRoutine).toList();
  }
}
