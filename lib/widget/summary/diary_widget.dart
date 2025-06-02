import 'dart:io';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:recap_today/model/diary/diary_model.dart';
import 'package:recap_today/provider/diary_provider.dart';
import 'package:recap_today/utils/file_manager.dart';
import 'package:recap_today/repository/auth_repository.dart';

class DiaryWidget extends StatefulWidget {
  final Diary? diary;
  final DateTime? date;

  const DiaryWidget({Key? key, this.diary, this.date}) : super(key: key);

  @override
  State<DiaryWidget> createState() => _DiaryWidgetState();
}

class _DiaryWidgetState extends State<DiaryWidget> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _imagePicker = ImagePicker();

  List<String> _photoPaths = [];
  bool _isLoading = true;
  Diary? _diary;
  late DateTime _targetDate;

  @override
  void initState() {
    super.initState();
    _targetDate = widget.date ?? DateTime.now();
    _loadDiary();
  }

  @override
  void didUpdateWidget(covariant DiaryWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.date != oldWidget.date) {
      _targetDate = widget.date ?? DateTime.now();
      _loadDiary();
    }
  }

  Future<void> _loadDiary() async {
    setState(() => _isLoading = true);
    final provider = context.read<DiaryProvider>();
    final diary = widget.diary ?? await provider.getDiaryForSpecificDate(_targetDate);

    setState(() {
      _diary = diary;
      _titleController.text = diary?.title ?? '';
      _contentController.text = diary?.content ?? '';
      _photoPaths = diary?.photoPaths ?? [];
      _isLoading = false;
    });
  }

  Future<void> _pickMultipleImages() async {
    try {
      final pickedFiles = await _imagePicker.pickMultiImage();
      if (pickedFiles.isEmpty) return;

      setState(() => _isLoading = true);

      int success = 0;
      int failure = 0;

      for (var file in pickedFiles) {
        final saved = await FileManager.savePhoto(File(file.path));
        if (saved != null) {
          _photoPaths.add(saved);
          success++;
        } else {
          failure++;
        }
      }

      setState(() => _isLoading = false);

      if (success > 0) {
        _showSnackBar('$success개의 사진이 추가되었습니다');
      }
      if (failure > 0) {
        _showSnackBar(
          '$failure개의 사진을 추가하지 못했습니다.\n크기가 너무 크거나 형식이 맞지 않습니다.',
          color: Colors.orange,
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnackBar('오류 발생: ${e.toString()}', color: Colors.red);
    }
  }

  void _showSnackBar(String message, {Color? color}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color),
    );
  }

  Future<void> _saveDiary() async {
    final authRepo = context.read<AuthRepository>();
    final userId = authRepo.getCurrentUserId();

    if (_titleController.text.isEmpty) {
      _showSnackBar('제목을 입력하세요');
      return;
    }

    final diary = Diary(
      id: _diary?.id, // nullable 허용됨
      userId: userId,
      date: DateFormat('yyyy-MM-dd').format(_targetDate),
      title: _titleController.text,
      content: _contentController.text,
      photoPaths: _photoPaths,
      createdAt: _diary?.createdAt ?? DateTime.now(),
    );

    try {
      final saved = await context.read<DiaryProvider>().saveDiary(diary);
      setState(() => _diary = saved);
      _showSnackBar('일기가 저장되었습니다');
    } catch (e) {
      _showSnackBar('저장 실패: ${e.toString()}', color: Colors.red);
    }
  }

  Widget _buildImagePreview(String path, int index) {
    return FutureBuilder<String>(
      future: FileManager.getAbsolutePath(path),
      builder: (context, snapshot) {
        final width = 150.0;

        if (!snapshot.hasData || snapshot.hasError || !File(snapshot.data!).existsSync()) {
          return _buildBrokenImage(index, width);
        }

        return Padding(
          padding: const EdgeInsets.only(right: 8.0),
          child: Stack(
            children: [
              Image.file(File(snapshot.data!), width: width, fit: BoxFit.cover),
              _buildRemoveButton(index),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBrokenImage(int index, double width) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: Stack(
        children: [
          SizedBox(
            width: width,
            child: Center(child: Icon(Icons.broken_image, color: Colors.red.shade300, size: 48)),
          ),
          _buildRemoveButton(index),
        ],
      ),
    );
  }

  Widget _buildRemoveButton(int index) {
    return Positioned(
      top: 0,
      right: 0,
      child: IconButton(
        icon: const Icon(Icons.close, color: Colors.red),
        onPressed: () => setState(() => _photoPaths.removeAt(index)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(DateFormat('yyyy-MM-dd').format(_targetDate), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 24)),
          const SizedBox(height: 16),
          TextField(controller: _titleController, decoration: const InputDecoration(labelText: '제목')),
          const SizedBox(height: 16),
          TextField(controller: _contentController, decoration: const InputDecoration(labelText: '내용'), minLines: 1, maxLines: null),
          const SizedBox(height: 16),
          Row(
            children: [
              ElevatedButton(onPressed: _pickMultipleImages, child: const Text('사진 추가')),
              const Spacer(),
              ElevatedButton(onPressed: _saveDiary, child: const Text('저장')),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _photoPaths.length,
              itemBuilder: (context, index) => _buildImagePreview(_photoPaths[index], index),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }
}
