import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Added import for DateFormat
import 'package:provider/provider.dart';
import 'package:recap_today/model/emotion_model.dart';
import 'package:recap_today/repository/abstract_emotion_repository.dart';
import 'package:recap_today/widget/home/hourly_emotion_logger.dart'; // Added

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

  // Define a mapping for emotions to numerical values for the graph
  // And a color for each emotion type
  static const Map<String, ({double value, Color color})> _emotionConfig = {
    "행복": (value: 5.0, color: Colors.greenAccent),
    "놀람": (value: 4.0, color: Colors.blueAccent),
    "보통": (value: 3.0, color: Colors.grey),
    "피곤": (value: 2.0, color: Colors.orangeAccent),
    "슬픔": (value: 1.0, color: Colors.lightBlue),
    "화남": (value: 0.0, color: Colors.redAccent),
  };

  @override
  void initState() {
    super.initState();
    _emotionRepository = Provider.of<AbstractEmotionRepository>(
      context,
      listen: false,
    );
    _loadEmotionData();
  }

  @override
  void didUpdateWidget(covariant EmotionSummaryGraph oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.date != oldWidget.date) {
      _loadEmotionData();
    }
  }

  Future<void> _loadEmotionData() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final String dateString = DateFormat(
        'yyyy-MM-dd',
      ).format(widget.date); // Format DateTime to String
      final records = await _emotionRepository.getEmotionRecordsForDay(
        dateString,
      ); // Use formatted string

      if (mounted) {
        setState(() {
          _emotionRecords = records; // For the graph
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      // Handle error appropriately, maybe show a message
      print("Error loading emotion data for graph: $e");
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('감정 데이터 로딩 오류: $e')));
      }
    }
  }

  LineChartData _buildChartData() {
    List<FlSpot> spots = [];
    List<Color> gradientColors = [];

    // Sort records by time to ensure the line chart connects points chronologically
    _emotionRecords.sort(
      (a, b) => a.hour.compareTo(b.hour),
    ); // Changed from a.timestamp

    if (_emotionRecords.isEmpty) {
      // Create a default spot if no data, to avoid empty chart errors
      // This could be a flat line at a neutral value, or just an empty list
      // For now, let's show a flat line at "보통" if no data
      spots.add(FlSpot(0, _emotionConfig["보통"]!.value));
      spots.add(FlSpot(23, _emotionConfig["보통"]!.value));
      gradientColors.add(_emotionConfig["보통"]!.color);
      gradientColors.add(_emotionConfig["보통"]!.color);
    } else {
      for (var record in _emotionRecords) {
        final config = _emotionConfig[record.emotionType];
        if (config != null) {
          spots.add(
            FlSpot(record.hour.toDouble(), config.value),
          ); // Changed from record.timestamp.hour
          gradientColors.add(config.color);
        }
      }
      // If only one spot, duplicate it to draw a line
      if (spots.length == 1) {
        spots.add(
          FlSpot(
            spots.first.x + 1 > 23 ? 23 : spots.first.x + 1,
            spots.first.y,
          ),
        ); // Add a point one hour later or at 23h
        gradientColors.add(gradientColors.first); // Use the same color
      }
    }

    // Ensure gradientColors has at least two colors if spots exist
    if (spots.isNotEmpty && gradientColors.length == 1) {
      gradientColors.add(gradientColors.first); // Duplicate the color
    }
    if (gradientColors.isEmpty && spots.isNotEmpty) {
      // Default gradient if somehow colors weren't added but spots exist
      gradientColors.addAll([
        Theme.of(context).primaryColor,
        Theme.of(context).colorScheme.secondary,
      ]);
    }
    if (gradientColors.isEmpty && spots.isEmpty) {
      // Default gradient if somehow colors weren't added and spots are empty
      gradientColors.addAll([
        _emotionConfig["보통"]!.color,
        _emotionConfig["보통"]!.color,
      ]);
    }

    return LineChartData(
      gridData: FlGridData(
        show: true,
        drawVerticalLine: true,
        horizontalInterval: 1,
        verticalInterval: 1,
        getDrawingHorizontalLine: (value) {
          return const FlLine(color: Colors.black12, strokeWidth: 0.5);
        },
        getDrawingVerticalLine: (value) {
          return const FlLine(color: Colors.black12, strokeWidth: 0.5);
        },
      ),
      titlesData: FlTitlesData(
        show: true,
        rightTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 30,
            interval: 4, // Show every 4 hours
            getTitlesWidget: (double value, TitleMeta meta) {
              final hour = value.toInt();
              if (hour % 4 == 0 && hour <= 23) {
                return SideTitleWidget(
                  axisSide: meta.axisSide,
                  space: 8.0,
                  child: Text(
                    '${hour.toString().padLeft(2, '0')}:00',
                    style: const TextStyle(fontSize: 10),
                  ),
                );
              }
              return Container();
            },
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            interval: 1,
            getTitlesWidget: (double value, TitleMeta meta) {
              // Find emotion corresponding to the value
              String emotionText = '';
              _emotionConfig.forEach((key, val) {
                if (val.value == value) {
                  emotionText = key;
                }
              });
              if (emotionText.isNotEmpty) {
                return Text(
                  emotionText,
                  style: const TextStyle(fontSize: 10),
                  textAlign: TextAlign.left,
                );
              }
              return Container();
            },
            reservedSize: 42,
          ),
        ),
      ),
      borderData: FlBorderData(
        show: true,
        border: Border.all(color: Colors.black26, width: 1),
      ),
      minX: 0,
      maxX: 23, // 24 hours
      minY: -0.5, // Min emotion value (e.g., 화남)
      maxY: 5.5, // Max emotion value (e.g., 행복)
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: true,
          gradient: LinearGradient(
            colors:
                gradientColors.length < 2
                    ? [_emotionConfig["보통"]!.color, _emotionConfig["보통"]!.color]
                    : gradientColors,
          ),
          barWidth: 3,
          isStrokeCapRound: true,
          dotData: const FlDotData(show: true),
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              colors:
                  gradientColors.length < 2
                      ? [
                        _emotionConfig["보통"]!.color.withOpacity(0.3),
                        _emotionConfig["보통"]!.color.withOpacity(0.3),
                      ]
                      : gradientColors
                          .map((color) => color.withOpacity(0.3))
                          .toList(),
            ),
          ),
        ),
      ],
      lineTouchData: LineTouchData(
        touchTooltipData: LineTouchTooltipData(
          getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
            return touchedBarSpots.map((barSpot) {
              final flSpot = barSpot.bar.spots[barSpot.spotIndex];
              String emotionText = '';
              Color emotionColor = Colors.transparent;

              _emotionConfig.forEach((key, val) {
                if (val.value == flSpot.y) {
                  emotionText = key;
                  emotionColor = val.color;
                }
              });

              // Find the original record for notes if available
              EmotionRecord? touchedRecord;
              for (var record in _emotionRecords) {
                if (record.hour == flSpot.x.toInt() &&
                    _emotionConfig[record.emotionType]?.value == flSpot.y) {
                  // Changed from record.timestamp.hour
                  touchedRecord = record;
                  break;
                }
              }

              String tooltipText =
                  '${flSpot.x.toInt().toString().padLeft(2, '0')}:00\\n$emotionText';
              if (touchedRecord?.notes != null &&
                  touchedRecord!.notes!.isNotEmpty) {
                tooltipText += '\n(${touchedRecord.notes})';
              }

              return LineTooltipItem(
                tooltipText,
                TextStyle(color: emotionColor, fontWeight: FontWeight.bold),
              );
            }).toList();
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16.0, top: 16.0, bottom: 8.0),
          child: Text(
            '오늘의 감정 변화', // Graph Title
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.black, // Added color black
            ),
          ),
        ),
        if (_emotionRecords.isEmpty)
          Container(
            height: 200,
            padding: const EdgeInsets.all(16.0),
            alignment: Alignment.center,
            child: const Text(
              '오늘 기록된 감정이 없습니다.', // Updated message - timeline reference removed
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          )
        else
          AspectRatio(
            aspectRatio: 1.70,
            child: Padding(
              padding: const EdgeInsets.only(
                right: 28.0,
                left: 16.0,
                top: 16.0,
                bottom: 12.0,
              ),
              child: LineChart(_buildChartData()),
            ),
          ),
        const Divider(), // Added Divider
        ExpansionTile(
          title: Text(
            '시간별 감정 기록 보기',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.black54,
            ),
          ),
          children: <Widget>[
            SizedBox(
              height: 300, // Adjust height as needed, or make it more dynamic
              child: HourlyEmotionTimelineDrawer(date: widget.date),
            ),
          ],
        ),
      ],
    );
  }
}
