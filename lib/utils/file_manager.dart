// file_manager.dart
import 'dart:io';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';

/// 파일 관리 클래스 (사진 저장)
class FileManager {
  /// 최대 허용 파일 크기 (10MB)
  static const int maxFileSize = 10 * 1024 * 1024;

  /// 허용되는 이미지 확장자
  static const List<String> allowedExtensions = [
    '.jpg',
    '.jpeg',
    '.png',
    '.gif',
    '.webp',
  ];

  /// 사진 저장 디렉토리 경로 가져오기
  static Future<String> get photosDir async {
    final directory = await getApplicationDocumentsDirectory();
    final photoPath = path.join(directory.path, 'diary_photos');
    await Directory(photoPath).create(recursive: true);
    return photoPath;
  }

  /// 상대 경로 생성 (데이터베이스 저장용)
  static String createRelativePath(String fullPath) {
    final fileName = path.basename(fullPath);
    return 'diary_photos/$fileName';
  }

  /// 상대 경로에서 절대 경로 얻기
  static Future<String> getAbsolutePath(String relativePath) async {
    if (relativePath.startsWith('/')) {
      // 이미 절대 경로인 경우
      return relativePath;
    }

    // 상대 경로에서 파일명만 추출
    String fileName;
    if (relativePath.contains('/')) {
      fileName = relativePath.split('/').last;
    } else {
      fileName = relativePath;
    }

    final directory = await getApplicationDocumentsDirectory();
    return path.join(directory.path, 'diary_photos', fileName);
  }

  /// 파일 해시값 계산
  static Future<String> _computeFileHash(File file) async {
    try {
      final bytes = await file.readAsBytes();
      final digest = sha256.convert(bytes);
      return digest.toString();
    } catch (e) {
      debugPrint('Error computing file hash: $e');
      // 오류 발생 시 현재 시간 기반 해시를 반환
      return DateTime.now().millisecondsSinceEpoch.toString();
    }
  }

  /// 고유한 파일명 생성
  static String _generateUniqueFileName(String originalFileName) {
    String fileExtension;
    try {
      fileExtension = path.extension(originalFileName).toLowerCase();
      if (fileExtension.isEmpty) {
        fileExtension = '.jpg'; // 기본 확장자
      }
    } catch (e) {
      debugPrint('Error getting extension: $e');
      fileExtension = '.jpg'; // 오류 시 기본 확장자
    }

    String uuid;
    try {
      uuid = const Uuid().v4();
    } catch (e) {
      debugPrint('Error generating UUID: $e');
      // UUID 생성 실패 시 대체 고유 ID 생성
      uuid =
          '${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(10000)}';
    }

    return '$uuid$fileExtension';
  }

  /// 파일 유효성 검사
  static Future<bool> _validateImageFile(File file) async {
    try {
      // 파일 존재 확인
      if (!await file.exists()) {
        debugPrint('File does not exist: ${file.path}');
        return false;
      }

      // 파일 크기 확인
      final fileSize = await file.length();
      if (fileSize > maxFileSize) {
        debugPrint('File too large: ${fileSize / 1024 / 1024}MB');
        return false;
      }

      // 파일 확장자 확인
      final fileExt = path.extension(file.path).toLowerCase();
      if (!allowedExtensions.contains(fileExt)) {
        debugPrint('Invalid file extension: $fileExt');
        return false;
      }

      return true;
    } catch (e) {
      debugPrint('Error validating file: $e');
      return false;
    }
  }

  /// 사진 파일 저장
  static Future<String?> savePhoto(File file) async {
    try {
      // 파일 유효성 검사
      final isValid = await _validateImageFile(file);
      if (!isValid) {
        debugPrint('Invalid image file: ${file.path}');
        return null;
      }

      // 고유한 파일명 생성
      final uniqueFileName = _generateUniqueFileName(path.basename(file.path));
      final dir = await photosDir;
      final savedFilePath = path.join(dir, uniqueFileName);
      final savedFile = File(savedFilePath);

      // 파일 복사
      await file.copy(savedFile.path);

      // 상대 경로 반환 (데이터베이스 저장용)
      return createRelativePath(savedFile.path);
    } catch (e) {
      debugPrint('Error saving photo: $e');
      return null;
    }
  }

  /// 임시 저장된 사진 정리
  static Future<void> cleanupUnusedPhotos(List<String> usedPaths) async {
    if (usedPaths == null) {
      debugPrint('Used paths list is null');
      return;
    }

    try {
      final dir = await photosDir;
      final directory = Directory(dir);

      if (!await directory.exists()) {
        debugPrint('Photos directory does not exist');
        return;
      }

      final files = directory.listSync();

      for (var file in files) {
        if (file is File) {
          final relativePath = createRelativePath(file.path);
          if (!usedPaths.contains(relativePath)) {
            try {
              await file.delete();
              debugPrint('Deleted unused photo: ${file.path}');
            } catch (e) {
              debugPrint('Error deleting file ${file.path}: $e');
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Error cleaning up photos: $e');
    }
  }
}
