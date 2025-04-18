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

    return Scaffold(
      appBar: AppBar(
        title: const Text('TODO'),
      ),
      body: ListView.builder(
        itemCount: checklistProvider.items.length,
        itemBuilder: (context, index) {
          final item = checklistProvider.items[index];
          return ChecklistItemWidget(
            item: item,
            onCheckboxChanged: (itemId, newValue) {
              checklistProvider.toggleItem(itemId, newValue);
            },
            onDelete: (itemId) {
              checklistProvider.removeItem(itemId);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showAddItemDialog(context, checklistProvider);
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}