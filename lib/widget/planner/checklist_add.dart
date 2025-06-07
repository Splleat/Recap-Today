import 'package:flutter/material.dart';
import 'package:recap_today/model/freezed/checklist_item.dart';
import 'package:recap_today/provider/checklist_provider.dart';
import 'package:recap_today/provider/login_provider.dart'; // 추가
import 'package:provider/provider.dart'; // 추가
import 'package:intl/intl.dart';

void showAddItemDialog(BuildContext context, ChecklistProvider checklistProvider) {
  TextEditingController titleController = TextEditingController();
  TextEditingController descriptionController = TextEditingController();
  DateTime? selectedDueDate;

  showDialog(
    context: context,
    builder: (BuildContext context) {
      // LoginProvider에서 사용자 ID 가져오기
      final loginProvider = Provider.of<LoginProvider>(context, listen: false);
      final userId = loginProvider.activeUserId;

      return AlertDialog(
        title: const Text('할 일 추가'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: '제목'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(labelText: '설명 (선택 사항)'),
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
              if (titleController.text.isNotEmpty) {
                final newItem = ChecklistItem(
                  id: UniqueKey().toString(),
                  userId: userId, // LoginProvider에서 가져온 ID 사용
                  text: titleController.text, // 제목
                  subtext: descriptionController.text.isNotEmpty
                      ? descriptionController.text
                      : null, // 설명
                  dueDate: selectedDueDate,
                );
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