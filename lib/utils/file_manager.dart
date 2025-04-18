// file_manager.dart
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart';

/// 파일 관리 클래스 (사진 저장)
class FileManager {
  /// 사진 저장 디렉토리 경로 가져오기
  static Future<String> get photosDir async {
    final directory = await getApplicationDocumentsDirectory();
    final path = join(directory.path, 'diary_photos');
    await Directory(path).create(recursive: true);
    return path;
  }

  /// 사진 파일 저장
  static Future<String> savePhoto(File file) async {
    final dir = await photosDir;
    final fileName = basename(file.path);
    final savedFile = File(join(dir, fileName));
    await file.copy(savedFile.path);
    return savedFile.path;
  }
}
