import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:recap_today/provider/checklist_provider.dart';
import 'package:recap_today/widget/planner/checklist_widget.dart';
import 'package:recap_today/widget/planner/checklist_add.dart';

class ChecklistScreen extends StatelessWidget {
  const ChecklistScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final checklistProvider = Provider.of<ChecklistProvider>(context);

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withOpacity(0.8),
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'TODO',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
              ),
              FloatingActionButton(
                mini: true,
                elevation: 0,
                onPressed: () {
                  showAddItemDialog(context, checklistProvider);
                },
                child: const Icon(Icons.add),
              ),
            ],
          ),
          Expanded(
            child: ListView.builder(
              itemCount: checklistProvider.items.length,
              itemBuilder: (context, index) {
                final item = checklistProvider.items[index];
                return ChecklistItemWidget(
                  item: item,
                  onCheckboxChanged: (itemId, newValue) async {
                    try {
                      await checklistProvider.updateItem(
                        id: itemId,
                        isChecked: newValue,
                      );
                    } catch (e) {
                      debugPrint('항목 업데이트 중 오류: $e');
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('항목 업데이트 실패'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                  onDelete: (itemId) async {
                    try {
                      await checklistProvider.removeItem(itemId);
                    } catch (e) {
                      debugPrint('항목 삭제 중 오류: $e');
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('항목 삭제 실패'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}