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
  // final ScheduleItem? initialItem;

  const ScheduleAddForm({
    Key? key,
    required this.isRoutineContext,
    this.selectedDate,
    this.dayOfWeek,
    // this.initialItem,
  }) : super(key: key);

  _ScheduleAddFormState createState() => _ScheduleAddFormState();
}

class _ScheduleAddFormState extends State<ScheduleAddForm> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _titleController;
  String? _subText;
  TimeOfDay? _selectedStartTime;
  TimeOfDay? _selectedEndTime;
  int _selectedDayOfWeek = DateTime.now().weekday % 7;
  DateTime? _selectedSpecificDate;
  Color _selectedColor = Colors.orangeAccent;
  bool _hasAlarm = false;
  Duration _alarmOffset = const Duration(minutes: 60);

  void initState() {
    super.initState();
    // 수정 모드일 경우 widget.initialItem 값으로 변수들 초기화하는 로직 추가
    _titleController = TextEditingController(
      // 수정 시 초기값 설정
    );
    _selectedStartTime = TimeOfDay.fromDateTime(DateTime.now().add(Duration(hours: 1)));
    _selectedEndTime = TimeOfDay.fromDateTime(DateTime.now().add(Duration(hours: 2)));

    if (!widget.isRoutineContext) {
      _selectedSpecificDate = widget.selectedDate ?? DateTime.now();
    }
    else {
      _selectedDayOfWeek = DateTime.now().weekday % 7;
    }
  }

  void dispose() { // 컨트롤러는 메모리 누수를 막기 위해 반드시 dispose 필요
    _titleController.dispose();
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
      if (_selectedStartTime != null && _isTimeBefore(picked, _selectedStartTime!)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('종료 시간은 시작 시간보다 늦어야 합니다.')),
          );
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
    if (time1.hour < time2. hour) return true;
    else if (time1.hour >= time2.hour) return false;
    return time1.minute < time2.minute;
  }

  void _submitForm() {
    if (_formKey.currentState?.validate() ?? false) {
      _formKey.currentState?.save();

      final startTime = _selectedStartTime;
      final endTime = _selectedEndTime;
      final date = _selectedSpecificDate;

      if (startTime == null || endTime == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('시작 시간과 종료 시간을 모두 선택해주세요.')),
          );
        }
        return;
      }

      if (!widget.isRoutineContext && date == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('날짜를 선택해주세요.')),
          );
          return;
        }
      }

      final newItem = ScheduleItem(
        id: Uuid().v4(),
        text: _titleController.text,
        subText: _subText,
        dayOfWeek: widget.isRoutineContext ? _selectedDayOfWeek : null,
        selectedDate: widget.isRoutineContext ? null : _selectedSpecificDate,
        isRoutine: widget.isRoutineContext,
        startTime: startTime,
        endTime: endTime,
        color: _selectedColor,
        hasAlarm: _hasAlarm,
        alarmOffset: _hasAlarm ? _alarmOffset : null
      );

      Provider.of<ScheduleProvider>(context, listen: false).addItem(newItem);

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
          children: weekDays.map((day) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: Text(day),
          )).toList(),
        ),
      ],
    );
  }

  Widget _buildDatePickerSelector() {
    final formattedDate = _selectedSpecificDate != null
        ? DateFormat.MMMEd('ko_KR').format(_selectedSpecificDate!)
        : '날짜 선택';

    return ListTile(
      leading: Icon(Icons.calendar_today),
      title: Text(formattedDate),
      trailing: Icon(Icons.arrow_drop_down),
      onTap: _pickDate,
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
                  if (value == null || value.isEmpty)
                    return '일정 제목을 입력해주세요';
                  return null;
                },
              ),
              SizedBox(height: 16.0),

              TextFormField(
                decoration: InputDecoration(labelText: '세부 정보(선택)'),
                maxLines: 1,
                onSaved: (value) {
                  _subText = value;
                }
              ),

              Row(
                children: [
                  Expanded(
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.access_time),
                      title: Text('시작: ${_selectedStartTime?.format(context) ?? '선택'}'),
                      onTap: _pickStartTime,
                    ),
                  ),
                  SizedBox(width: 16.0),
                  Expanded(
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.access_time_filled),
                      title: Text('종료: ${_selectedEndTime?.format(context) ?? '선택'}'),
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
              SizedBox(height: 16),

              ElevatedButton(
                onPressed: _submitForm, // 저장
                child: Text('저장'),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 12.0),
                ),
              ),
              SizedBox(height: 16.0),
            ],
          )
        )
      )
    );
  }
}