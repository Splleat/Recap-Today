import 'package:flutter/material.dart';
import 'package:recap_today/provider/checklist_provider.dart';
import 'package:provider/provider.dart';
import 'package:recap_today/widget/background.dart';
import 'package:recap_today/widget/planner/checklist_widget.dart';

class HomeChecklist extends StatelessWidget {
  const HomeChecklist({super.key});

  Widget build(BuildContext context) {
    final checklistProvider = context.watch<ChecklistProvider>();
    final allItems = checklistProvider.items;
    final remainItems = checklistProvider.items.where(
        (item) => !item.isChecked
    ).toList();

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
      ),
      body: Stack(
        children: [
          Container(
            decoration: commonTabDecoration(),
          ),
          SafeArea(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('완료하지 않은 할 일이 \n${remainItems.length}개 있습니다.'),
                  SizedBox(height: 20),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      child:Consumer<ChecklistProvider>(
                        builder: (context, checklistProvider, child) {
                          return ListView.builder(
                            itemCount: allItems.length,
                            itemBuilder: (context, index) {
                              final item = allItems[index];
                              return ChecklistItemWidget(
                                item: item,
                                onCheckboxChanged: (itemId, newValue) {
                                  checklistProvider.toggleItem(itemId, newValue);
                                },
                                onDelete: null,
                              );
                            },
                          );
                        },
                      ),
                    )
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}