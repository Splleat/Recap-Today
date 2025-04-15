import 'package:flutter/material.dart';
import 'package:recap_today/widget/background.dart';
import 'package:recap_today/widget/planner/timetable.dart';
import 'package:recap_today/widget/planner/timetable_widget.dart';
import 'package:recap_today/widget/planner/schedule_add.dart';

class TimetableScreen extends StatelessWidget {
  const TimetableScreen({super.key});

  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text('시간표'),
        centerTitle: true,
        actions: <Widget> [
          IconButton(
            icon: Icon(Icons.add),
            tooltip: '일정 추가',
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                builder: (BuildContext context) {
                  return Padding(
                    padding: MediaQuery.of(context).viewInsets,
                    child: ScheduleAddForm(
                      isRoutineContext: true,
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
      body: Container(
        decoration: commonTabDecoration(),
        child: TimetableWidget(),
      ),
    );
  }
}