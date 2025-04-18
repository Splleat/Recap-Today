import 'package:flutter/material.dart';

class ChecklistItem {
  final String id;
  String text;
  String? subtext;
  bool isChecked;
  DateTime? dueDate;

  ChecklistItem({
    required this.id,
    required this.text,
    this.isChecked = false,
    this.dueDate,
    this.subtext,
  });

  ChecklistItem copyWith({
    String? id,
    String? text,
    bool? isChecked,
    DateTime? dueDate,
    String? subtext,
  }) {
    return ChecklistItem(
      id: id ?? this.id,
      text: text ?? this.text,
      subtext: subtext ?? this.subtext,
      isChecked: isChecked ?? this.isChecked,
      dueDate: dueDate ?? this.dueDate,
    );
  }
}
