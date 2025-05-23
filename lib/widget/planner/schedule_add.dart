import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import 'package:recap_today/model/schedule_item.dart';
import 'package:recap_today/provider/schedule_provider.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';

class ScheduleAddForm extends StatefulWidget {
  final bool isRoutineContext;
  final DateTime? selectedDate;
  final int? dayOfWeek;
  final ScheduleItem? initialItem; // Added for editing

  const ScheduleAddForm({
    Key? key,
    required this.isRoutineContext,
    this.selectedDate,
    this.dayOfWeek,
    this.initialItem, // Added for editing
  }) : super(key: key);

  @override
  _ScheduleAddFormState createState() => _ScheduleAddFormState();
}

class _ScheduleAddFormState extends State<ScheduleAddForm> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _titleController;
  late TextEditingController _subTextController; // Added for subText
  TimeOfDay? _selectedStartTime;
  TimeOfDay? _selectedEndTime;
  late int _selectedDayOfWeek;
  DateTime? _selectedSpecificDate;
  Color _selectedColor = Colors.lightBlueAccent; // Default color
  bool _hasAlarm = false;
  Duration _alarmOffset = const Duration(minutes: 60); // Default alarm offset

  bool get _isEditMode => widget.initialItem != null; // Check if in edit mode

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _subTextController =
        TextEditingController(); // Initialize subText controller

    if (_isEditMode && widget.initialItem != null) {
      // Editing existing item
      final item = widget.initialItem!;
      _titleController.text = item.text;
      _subTextController.text = item.subText ?? '';
      _selectedStartTime = item.startTime;
      _selectedEndTime = item.endTime;
      _selectedColor = item.color ?? Colors.lightBlueAccent;
      _hasAlarm = item.hasAlarm ?? false;
      _alarmOffset = item.alarmOffset ?? const Duration(minutes: 60);

      if (widget.isRoutineContext) {
        _selectedDayOfWeek = item.dayOfWeek ?? (DateTime.now().weekday % 7);
      } else {
        _selectedSpecificDate =
            item.selectedDate ?? widget.selectedDate ?? DateTime.now();
      }
    } else {
      // Adding new item
      _selectedStartTime = TimeOfDay.fromDateTime(
        DateTime.now().add(const Duration(hours: 1)),
      );
      _selectedEndTime = TimeOfDay.fromDateTime(
        DateTime.now().add(const Duration(hours: 2)),
      );
      if (!widget.isRoutineContext) {
        _selectedSpecificDate = widget.selectedDate ?? DateTime.now();
        _selectedDayOfWeek =
            _selectedSpecificDate!.weekday %
            7; // Ensure dayOfWeek is set for non-routine from date
      } else {
        _selectedDayOfWeek = widget.dayOfWeek ?? (DateTime.now().weekday % 7);
      }
      // Set default color for new items if needed, or keep as is.
      // _selectedColor = Colors.lightBlueAccent; // Example default
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _subTextController.dispose(); // Dispose subText controller
    super.dispose();
  }

  Future<void> _pickStartTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedStartTime ?? TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        _selectedStartTime = picked;
      });
    }
  }

  Future<void> _pickEndTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedEndTime ?? TimeOfDay.now(),
    );
    if (picked != null) {
      if (_selectedStartTime != null &&
          _isTimeBefore(picked, _selectedStartTime!)) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('종료 시간은 시작 시간보다 늦어야 합니다.')));
        }
        return;
      }
      setState(() {
        _selectedEndTime = picked;
      });
    }
  }

  Future<void> _pickDate() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedSpecificDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      locale: const Locale('ko', 'KR'),
    );

    if (pickedDate != null) {
      setState(() {
        _selectedSpecificDate = pickedDate;
      });
    }
  }

  bool _isTimeBefore(TimeOfDay time1, TimeOfDay time2) {
    if (time1.hour < time2.hour)
      return true;
    else if (time1.hour >= time2.hour)
      return false;
    return time1.minute < time2.minute;
  }

  void _submitForm() {
    if (_formKey.currentState?.validate() ?? false) {
      _formKey.currentState?.save();

      final startTime = _selectedStartTime;
      final endTime = _selectedEndTime;
      // final date = _selectedSpecificDate; // Not directly used for item creation here

      if (startTime == null || endTime == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('시작 시간과 종료 시간을 모두 선택해주세요.')),
          );
        }
        return;
      }

      if (!widget.isRoutineContext && _selectedSpecificDate == null) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('날짜를 선택해주세요.')));
        }
        return;
      }

      final scheduleData = ScheduleItem(
        id: _isEditMode ? widget.initialItem!.id : const Uuid().v4(),
        text: _titleController.text,
        subText:
            _subTextController.text.isNotEmpty ? _subTextController.text : null,
        dayOfWeek: widget.isRoutineContext ? _selectedDayOfWeek : null,
        selectedDate: widget.isRoutineContext ? null : _selectedSpecificDate,
        isRoutine: widget.isRoutineContext,
        startTime: startTime,
        endTime: endTime,
        color: _selectedColor,
        hasAlarm: _hasAlarm,
        alarmOffset: _hasAlarm ? _alarmOffset : null,
      );

      final scheduleProvider = Provider.of<ScheduleProvider>(
        context,
        listen: false,
      );
      if (_isEditMode) {
        scheduleProvider.updateItem(scheduleData);
      } else {
        scheduleProvider.addItem(scheduleData);
      }

      Navigator.pop(context);
    }
  }

  Widget _buildDayOfWeekSelector() {
    const List<String> weekDays = ['일', '월', '화', '수', '목', '금', '토'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('요일 선택'),
        ToggleButtons(
          isSelected: List.generate(7, (index) => index == _selectedDayOfWeek),
          onPressed: (int index) {
            setState(() {
              _selectedDayOfWeek = index;
            });
          },
          children:
              weekDays
                  .map(
                    (day) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12.0),
                      child: Text(day),
                    ),
                  )
                  .toList(),
        ),
      ],
    );
  }

  Widget _buildDatePickerSelector() {
    final formattedDate =
        _selectedSpecificDate != null
            ? DateFormat.MMMEd('ko_KR').format(_selectedSpecificDate!)
            : '날짜 선택';

    return ListTile(
      leading: Icon(Icons.calendar_today),
      title: Text(formattedDate),
      trailing: Icon(Icons.arrow_drop_down),
      onTap: _pickDate,
    );
  }

  Widget _buildColorPicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('색상 선택'),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8.0,
          runSpacing: 8.0,
          children:
              [
                    Colors.red,
                    Colors.pink,
                    Colors.purple,
                    Colors.deepPurple,
                    Colors.indigo,
                    Colors.blue,
                    Colors.lightBlue,
                    Colors.cyan,
                    Colors.teal,
                    Colors.green,
                    Colors.lightGreen,
                    Colors.lime,
                    Colors.yellow,
                    Colors.amber,
                    Colors.orange,
                    Colors.deepOrange,
                    Colors.brown,
                    Colors.grey,
                    Colors.blueGrey,
                  ]
                  .map(
                    (color) => GestureDetector(
                      onTap: () => setState(() => _selectedColor = color),
                      child: Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border:
                              _selectedColor == color
                                  ? Border.all(color: Colors.black, width: 2)
                                  : null,
                        ),
                      ),
                    ),
                  )
                  .toList(),
        ),
      ],
    );
  }

  Widget _buildAlarmSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('알림 설정'),
            Switch(
              value: _hasAlarm,
              onChanged: (value) {
                setState(() {
                  _hasAlarm = value;
                });
              },
            ),
          ],
        ),
        if (_hasAlarm)
          DropdownButtonFormField<Duration>(
            decoration: const InputDecoration(labelText: '알림 시간'),
            value: _alarmOffset,
            items: [
              const DropdownMenuItem(
                value: Duration(minutes: 5),
                child: Text('5분 전'),
              ),
              const DropdownMenuItem(
                value: Duration(minutes: 10),
                child: Text('10분 전'),
              ),
              const DropdownMenuItem(
                value: Duration(minutes: 15),
                child: Text('15분 전'),
              ),
              const DropdownMenuItem(
                value: Duration(minutes: 30),
                child: Text('30분 전'),
              ),
              const DropdownMenuItem(
                value: Duration(hours: 1),
                child: Text('1시간 전'),
              ),
              const DropdownMenuItem(
                value: Duration(hours: 2),
                child: Text('2시간 전'),
              ),
            ],
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _alarmOffset = value;
                });
              }
            },
          ),
      ],
    );
  }

  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 16.0,
          right: 16.0,
          top: 16.0,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(labelText: '일정 제목'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '일정 제목을 입력해주세요';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16.0),

              TextFormField(
                controller: _subTextController, // Use subText controller
                decoration: const InputDecoration(labelText: '세부 정보 (선택)'),
                maxLines: 1,
                // No onSaved needed if using controller directly
              ),
              const SizedBox(height: 16.0), // Added spacing

              Row(
                children: [
                  Expanded(
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.access_time),
                      title: Text(
                        '시작: ${_selectedStartTime?.format(context) ?? '선택'}',
                      ),
                      onTap: _pickStartTime,
                    ),
                  ),
                  SizedBox(width: 16.0),
                  Expanded(
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.access_time_filled),
                      title: Text(
                        '종료: ${_selectedEndTime?.format(context) ?? '선택'}',
                      ),
                      onTap: _pickEndTime,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 24.0),

              if (widget.isRoutineContext) ...[
                _buildDayOfWeekSelector(),
              ] else ...[
                _buildDatePickerSelector(),
              ],
              const SizedBox(height: 16),
              _buildColorPicker(), // Add color picker
              const SizedBox(height: 16),
              _buildAlarmSelector(), // Add alarm selector
              const SizedBox(height: 24),

              ElevatedButton(
                onPressed: _submitForm,
                child: Text(_isEditMode ? '수정' : '저장'), // Dynamic button text
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12.0),
                ),
              ),
              SizedBox(height: 16.0),
            ],
          ),
        ),
      ),
    );
  }
}
