import 'dart:io';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:recap_today/model/diary_model.dart';
import 'package:recap_today/provider/diary_provider.dart';
import 'package:recap_today/utils/file_manager.dart';

class DiaryWidget extends StatefulWidget {
  final DiaryModel? diary;

  const DiaryWidget({Key? key, this.diary}) : super(key: key);

  @override
  _DiaryWidgetState createState() => _DiaryWidgetState();
}

class _DiaryWidgetState extends State<DiaryWidget> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  List<String> _photoPaths = [];
  bool _isLoading = true;
  DiaryModel? _todayDiary;

  @override
  void initState() {
    super.initState();
    _loadTodayDiary();
  }

  // 오늘의 일기 로딩
  Future<void> _loadTodayDiary() async {
    setState(() {
      _isLoading = true;
    });

    final diaryProvider = Provider.of<DiaryProvider>(context, listen: false);
    final diary = widget.diary ?? await diaryProvider.getTodayDiary();

    setState(() {
      _todayDiary = diary;
      if (diary != null) {
        _titleController.text = diary.title;
        _contentController.text = diary.content;
        _photoPaths = List<String>.from(diary.photoPaths);
      }
      _isLoading = false;
    });
  }

  // 여러 이미지를 한 번에 선택하는 함수
  Future<void> _pickMultipleImages() async {
    final picker = ImagePicker();
    final pickedFiles = await picker.pickMultiImage();

    if (pickedFiles.isNotEmpty) {
      for (var image in pickedFiles) {
        final path = await FileManager.savePhoto(File(image.path));
        setState(() {
          _photoPaths.add(path);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            DateFormat('yyyy-MM-dd').format(DateTime.now()),
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _titleController,
            decoration: const InputDecoration(labelText: '제목'),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _contentController,
            decoration: const InputDecoration(labelText: '내용'),
            maxLines: 5,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _pickMultipleImages,
            child: const Text('사진 추가'),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _photoPaths.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: Stack(
                    children: [
                      Image.file(
                        File(_photoPaths[index]),
                        width: 150,
                        fit: BoxFit.cover,
                      ),
                      Positioned(
                        top: 0,
                        right: 0,
                        child: IconButton(
                          icon: const Icon(Icons.close, color: Colors.red),
                          onPressed: () {
                            setState(() {
                              _photoPaths.removeAt(index);
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton(
              onPressed: () async {
                if (_titleController.text.isEmpty) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(const SnackBar(content: Text('제목을 입력하세요')));
                  return;
                }
                final diary = DiaryModel(
                  id: _todayDiary?.id,
                  date: DateTime.now().toIso8601String().substring(0, 10),
                  title: _titleController.text,
                  content: _contentController.text,
                  photoPaths: _photoPaths,
                );

                try {
                  // 일기를 저장하고 저장된 일기 객체를 반환받음
                  final savedDiary = await Provider.of<DiaryProvider>(
                    context,
                    listen: false,
                  ).saveDiary(diary);

                  // 현재 일기 상태 업데이트
                  setState(() {
                    _todayDiary = savedDiary;
                  });

                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(const SnackBar(content: Text('일기가 저장되었습니다')));
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('오류가 발생했습니다: ${e.toString()}')),
                  );
                }
              },
              child: const Text('저장'),
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
