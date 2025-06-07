import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class ShareUtil {
    // Helper function to decode Uint8List to ui.Image
    static Future<ui.Image> decodeImageFromList(Uint8List list) async {
      final codec = await ui.instantiateImageCodec(list);
      final frame = await codec.getNextFrame();
      return frame.image;
    }

    // 위젯 캡쳐 -> 이미지(Uint8List) 반환
    static Future<Uint8List?> capture(GlobalKey key, {Rect? cropArea}) async { // Added cropArea parameter
        try {
            final boundary = key.currentContext?.findRenderObject() as RenderRepaintBoundary?;
            if (boundary == null) return null;

            if (boundary.debugNeedsPaint) {
                await Future.delayed(const Duration(milliseconds: 20));
                return capture(key, cropArea: cropArea); // Pass cropArea in recursive call
            }

            const double pixelRatio = 3.0;
            final ui.Image originalImage = await boundary.toImage(pixelRatio: pixelRatio);

            if (cropArea != null) {
                // Crop the image if cropArea is provided
                final recorder = ui.PictureRecorder();
                final scaledCropWidth = cropArea.width * pixelRatio;
                final scaledCropHeight = cropArea.height * pixelRatio;

                // Create a canvas for the cropped image
                final canvas = ui.Canvas(recorder, Rect.fromLTWH(0, 0, scaledCropWidth, scaledCropHeight));

                final Rect srcRect = Rect.fromLTWH(
                    cropArea.left * pixelRatio,
                    cropArea.top * pixelRatio,
                    scaledCropWidth,
                    scaledCropHeight,
                );
                final Rect dstRect = Rect.fromLTWH(0, 0, scaledCropWidth, scaledCropHeight);

                canvas.drawImageRect(originalImage, srcRect, dstRect, Paint());

                final picture = recorder.endRecording();
                final ui.Image croppedImage = await picture.toImage(
                    scaledCropWidth.toInt(),
                    scaledCropHeight.toInt(),
                );
                
                final byteData = await croppedImage.toByteData(format: ui.ImageByteFormat.png);
                originalImage.dispose(); // Dispose original image
                croppedImage.dispose(); // Dispose cropped image
                return byteData?.buffer.asUint8List();

            } else {
                // No cropArea, return the full image
                final byteData = await originalImage.toByteData(format: ui.ImageByteFormat.png);
                originalImage.dispose(); // Dispose original image
                return byteData?.buffer.asUint8List();
            }

        } catch (e) {
            debugPrint('캡처 실패: $e');
            return null;
        }
    }

    // 이미지(Uint8List)를 임시 파일로 저장 -> XFile 반환
    static Future<XFile?> saveToTempFile(Uint8List bytes, String fileName) async {
        try {
            final dir = await getTemporaryDirectory();
            final path = '${dir.path}/$fileName.png'; // Ensure .png extension for consistency
            final file = await File(path).writeAsBytes(bytes);
            return XFile(file.path);
        } catch (e) {
            debugPrint('파일 저장 실패: $e');
            return null;
        }
    }

    // XFile 공유
    static Future<void> shareImageFile(XFile file, {String? text}) async {
        try {
            await Share.shareXFiles([file], text: text ?? '오늘 하루 요약이에요!');
        } catch (e) {
            debugPrint('공유 실패: $e');
        }
    }

    // 캡처 -> 저장 -> 공유
    static Future<void> captureAndShare(GlobalKey key, String fileName, {Rect? cropArea}) async { // Added cropArea parameter
        // This method might be simplified or removed if the new dialog flow is preferred
        final Uint8List? imageBytes = await capture(key, cropArea: cropArea); // Pass cropArea
        if (imageBytes == null) return;

        final file = await saveToTempFile(imageBytes, fileName);
        if (file == null) return;

        await shareImageFile(file);
        // 공유 후 임시 파일 삭제
        await File(file.path).delete(); // Make sure to import 'dart:io' for File
    }

    // New method to crop image bytes
    static Future<Uint8List?> cropImageBytes(Uint8List originalImageBytes, Rect cropRectPx) async {
        try {
          final ui.Image originalUiImage = await decodeImageFromList(originalImageBytes); // Changed to use public static method

          final recorder = ui.PictureRecorder();
          // Canvas for the cropped image, dimensions are from cropRectPx
          final canvas = ui.Canvas(recorder, Rect.fromLTWH(0, 0, cropRectPx.width, cropRectPx.height));

          // Source rect is cropRectPx (from original image)
          // Destination rect is 0,0 to cropRectPx.width, cropRectPx.height (in the new canvas)
          final Rect dstRect = Rect.fromLTWH(0, 0, cropRectPx.width, cropRectPx.height);

          canvas.drawImageRect(originalUiImage, cropRectPx, dstRect, Paint());

          final picture = recorder.endRecording();
          final ui.Image croppedImage = await picture.toImage(
            cropRectPx.width.toInt(),
            cropRectPx.height.toInt(),
          );
          
          final byteData = await croppedImage.toByteData(format: ui.ImageByteFormat.png);
          originalUiImage.dispose(); // Dispose original image to free memory
          croppedImage.dispose(); // Dispose cropped image to free memory
          return byteData?.buffer.asUint8List();
        } catch (e) {
          debugPrint('cropImageBytes failed: $e');
          return null;
        }
    }
}
