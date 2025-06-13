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
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'TODO',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
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
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
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
          ),
        ],
      ),
    );
  }
}
