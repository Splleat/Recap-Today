// photo_backup_util.dart
import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import 'package:image/image.dart' as img;
import 'package:recap_today/utils/file_manager.dart';

/// 사진 백업 및 복원을 위한 유틸리티 클래스
class PhotoBackupUtil {
  /// 사진 파일들을 Base64로 인코딩하여 백업 데이터로 변환 (압축 적용)
  static Future<List<Map<String, dynamic>>> encodePhotosForBackup(
    List<String> photoPaths,
  ) async {
    final List<Map<String, dynamic>> encodedPhotos = [];

    debugPrint('📸 사진 백업 인코딩 시작: ${photoPaths.length}개');

    for (int i = 0; i < photoPaths.length; i++) {
      final relativePath = photoPaths[i];
      try {
        final absolutePath = await FileManager.getAbsolutePath(relativePath);
        final file = File(absolutePath);

        if (await file.exists()) {
          final originalBytes = await file.readAsBytes();
          final fileName = path.basename(relativePath);

          // 이미지 압축 적용
          final compressedBytes = await _compressImage(originalBytes);
          final base64String = base64Encode(compressedBytes);

          encodedPhotos.add({
            'fileName': fileName,
            'relativePath': relativePath,
            'data': base64String,
            'size': compressedBytes.length,
            'originalSize': originalBytes.length,
          });

          final compressionRatio = ((originalBytes.length -
                      compressedBytes.length) /
                  originalBytes.length *
                  100)
              .toStringAsFixed(1);
          debugPrint(
            '📸 사진 $i 인코딩 완료: $fileName (${originalBytes.length} → ${compressedBytes.length} bytes, $compressionRatio% 압축)',
          );
        } else {
          debugPrint('📸 사진 $i 파일 없음: $absolutePath');
        }
      } catch (e) {
        debugPrint('📸 사진 $i 인코딩 오류: $e');
      }
    }

    debugPrint('📸 사진 백업 인코딩 완료: ${encodedPhotos.length}개 성공');
    return encodedPhotos;
  }

  /// Base64로 인코딩된 사진 데이터를 파일로 복원
  static Future<List<String>> decodePhotosFromBackup(
    List<dynamic> encodedPhotos,
  ) async {
    final List<String> restoredPaths = [];

    debugPrint('📸 사진 백업 디코딩 시작: ${encodedPhotos.length}개');

    for (int i = 0; i < encodedPhotos.length; i++) {
      final photoData = encodedPhotos[i] as Map<String, dynamic>;
      try {
        final fileName = photoData['fileName'] as String;
        final base64String = photoData['data'] as String;

        // Base64 디코딩
        final bytes = base64Decode(base64String);

        // 새로운 파일명 생성 (중복 방지)
        final photosDir = await FileManager.photosDir;
        final newFileName = _generateUniqueFileName(fileName);
        final newFilePath = path.join(photosDir, newFileName);

        // 파일 저장
        final file = File(newFilePath);
        await file.writeAsBytes(bytes);

        // 상대 경로 생성
        final newRelativePath = FileManager.createRelativePath(newFilePath);
        restoredPaths.add(newRelativePath);

        debugPrint('📸 사진 $i 디코딩 완료: $newFileName (${bytes.length} bytes)');
      } catch (e) {
        debugPrint('📸 사진 $i 디코딩 오류: $e');
      }
    }

    debugPrint('📸 사진 백업 디코딩 완료: ${restoredPaths.length}개 성공');
    return restoredPaths;
  }

  /// 고유한 파일명 생성 (중복 방지)
  static String _generateUniqueFileName(String originalFileName) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final extension = path.extension(originalFileName);
    final nameWithoutExt = path.basenameWithoutExtension(originalFileName);
    return '${nameWithoutExt}_restored_$timestamp$extension';
  }

  /// 사진 백업 크기 계산 (MB 단위)
  static Future<double> calculateBackupSize(List<String> photoPaths) async {
    int totalBytes = 0;

    for (final relativePath in photoPaths) {
      try {
        final absolutePath = await FileManager.getAbsolutePath(relativePath);
        final file = File(absolutePath);

        if (await file.exists()) {
          final bytes = await file.length();
          totalBytes += bytes;
        }
      } catch (e) {
        debugPrint('📸 사진 크기 계산 오류: $e');
      }
    }

    return totalBytes / (1024 * 1024); // MB로 변환
  }

  /// 이미지 압축 함수
  static Future<Uint8List> _compressImage(Uint8List bytes) async {
    try {
      // 이미지 디코딩
      final img.Image? image = img.decodeImage(bytes);
      if (image == null) {
        debugPrint('📸 이미지 디코딩 실패, 원본 반환');
        return bytes;
      } // 이미지 크기가 큰 경우 리사이즈 (최대 500x500)
      img.Image resizedImage = image;
      const int maxSize = 500;

      if (image.width > maxSize || image.height > maxSize) {
        if (image.width > image.height) {
          resizedImage = img.copyResize(image, width: maxSize);
        } else {
          resizedImage = img.copyResize(image, height: maxSize);
        }
        debugPrint(
          '📸 이미지 리사이즈: ${image.width}x${image.height} → ${resizedImage.width}x${resizedImage.height}',
        );
      } // JPEG로 압축 (품질 40%)
      final compressedBytes = img.encodeJpg(resizedImage, quality: 40);

      final compressionRatio =
          ((bytes.length - compressedBytes.length) / bytes.length * 100);
      debugPrint(
        '📸 이미지 압축 완료: ${bytes.length} → ${compressedBytes.length} bytes (${compressionRatio.toStringAsFixed(1)}% 압축)',
      );

      return Uint8List.fromList(compressedBytes);
    } catch (e) {
      debugPrint('📸 이미지 압축 오류: $e, 원본 반환');
      return bytes;
    }
  }
}
