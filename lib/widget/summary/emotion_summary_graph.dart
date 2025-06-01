import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:recap_today/model/emotion_model.dart';
import 'package:recap_today/repository/abstract_emotion_repository.dart';
import 'package:recap_today/widget/home/hourly_emotion_logger.dart';

class EmotionSummaryGraph extends StatefulWidget {
  final DateTime date;
  const EmotionSummaryGraph({super.key, required this.date});
  @override
  State<EmotionSummaryGraph> createState() => _EmotionSummaryGraphState();
}

class _EmotionSummaryGraphState extends State<EmotionSummaryGraph> {
  late AbstractEmotionRepository _emotionRepository;
  List<EmotionRecord> _emotionRecords = [];
  bool _isLoading = true;

  static const Map<String, ({double value, Color color})> _emotionConfig = {
    "매우 좋음": (value: 4.0, color: Colors.greenAccent),
    "좋음": (value: 3.0, color: Colors.blueAccent),
    "보통": (value: 2.0, color: Colors.grey),
    "나쁨": (value: 1.0, color: Colors.orangeAccent),
    "매우 나쁨": (value: 0.0, color: Colors.redAccent),
  };

  @override
  void initState() {
    super.initState();
    _emotionRepository = Provider.of<AbstractEmotionRepository>(context, listen: false);
    _loadEmotionData();
  }

  @override
  void didUpdateWidget(covariant EmotionSummaryGraph oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.date != oldWidget.date) _loadEmotionData();
  }

  Future<void> _loadEmotionData() async {
    setState(() => _isLoading = true);
    try {
      final dateString = DateFormat('yyyy-MM-dd').format(widget.date);
      final records = await _emotionRepository.getEmotionRecordsForDay(dateString);
      if (mounted) setState(() { _emotionRecords = records; _isLoading = false; });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('감정 데이터 로딩 오류: $e')));
      }
      debugPrint("감정 그래프 데이터 로드 중 오류: $e");
    }
  }

  LineChartData _buildChartData() {
    List<FlSpot> spots = [];
    List<Color> gradientColors = [];
    _emotionRecords.sort((a, b) => a.hour.compareTo(b.hour));
    if (_emotionRecords.isEmpty) {
      spots.addAll([FlSpot(0, _emotionConfig["보통"]!.value), FlSpot(23, _emotionConfig["보통"]!.value)]);
      gradientColors.addAll([_emotionConfig["보통"]!.color, _emotionConfig["보통"]!.color]);
    } else {
      for (var record in _emotionRecords) {
        final config = _emotionConfig[record.emotionType];
        if (config != null) {
          spots.add(FlSpot(record.hour.toDouble(), config.value));
          gradientColors.add(config.color);
        }
      }
      if (spots.length == 1) {
        spots.add(FlSpot(spots.first.x + 1 > 23 ? 23 : spots.first.x + 1, spots.first.y));
        gradientColors.add(gradientColors.first);
      }
    }
    while (gradientColors.length < spots.length) {
      gradientColors.add(gradientColors.isNotEmpty ? gradientColors.last : Colors.grey);
    }
    if (spots.isNotEmpty && gradientColors.length == 1) gradientColors.add(gradientColors.first);
    if (gradientColors.isEmpty && spots.isNotEmpty) gradientColors.addAll([Theme.of(context).primaryColor, Theme.of(context).colorScheme.secondary]);
    if (gradientColors.isEmpty && spots.isEmpty) gradientColors.addAll([_emotionConfig["보통"]!.color, _emotionConfig["보통"]!.color]);

    return LineChartData(
      gridData: FlGridData(show: false),
      titlesData: FlTitlesData(
        show: true,
        rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 30,
            interval: 4,
            getTitlesWidget: (double value, TitleMeta meta) {
              final hour = value.toInt();
              if (hour % 4 == 0 && hour <= 23) {
                return SideTitleWidget(
                  meta: meta,
                  space: 8.0,
                  child: Text('${hour.toString().padLeft(2, '0')}:00', style: const TextStyle(fontSize: 10)),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            interval: 1,
            getTitlesWidget: (double value, TitleMeta meta) {
              IconData? icon;
              Color? iconColor;
              _emotionConfig.forEach((key, val) {
                if (val.value == value && emotionDetailsConfig.containsKey(key)) {
                  icon = emotionDetailsConfig[key]?.icon;
                  iconColor = val.color;
                }
              });
              if (icon != null) {
                return Icon(icon, color: iconColor ?? Colors.grey, size: 22);
              }
              return const SizedBox.shrink();
            },
            reservedSize: 42,
          ),
        ),
      ),
      borderData: FlBorderData(
        show: true,
        border: Border.all(
          color: Theme.of(context).brightness == Brightness.dark ? Colors.white38 : Colors.black26,
          width: 1,
        ),
      ),
      minX: 0,
      maxX: 23,
      minY: 0.0,
      maxY: 4.0,
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: true,
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.white
              : Colors.black,
          barWidth: 1.5,
          isStrokeCapRound: true,
          dotData: FlDotData(
            show: true,
            getDotPainter: (spot, percent, barData, index) {
              Color dotColor = Colors.grey;
              if (index != null && index < gradientColors.length) dotColor = gradientColors[index];
              return FlDotCirclePainter(
                radius: 7,
                color: dotColor,
                strokeWidth: 0,
                strokeColor: Colors.transparent, // ← 혹시 몰라서 투명색
              );
            },
          ),
          belowBarData: BarAreaData(
            show: true,
            color: (Theme.of(context).brightness == Brightness.dark
                ? Colors.white
                : Colors.black).withOpacity(0.1),
          ),
        ),
      ],
      lineTouchData: LineTouchData(
        touchTooltipData: LineTouchTooltipData(
          getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
            return touchedBarSpots.map((barSpot) {
              final flSpot = barSpot;
              String emotionText = '';
              _emotionConfig.forEach((key, val) {
                if (val.value == flSpot.y) {
                  emotionText = key;
                }
              });
              if (emotionText.isEmpty) emotionText = '기록 없음';
              EmotionRecord? touchedRecord;
              for (var record in _emotionRecords) {
                if (record.hour == flSpot.x.toInt() && _emotionConfig[record.emotionType]?.value == flSpot.y) {
                  touchedRecord = record;
                  break;
                }
              }
              String tooltipText = '${flSpot.x.toInt().toString().padLeft(2, '0')}:00\n$emotionText';
              if (touchedRecord?.notes != null && touchedRecord!.notes!.isNotEmpty) {
                tooltipText += '\n${touchedRecord.notes}';
              }
              return LineTooltipItem(
                tooltipText,
                TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  height: 1.5,
                ),
                children: [
                  TextSpan(
                    text: '\n',
                    style: const TextStyle(fontSize: 2),
                  ),
                ],
              );
            }).toList();
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    String formattedDate = DateFormat('yyyy년 M월 d일').format(widget.date);
    bool isToday = widget.date.year == DateTime.now().year &&
        widget.date.month == DateTime.now().month &&
        widget.date.day == DateTime.now().day;
    String title = isToday ? '오늘의 감정 변화' : '$formattedDate 감정 변화';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16.0, top: 16.0, bottom: 8.0),
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
        if (_emotionRecords.isEmpty)
          Container(
            height: 200,
            padding: const EdgeInsets.all(16.0),
            alignment: Alignment.center,
            child: const Text(
              '오늘 기록된 감정이 없습니다.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
          )
        else
          AspectRatio(
            aspectRatio: 1.70,
            child: Padding(
              padding: const EdgeInsets.only(right: 28.0, left: 16.0, top: 16.0, bottom: 12.0),
              child: LineChart(_buildChartData()),
            ),
          ),
        const Divider(),
        ExpansionTile(
          title: Text(
            '시간별 감정 기록 보기',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          children: <Widget>[
            SizedBox(
              height: 300,
              child: HourlyEmotionTimelineDrawer(date: widget.date),
            ),
          ],
        ),
      ],
    );
  }
}
