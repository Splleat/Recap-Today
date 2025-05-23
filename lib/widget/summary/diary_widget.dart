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
    try {
      final picker = ImagePicker();
      final pickedFiles = await picker.pickMultiImage();

      if (pickedFiles.isNotEmpty) {
        // 선택된 이미지 저장 시작 상태 표시
        setState(() {
          _isLoading = true;
        });

        int successCount = 0;
        int failCount = 0;

        for (var image in pickedFiles) {
          // 파일 저장 및 상대 경로 획득
          final relativePath = await FileManager.savePhoto(File(image.path));

          if (relativePath != null) {
            // 성공적으로 저장된 이미지만 추가
            setState(() {
              _photoPaths.add(relativePath);
            });
            successCount++;
          } else {
            failCount++;
          }
        }

        // 작업 완료 후 로딩 상태 해제
        setState(() {
          _isLoading = false;
        });

        // 저장 결과 사용자에게 알림
        if (successCount > 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('$successCount개의 사진이 추가되었습니다')),
          );
        }

        if (failCount > 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '$failCount개의 사진을 추가하지 못했습니다.\n크기가 너무 크거나 지원하지 않는 형식입니다.',
              ),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('사진을 불러오는 중 오류가 발생했습니다: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
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
                return FutureBuilder<String>(
                  future: FileManager.getAbsolutePath(_photoPaths[index]),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const SizedBox(
                        width: 150,
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }

                    if (snapshot.hasError || !snapshot.hasData) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: Stack(
                          children: [
                            SizedBox(
                              width: 150,
                              child: Center(
                                child: Icon(
                                  Icons.broken_image,
                                  color: Colors.red.shade300,
                                  size: 48,
                                ),
                              ),
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
                    }

                    final absPath = snapshot.data!;
                    bool fileExists = false;
                    try {
                      fileExists = File(absPath).existsSync();
                    } catch (e) {
                      fileExists = false;
                    }

                    if (!fileExists) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: Stack(
                          children: [
                            SizedBox(
                              width: 150,
                              child: Center(
                                child: Icon(
                                  Icons.broken_image,
                                  color: Colors.red.shade300,
                                  size: 48,
                                ),
                              ),
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
                    }

                    try {
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: Stack(
                          children: [
                            Image.file(
                              File(absPath),
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
                    } catch (e) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: Stack(
                          children: [
                            SizedBox(
                              width: 150,
                              child: Center(
                                child: Icon(
                                  Icons.broken_image,
                                  color: Colors.red.shade300,
                                  size: 48,
                                ),
                              ),
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
                    }
                  },
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

                  // 저장된 일기의 photoPaths만 남기고 나머지 파일 정리
                  await FileManager.cleanupUnusedPhotos(savedDiary.photoPaths);

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
    // cleanupUnusedPhotos는 여기서 호출하지 않음 (일기 저장 시에만 호출)
    super.dispose();
  }
}
