import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:recap_today/model/checklist_item.dart';
import 'package:recap_today/provider/checklist_provider.dart';

class ChecklistAchievement extends StatelessWidget {
  final DateTime? date; // Add date parameter
  const ChecklistAchievement({super.key, this.date}); // Update constructor

  @override
  Widget build(BuildContext context) {
    return Consumer<ChecklistProvider>(
      builder: (context, provider, child) {
        final targetDate = date ?? DateTime.now();
        // Get completed items for the targetDate
        final completedItems = provider.getCompletedItemsForDate(targetDate);

        // Determine if the targetDate is today for display purposes
        final now = DateTime.now();
        final isToday =
            targetDate.year == now.year &&
            targetDate.month == now.month &&
            targetDate.day == now.day;
        final displayDateString =
            isToday ? '오늘' : DateFormat('M월 d일').format(targetDate);

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12.0),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 8.0,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Left side - Large number showing count of completed items
                  Expanded(
                    flex: 2,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '${completedItems.length}',
                            style: const TextStyle(
                              fontSize: 80,
                              fontWeight: FontWeight.bold,
                              height: 1.0,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$displayDateString 완료', // Updated text
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Divider
                  Container(
                    width: 1,
                    height: 140,
                    color: Colors.grey.withOpacity(0.3),
                    margin: const EdgeInsets.symmetric(horizontal: 16.0),
                  ),

                  // Right side - Scrollable list of completed items
                  Expanded(
                    flex: 3,
                    child:
                        completedItems.isEmpty
                            ? Center(
                              child: Text(
                                '$displayDateString 완료된 항목이 없습니다.', // Updated text
                                style: TextStyle(color: Colors.grey),
                                textAlign: TextAlign.center,
                              ),
                            )
                            : SizedBox(
                              height: 150,
                              child: ListView.builder(
                                physics: const BouncingScrollPhysics(),
                                padding: EdgeInsets.zero,
                                itemCount: completedItems.length,
                                itemBuilder: (context, index) {
                                  final item = completedItems[index];
                                  return CompletedChecklistItem(item: item);
                                },
                              ),
                            ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }
}

class CompletedChecklistItem extends StatelessWidget {
  final ChecklistItem item;

  const CompletedChecklistItem({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    // 최적화: 완료 시간 포맷팅을 미리 계산
    final completedTimeText =
        item.completedDate != null
            ? '${DateFormat('HH:mm').format(item.completedDate!)}에 완료'
            : '';

    return Container(
      margin: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 2.0),
            child: Icon(Icons.check_circle, color: Colors.green, size: 18),
          ),
          const SizedBox(width: 8.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.text,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    decoration: TextDecoration.lineThrough,
                    decorationColor: Colors.black38,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                if (item.subtext != null && item.subtext!.isNotEmpty)
                  Text(
                    item.subtext!,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                      decoration: TextDecoration.lineThrough,
                      decorationColor: Colors.grey,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                if (completedTimeText.isNotEmpty)
                  Text(
                    completedTimeText,
                    style: const TextStyle(fontSize: 10, color: Colors.grey),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
