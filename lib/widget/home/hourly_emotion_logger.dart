import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:recap_today/model/emotion_model.dart';
import 'package:recap_today/repository/abstract_emotion_repository.dart';
import 'package:intl/intl.dart'; // For date formatting

// Define a mapping for emotions to numerical values, colors, and icons
const Map<String, ({double value, Color color, IconData icon})>
emotionDetailsConfig = {
  "행복": (
    value: 5.0,
    color: Colors.greenAccent,
    icon: Icons.sentiment_very_satisfied,
  ),
  "놀람": (
    value: 4.0,
    color: Colors.blueAccent,
    icon: Icons.sentiment_satisfied_alt,
  ),
  "보통": (value: 3.0, color: Colors.grey, icon: Icons.sentiment_neutral),
  "피곤": (
    value: 2.0,
    color: Colors.orangeAccent,
    icon: Icons.sentiment_dissatisfied,
  ),
  "슬픔": (
    value: 1.0,
    color: Colors.lightBlue,
    icon: Icons.sentiment_very_dissatisfied,
  ),
  "화남": (value: 0.0, color: Colors.redAccent, icon: Icons.mood_bad),
};

class HourlyEmotionLogger extends StatefulWidget {
  final DateTime initialDate;

  const HourlyEmotionLogger({super.key, required this.initialDate});

  @override
  State<HourlyEmotionLogger> createState() => _HourlyEmotionLoggerState();
}

class _HourlyEmotionLoggerState extends State<HourlyEmotionLogger> {
  late AbstractEmotionRepository _emotionRepository;
  late PageController _pageController;
  late DateTime _selectedDate;
  Map<int, EmotionRecord?> _hourlyEmotions = {};
  bool _isLoading = true;
  int _currentHour = DateTime.now().hour;

  final List<String> _emotionTypes = emotionDetailsConfig.keys.toList();

  @override
  void initState() {
    super.initState();
    _emotionRepository = Provider.of<AbstractEmotionRepository>(
      context,
      listen: false,
    );
    _selectedDate = widget.initialDate;
    _currentHour = DateTime.now().hour;
    _pageController = PageController(
      initialPage: _currentHour,
      viewportFraction: 0.3,
    );
    _loadEmotionData();
  }

  @override
  void didUpdateWidget(covariant HourlyEmotionLogger oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialDate.year != oldWidget.initialDate.year ||
        widget.initialDate.month != oldWidget.initialDate.month ||
        widget.initialDate.day != oldWidget.initialDate.day) {
      _selectedDate = widget.initialDate;
      _currentHour =
          DateTime.now().day == _selectedDate.day &&
                  DateTime.now().month == _selectedDate.month &&
                  DateTime.now().year == _selectedDate.year
              ? DateTime.now().hour
              : 0;
      if (_pageController.hasClients) {
        _pageController.jumpToPage(_currentHour);
      }
      _loadEmotionData();
    }
  }

  Future<void> _loadEmotionData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _hourlyEmotions.clear();
    });
    try {
      final String dateString = DateFormat('yyyy-MM-dd').format(_selectedDate);
      final records = await _emotionRepository.getEmotionRecordsForDay(
        dateString,
      );
      final Map<int, EmotionRecord?> newHourlyEmotions = {};
      for (int i = 0; i < 24; i++) {
        newHourlyEmotions[i] = null;
      }
      for (var record in records) {
        newHourlyEmotions[record.hour] = record;
      }

      if (mounted) {
        setState(() {
          _hourlyEmotions = newHourlyEmotions;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('시간별 감정 로딩 오류: $e')));
      }
      print("Error loading hourly emotion data: $e");
    }
  }

  Future<void> _showEmotionSelectionDialog(int hour) async {
    final currentRecord = _hourlyEmotions[hour];
    String? selectedEmotion = currentRecord?.emotionType;
    TextEditingController notesController = TextEditingController(
      text: currentRecord?.notes,
    );

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (BuildContext context) {
        String? dialogSelectedEmotion = selectedEmotion;
        return AlertDialog(
          title: Text('${hour.toString().padLeft(2, '0')}:00 감정 기록'),
          scrollable: false,
          content: StatefulBuilder(
            builder: (BuildContext dialogContext, StateSetter setStateDialog) {
              return SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(dialogContext).viewInsets.bottom,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      DropdownButtonFormField<String>(
                        decoration: const InputDecoration(labelText: '감정 선택'),
                        value: dialogSelectedEmotion,
                        items:
                            _emotionTypes.map((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Row(
                                  children: [
                                    Icon(
                                      emotionDetailsConfig[value]!.icon,
                                      color: emotionDetailsConfig[value]!.color,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(value),
                                  ],
                                ),
                              );
                            }).toList(),
                        onChanged: (String? newValue) {
                          setStateDialog(() {
                            dialogSelectedEmotion = newValue;
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: notesController,
                        decoration: const InputDecoration(
                          labelText: '메모 (선택 사항)',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 3,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          actions: <Widget>[
            if (currentRecord != null && currentRecord.id != null)
              TextButton(
                child: const Text('삭제', style: TextStyle(color: Colors.red)),
                onPressed: () {
                  Navigator.of(
                    context,
                  ).pop({'action': 'delete', 'id': currentRecord.id!});
                },
              ),
            TextButton(
              child: const Text('취소'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('저장'),
              onPressed: () {
                if (dialogSelectedEmotion != null) {
                  Navigator.of(context).pop({
                    'action': 'save',
                    'emotionType': dialogSelectedEmotion,
                    'notes': notesController.text,
                  });
                }
              },
            ),
          ],
        );
      },
    );

    if (result != null) {
      final String dateString = DateFormat('yyyy-MM-dd').format(_selectedDate);
      if (result['action'] == 'save') {
        final newRecord = EmotionRecord(
          id: currentRecord?.id,
          date: dateString,
          hour: hour,
          emotionType: result['emotionType']!,
          notes: result['notes']?.isNotEmpty == true ? result['notes'] : null,
        );
        try {
          if (currentRecord?.id != null) {
            await _emotionRepository.updateEmotionRecord(newRecord);
          } else {
            await _emotionRepository.addEmotionRecord(newRecord);
          }
          _loadEmotionData();
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text('감정 저장 중 오류: $e')));
          }
        }
      } else if (result['action'] == 'delete' && result['id'] != null) {
        try {
          await _emotionRepository.deleteEmotionRecord(result['id']! as String);
          _loadEmotionData();
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text('감정 삭제 중 오류: $e')));
          }
        }
      }
    }
  }

  Widget _buildEmotionCard(int hour) {
    final record = _hourlyEmotions[hour];
    final timeFormatted = '${hour.toString().padLeft(2, '0')}:00';
    final emotionDetail =
        record != null ? emotionDetailsConfig[record.emotionType] : null;
    final isCurrentHour = hour == _currentHour;

    return GestureDetector(
      onTap: () => _showEmotionSelectionDialog(hour),
      child: Card(
        elevation: isCurrentHour ? 4.0 : 1.0,
        color:
            isCurrentHour
                ? Theme.of(context).primaryColorLight.withOpacity(0.5)
                : null,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side:
              isCurrentHour
                  ? BorderSide(
                    color: Theme.of(context).primaryColor,
                    width: 1.5,
                  )
                  : BorderSide.none,
        ),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                timeFormatted,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight:
                      isCurrentHour ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              const SizedBox(height: 8),
              Icon(
                emotionDetail?.icon ?? Icons.add_reaction_outlined,
                color: emotionDetail?.color ?? Colors.grey,
                size: 28,
              ),
              const SizedBox(height: 4),
              Text(
                record?.emotionType ?? '기록',
                style: TextStyle(
                  fontSize: 10,
                  color: emotionDetail?.color ?? Colors.grey,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
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
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Text(
            "시간별 감정 기록",
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
        SizedBox(
          height: 100, // Adjust height as needed
          child: PageView.builder(
            controller: _pageController,
            itemCount: 24,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 4.0,
                ), // Spacing between cards
                child: _buildEmotionCard(index),
              );
            },
            onPageChanged: (index) {
              // Optional: handle page change if needed
            },
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}

// Helper widget for the summary screen drawer
class HourlyEmotionTimelineDrawer extends StatefulWidget {
  final DateTime date;
  const HourlyEmotionTimelineDrawer({super.key, required this.date});

  @override
  State<HourlyEmotionTimelineDrawer> createState() =>
      _HourlyEmotionTimelineDrawerState();
}

class _HourlyEmotionTimelineDrawerState
    extends State<HourlyEmotionTimelineDrawer> {
  late AbstractEmotionRepository _emotionRepository;
  Map<int, EmotionRecord?> _hourlyEmotions = {};
  bool _isLoading = true;
  final List<String> _emotionTypes = emotionDetailsConfig.keys.toList();

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
  void didUpdateWidget(covariant HourlyEmotionTimelineDrawer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.date.year != oldWidget.date.year ||
        widget.date.month != oldWidget.date.month ||
        widget.date.day != oldWidget.date.day) {
      _loadEmotionData();
    }
  }

  Future<void> _loadEmotionData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _hourlyEmotions.clear();
    });
    try {
      final String dateString = DateFormat('yyyy-MM-dd').format(widget.date);
      final records = await _emotionRepository.getEmotionRecordsForDay(
        dateString,
      );
      final Map<int, EmotionRecord?> newHourlyEmotions = {};
      for (int i = 0; i < 24; i++) {
        newHourlyEmotions[i] = null;
      }
      for (var record in records) {
        newHourlyEmotions[record.hour] = record;
      }

      if (mounted) {
        setState(() {
          _hourlyEmotions = newHourlyEmotions;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('시간별 감정 로딩 오류 (서랍): $e')));
      }
      print("Error loading hourly emotion data for drawer: $e");
    }
  }

  Future<void> _showEmotionSelectionDialog(int hour) async {
    final currentRecord = _hourlyEmotions[hour];
    String? selectedEmotion = currentRecord?.emotionType;
    TextEditingController notesController = TextEditingController(
      text: currentRecord?.notes,
    );

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (BuildContext context) {
        String? dialogSelectedEmotion = selectedEmotion;
        return AlertDialog(
          title: Text('${hour.toString().padLeft(2, '0')}:00 감정 기록'),
          scrollable: false,
          content: StatefulBuilder(
            builder: (BuildContext dialogContext, StateSetter setStateDialog) {
              return SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(dialogContext).viewInsets.bottom,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      DropdownButtonFormField<String>(
                        decoration: const InputDecoration(labelText: '감정 선택'),
                        value: dialogSelectedEmotion,
                        items:
                            _emotionTypes.map((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Row(
                                  children: [
                                    Icon(
                                      emotionDetailsConfig[value]!.icon,
                                      color: emotionDetailsConfig[value]!.color,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(value),
                                  ],
                                ),
                              );
                            }).toList(),
                        onChanged: (String? newValue) {
                          setStateDialog(() {
                            dialogSelectedEmotion = newValue;
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: notesController,
                        decoration: const InputDecoration(
                          labelText: '메모 (선택 사항)',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 3,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          actions: <Widget>[
            if (currentRecord != null && currentRecord.id != null)
              TextButton(
                child: const Text('삭제', style: TextStyle(color: Colors.red)),
                onPressed: () {
                  Navigator.of(
                    context,
                  ).pop({'action': 'delete', 'id': currentRecord.id!});
                },
              ),
            TextButton(
              child: const Text('취소'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('저장'),
              onPressed: () {
                if (dialogSelectedEmotion != null) {
                  Navigator.of(context).pop({
                    'action': 'save',
                    'emotionType': dialogSelectedEmotion,
                    'notes': notesController.text,
                  });
                }
              },
            ),
          ],
        );
      },
    );

    if (result != null) {
      final String dateString = DateFormat('yyyy-MM-dd').format(widget.date);
      if (result['action'] == 'save') {
        final newRecord = EmotionRecord(
          id: currentRecord?.id,
          date: dateString,
          hour: hour,
          emotionType: result['emotionType']!,
          notes: result['notes']?.isNotEmpty == true ? result['notes'] : null,
        );
        try {
          if (currentRecord?.id != null) {
            await _emotionRepository.updateEmotionRecord(newRecord);
          } else {
            await _emotionRepository.addEmotionRecord(newRecord);
          }
          _loadEmotionData();
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text('감정 저장 중 오류 (서랍): $e')));
          }
        }
      } else if (result['action'] == 'delete' && result['id'] != null) {
        try {
          await _emotionRepository.deleteEmotionRecord(result['id']! as String);
          _loadEmotionData();
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text('감정 삭제 중 오류 (서랍): $e')));
          }
        }
      }
    }
  }

  Widget _buildHourTileForDrawer(int hour) {
    final record = _hourlyEmotions[hour];
    final timeFormatted = '${hour.toString().padLeft(2, '0')}:00';
    final emotionDetail =
        record != null ? emotionDetailsConfig[record.emotionType] : null;

    return ListTile(
      leading: Icon(
        emotionDetail?.icon ?? Icons.radio_button_unchecked,
        color: emotionDetail?.color ?? Colors.grey,
      ),
      title: Text(timeFormatted),
      subtitle: Text(record?.emotionType ?? '감정 기록 없음'),
      trailing:
          record?.notes != null && record!.notes!.isNotEmpty
              ? const Icon(Icons.notes)
              : null,
      onTap: () => _showEmotionSelectionDialog(hour),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_hourlyEmotions.isEmpty && !_isLoading) {
      return const Center(child: Text("오늘 기록된 감정이 없습니다."));
    }

    return ListView.builder(
      itemCount: 24,
      itemBuilder: (context, index) {
        return _buildHourTileForDrawer(index);
      },
    );
  }
}
