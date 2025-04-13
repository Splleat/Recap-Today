import 'package:flutter/material.dart';

class CheckList {
  final String id;
  String text;
  String? subtext;
  bool isChecked;
  DateTime? dueDate;

  CheckList({
    required this.id,
    required this.text,
    this.isChecked = false,
    this.dueDate,
    this.subtext,
  });

  CheckList copyWith({
    String? id,
    String? text,
    bool? isChecked,
    DateTime? dueDate,
    String? subtext,
  }) {
    return CheckList(
      id: id ?? this.id,
      text: text ?? this.text,
      isChecked: isChecked ?? this.isChecked,
      dueDate: dueDate ?? this.dueDate,
      subtext: subtext ?? this.subtext,
    );
  }
}