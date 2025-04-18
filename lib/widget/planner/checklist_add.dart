import 'package:flutter/material.dart';
import 'package:recap_today/model/checklist_item.dart';
import 'package:recap_today/provider/checklist_provider.dart';
import 'package:intl/intl.dart';

void showAddItemDialog(BuildContext context, ChecklistProvider checklistProvider) {
  TextEditingController textController = TextEditingController();
  DateTime? selectedDueDate;

  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text('할 일 추가'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: textController,
              decoration: const InputDecoration(labelText: '내용'),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(selectedDueDate == null
                    ? '마감일 선택 (선택 사항)'
                    : '마감일: ${DateFormat('yyyy-MM-dd HH:mm').format(selectedDueDate!)}'),
                TextButton(
                  onPressed: () async {
                    final DateTime? pickedDate = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime.now(),
                      lastDate: DateTime(2100),
                    );
                    if (pickedDate != null) {
                      final TimeOfDay? pickedTime = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.now(),
                      );
                      if (pickedTime != null) {
                        selectedDueDate = DateTime(
                          pickedDate.year,
                          pickedDate.month,
                          pickedDate.day,
                          pickedTime.hour,
                          pickedTime.minute,
                        );
                      }
                    }
                  },
                  child: const Text('선택'),
                ),
              ],
            ),
          ],
        ),
        actions: <Widget>[
          TextButton(
            child: const Text('취소'),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
          ElevatedButton(
            child: const Text('추가'),
            onPressed: () {
              if (textController.text.isNotEmpty) {
                final newItem = ChecklistItem(id: UniqueKey().toString(), text: textController.text, dueDate: selectedDueDate);
                checklistProvider.addItem(newItem);
                Navigator.of(context).pop();
              }
            },
          ),
        ],
      );
    },
  );
}