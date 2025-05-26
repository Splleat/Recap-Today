import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class ShareUtil {
    // 위젯 캡쳐 -> 이미지(Uint8List) 반환
    static Future<Uint8List?> capture(GlobalKey key) async {
        try {
            final boundary = key.currentContext?.findRenderObject() as RenderRepaintBoundary?; 
            if (boundary == null) return null;

            if (boundary.debugNeedsPaint) {
                await Future.delayed(const Duration(milliseconds: 20));
                return capture(key);
            }

            final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
            final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
            return byteData?.buffer.asUint8List();
        } catch (e) {
            debugPrint('캡처 실패: $e');
            return null;
        }
    }

    // 이미지(Uint8List)를 임시 파일로 저장 -> XFile 반환
    static Future<XFile?> saveToTempFile(Uint8List bytes, String fileName) async {
        try {
            final dir = await getTemporaryDirectory();
            final path = '${dir.path}/$fileName.png';
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
    static Future<void> captureAndShare(GlobalKey key, String fileName) async {
        final image = await capture(key);
        if (image == null) return;

        final file = await saveToTempFile(image, fileName);
        if (file == null) return;

        await shareImageFile(file);
        // 공유 후 임시 파일 삭제
        await File(file.path).delete();
    }
}
