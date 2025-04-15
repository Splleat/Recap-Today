import 'package:flutter/material.dart';
import 'package:recap_today/model/checklist_item.dart'; // CheckList 모델 임포트
import 'package:intl/intl.dart';

class ChecklistItemWidget extends StatelessWidget {
  final ChecklistItem item;
  final Function(String, bool) onCheckboxChanged;
  final Function(String) onDelete;

  const ChecklistItemWidget({
    super.key,
    required this.item,
    required this.onCheckboxChanged,
    required this.onDelete,
  });

  Duration? _getRemainingTime(DateTime? dueDate) {
    if (dueDate == null) {
      return null;
    }
    final now = DateTime.now();
    final difference = dueDate.difference(now);
    return difference.inMilliseconds > 0 ? difference : Duration.zero;
  }

  String _formatRemainingTime(Duration? remaining) {
    if (remaining == null) {
      return '';
    }
    if (remaining.inDays > 0) {
      return '${remaining.inDays}일';
    } else if (remaining.inHours > 0) {
      return '${remaining.inHours}시간';
    } else if (remaining.inMinutes > 0) {
      return '${remaining.inMinutes}분';
    } else if (remaining.inSeconds >= 0) {
      return '곧 마감';
    } else {
      return '기한 지남';
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      key: ValueKey(item.id),
      leading: Checkbox(
        value: item.isChecked,
        onChanged: (newValue) {
          if (newValue != null) {
            onCheckboxChanged(item.id, newValue);
          }
        },
      ),
      title: Text(item.text),
      subtitle: item.subtext != null ? Text(item.subtext!) : null,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (item.dueDate != null)
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _formatRemainingTime(_getRemainingTime(item.dueDate)),
                  style: TextStyle(
                    color: _getRemainingTime(item.dueDate)?.inMilliseconds.isNegative ?? false
                        ? Colors.red
                        : Colors.grey,
                  ),
                ),
                Text(
                  DateFormat('yyyy-MM-dd HH:mm').format(item.dueDate!),
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () {
              onDelete(item.id);
            },
          ),
        ],
      ),
      onTap: () {
        onCheckboxChanged(item.id, !item.isChecked);
      },
    );
  }
}