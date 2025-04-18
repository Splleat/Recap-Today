import 'package:flutter/material.dart';
import 'package:recap_today/widget/planner/timeline.dart';
import 'package:provider/provider.dart';
import 'package:recap_today/provider/schedule_provider.dart';
import 'package:intl/intl.dart';
import 'package:recap_today/widget/planner/user_schedule_list_widget.dart';
import 'schedule_add.dart';

class DailyTimelineWidget extends StatelessWidget {
  final DateTime date;

  const DailyTimelineWidget({super.key, required this.date});

  Widget build(BuildContext context) {
    final scheduleProvider = context.watch<ScheduleProvider>();
    final allItems = scheduleProvider.items;

    return Scaffold(
      appBar: AppBar(
        title: Text(DateFormat.yMMMEd('ko_KR').format(date)),
      ),
      body: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Container(
              child: DailyTimeline(context, date, allItems),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Container(
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: Colors.white,
                ),
                child: UserScheduleListWidget(date: date),
              )
            )
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: '일정 추가',
        onPressed: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true, // BottomSheet가 키보드 등에 가려지지 않고 높이 조절됨
            builder: (sheetContext) { // BottomSheet 빌더
              // 키보드가 올라올 때 BottomSheet 내용이 가려지지 않도록 Padding 추가
              return Padding(
                padding: MediaQuery.of(sheetContext).viewInsets,
                child: ScheduleAddForm(
                  isRoutineContext: false, // 사용자 일정 추가이므로 false
                  selectedDate: date,     // 현재 타임라인의 날짜 전달
                ),
              );
            },
          );
        },
        child: const Icon(Icons.add), // '+' 아이콘
      ),
    );
  }
}