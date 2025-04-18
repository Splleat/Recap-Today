import 'package:flutter/material.dart';
import 'package:recap_today/model/schedule_item.dart';
import 'package:recap_today/utils/time_utils.dart';
import 'package:recap_today/provider/schedule_provider.dart';
import 'package:provider/provider.dart';

List<String> week = ['일', '월', '화', '수', '목', '금', '토'];
const int kColumnLength = 48;
const double kFirstColumnHeight = 20;
const double kBoxSize = 60;

Widget buildTimeColumn() {
  return Expanded(
      child:Column(
        children: [
          SizedBox(
            height: kFirstColumnHeight,
          ),
          ...List.generate(
            kColumnLength.toInt(),
                (index) {
              if (index % 2 == 0) {
                return const Divider(
                  color: Colors.grey,
                  height: 0,
                );
              }
              return SizedBox(
                height: kBoxSize,
                child: Center(child: Text('${index ~/ 2}')),
              );
            },
          ),
        ],
      )
  );
}

List<Widget> buildDayColumn(int index, List<ScheduleItem> items) {
  return [
    const VerticalDivider(
      color: Colors.grey,
      width: 0,
    ),
    Expanded(
      flex: 4,
      child: Stack(
        children: [
          Column(
            children: [
              SizedBox(
                height: kFirstColumnHeight,
                child: Text(
                  '${week[index]}',
                ),
              ),
              ...List.generate(
                kColumnLength,
                    (index) {
                  if (index % 2 == 0) {
                    return const Divider(
                      color: Colors.grey,
                      height: 0,
                    );
                  }
                  return SizedBox(
                    height: kBoxSize,
                    child: Container(),
                  );
                },
              ),
            ],
          ),
          ...items.map((item) {
            final double top = timeOfDayToMinutes(item.startTime).toDouble() + kFirstColumnHeight;
            final double height = scheduleDuration(item.startTime, item.endTime).toDouble();
            if (height <= 0) {
              return SizedBox.shrink();
            }

            return Positioned(
              top: top,
              left: 2.0,
              right: 2.0,
              height: height,
              child: TimetableScheduleBlock(item: item),
            );
          }).toList(),
        ],
      ),
    ),
  ];
}

class TimetableScheduleBlock extends StatelessWidget {
  final ScheduleItem item;

  void _showOptionsDialog(BuildContext context, ScheduleItem item) {
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(item.text),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start ,
            children: [
              item.isRoutine ? Text('루틴 일정') : Text('사용자 일정'),
              Text((item.subText?.isNotEmpty ?? false) ? item.subText! : '세부 내용 없음'),
              Text('${item.startTime.format(context)} - ${item.endTime.format(context)}'),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: Text('수정'),
              onPressed: () {
                // 수정 기능 구현
              }
            ),
            TextButton(
              child: Text('삭제', style: TextStyle(color: Colors.red)),
              onPressed: () {
                try {
                  context.read<ScheduleProvider>().removeItem(item.id);
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('일정 삭제 중 오류가 발생했습니다: $e')),
                  );
                }
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  const TimetableScheduleBlock ({
    Key? key,
    required this.item,
  }) : super(key: key);
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        _showOptionsDialog(context, item);
      },
      child: Container(
        decoration: BoxDecoration(
          color: item.color,
        ),
        alignment: Alignment.center,
        child: Text(item.text, textAlign: TextAlign.start,),
      ),
    );
  }
}