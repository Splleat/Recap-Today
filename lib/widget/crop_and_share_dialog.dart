import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:recap_today/utils/share_util.dart';

enum _ActiveHandle { none, top, bottom }

class CropAndShareDialog extends StatefulWidget {
  final Uint8List originalImageBytes;

  const CropAndShareDialog({Key? key, required this.originalImageBytes})
    : super(key: key);

  @override
  _CropAndShareDialogState createState() => _CropAndShareDialogState();
}

class _CropAndShareDialogState extends State<CropAndShareDialog> {
  final GlobalKey _imageAreaKey = GlobalKey();
  ui.Image? _decodedImage;
  double _imageScale = 1.0;

  double _cropTopY = 0;
  double _cropBottomY = 0;
  double _imageDisplayWidth = 0;
  double _imageDisplayHeight = 0;

  _ActiveHandle _activeHandle = _ActiveHandle.none;

  static const double _handleVisualHeight =
      20.0; // Visual thickness of the handle line - Increased
  static const double _handleTouchTargetHeight =
      100.0; // Interaction area height for gestures - Increased
  static const double _minCropHeight =
      50.0; // Minimum pixels for crop height on display

  @override
  void initState() {
    super.initState();
    _loadAndProcessImage();
  }

  Future<void> _loadAndProcessImage() async {
    _decodedImage = await ShareUtil.decodeImageFromList(
      widget.originalImageBytes,
    );
    if (!mounted || _decodedImage == null) return;

    // Calculate display dimensions after the first frame is rendered and context is available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final screenWidth = MediaQuery.of(context).size.width;
      // Standard padding for dialogs/content area
      final availableWidth = screenWidth - (16.0 * 2);

      if (_decodedImage!.width > availableWidth) {
        _imageScale = availableWidth / _decodedImage!.width;
      } else {
        _imageScale = 1.0;
      }

      setState(() {
        _imageDisplayWidth = _decodedImage!.width * _imageScale;
        _imageDisplayHeight = _decodedImage!.height * _imageScale;
        _cropTopY = 0;
        _cropBottomY = _imageDisplayHeight;
      });
    });
  }

  void _handleShare(Uint8List imageBytesToShare) async {
    final navigator = Navigator.of(context);
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    final file = await ShareUtil.saveToTempFile(
      imageBytesToShare,
      'recap_today_cropped_image',
    );
    if (file != null) {
      await ShareUtil.shareImageFile(file);
      // Consider deleting the temp file after a short delay or if share is confirmed successful
      // await File(file.path).delete();
      navigator.pop(); // Close the dialog
    } else {
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('파일 저장에 실패하여 공유할 수 없습니다.')),
      );
    }
  }

  void _resetCrop() {
    if (mounted && _decodedImage != null) {
      setState(() {
        _cropTopY = 0;
        _cropBottomY = _imageDisplayHeight;
        _activeHandle = _ActiveHandle.none;
      });
    }
  }

  Widget _buildTopHandle() {
    return Positioned(
      top: _cropTopY - (_handleTouchTargetHeight / 2),
      left: 0,
      right: 0,
      height: _handleTouchTargetHeight,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque, // Capture taps within this area
        onVerticalDragStart: (details) {
          if (!mounted) return;
          setState(() {
            _activeHandle = _ActiveHandle.top;
          });
        },
        onVerticalDragUpdate: (details) {
          if (!mounted || _decodedImage == null) return;
          final RenderBox imageAreaRenderBox =
              _imageAreaKey.currentContext?.findRenderObject() as RenderBox;
          final Offset localPosition = imageAreaRenderBox.globalToLocal(
            details.globalPosition,
          );

          setState(() {
            _cropTopY = localPosition.dy.clamp(
              0.0,
              _cropBottomY - _minCropHeight,
            );
          });
        },
        onVerticalDragEnd: (details) {
          if (!mounted) return;
          setState(() {
            _activeHandle = _ActiveHandle.none;
          });
        },
        child: Center(
          child: Container(
            height: _handleVisualHeight,
            width: _imageDisplayWidth * 0.8, // Visual handle width - Increased
            decoration: BoxDecoration(
              color:
                  _activeHandle == _ActiveHandle.top
                      ? Colors.blueAccent.shade700
                      : Colors.blueAccent,
              borderRadius: BorderRadius.circular(_handleVisualHeight / 2),
              border: Border.all(color: Colors.white, width: 1.0),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomHandle() {
    return Positioned(
      top: _cropBottomY - (_handleTouchTargetHeight / 2),
      left: 0,
      right: 0,
      height: _handleTouchTargetHeight,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onVerticalDragStart: (details) {
          if (!mounted) return;
          setState(() {
            _activeHandle = _ActiveHandle.bottom;
          });
        },
        onVerticalDragUpdate: (details) {
          if (!mounted || _decodedImage == null) return;
          final RenderBox imageAreaRenderBox =
              _imageAreaKey.currentContext?.findRenderObject() as RenderBox;
          final Offset localPosition = imageAreaRenderBox.globalToLocal(
            details.globalPosition,
          );

          setState(() {
            _cropBottomY = localPosition.dy.clamp(
              _cropTopY + _minCropHeight,
              _imageDisplayHeight,
            );
          });
        },
        onVerticalDragEnd: (details) {
          if (!mounted) return;
          setState(() {
            _activeHandle = _ActiveHandle.none;
          });
        },
        child: Center(
          child: Container(
            height: _handleVisualHeight,
            width: _imageDisplayWidth * 0.8, // Visual handle width - Increased
            decoration: BoxDecoration(
              color:
                  _activeHandle == _ActiveHandle.bottom
                      ? Colors.blueAccent.shade700
                      : Colors.blueAccent,
              borderRadius: BorderRadius.circular(_handleVisualHeight / 2),
              border: Border.all(color: Colors.white, width: 1.0),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('영역 선택'),
        actions: [
          TextButton(
            onPressed: () async {
              if (_decodedImage == null ||
                  _imageDisplayWidth <= 0 ||
                  _imageDisplayHeight <= 0) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text('이미지가 아직 로드되지 않았습니다.')));
                return;
              }

              final Rect displayCropRect = Rect.fromLTRB(
                0, // Crop X is always 0 for full width
                _cropTopY,
                _imageDisplayWidth, // Crop width is always full display width
                _cropBottomY,
              );

              if (displayCropRect.width <= 0 ||
                  displayCropRect.height <= 0 ||
                  displayCropRect.height < _minCropHeight) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('유효한 영역을 선택해주세요. 최소 높이: ${_minCropHeight}px'),
                  ),
                );
                return;
              }

              final Rect cropRectInOriginalPixels = Rect.fromLTWH(
                0, // X in original image pixels (always 0 for full width)
                displayCropRect.top /
                    _imageScale, // Top in original image pixels
                _decodedImage!.width
                    .toDouble(), // Width in original image pixels (full width)
                displayCropRect.height /
                    _imageScale, // Height in original image pixels
              );

              final Rect originalImageBounds = Rect.fromLTWH(
                0,
                0,
                _decodedImage!.width.toDouble(),
                _decodedImage!.height.toDouble(),
              );
              final Rect validCropRectPx = cropRectInOriginalPixels.intersect(
                originalImageBounds,
              );

              if (validCropRectPx.isEmpty ||
                  validCropRectPx.width <= 0 ||
                  validCropRectPx.height <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('자르기 영역이 이미지 범위를 벗어났습니다.')),
                );
                return;
              }

              final Uint8List? croppedBytes = await ShareUtil.cropImageBytes(
                widget.originalImageBytes,
                validCropRectPx,
              );

              if (croppedBytes != null) {
                _handleShare(croppedBytes);
              } else {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text('이미지 자르기에 실패했습니다.')));
              }
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 8.0,
              ), // Add some padding
              child: Text(
                '공유하기',
                style: TextStyle(
                  color: IconTheme.of(context).color, // AppBar의 아이콘 테마 색상 사용
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ],
      ),
      body:
          _decodedImage == null || _imageDisplayHeight == 0
              ? Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                // This will always be scrollable
                physics: AlwaysScrollableScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize:
                        MainAxisSize
                            .min, // Important for SingleChildScrollView with Column
                    children: [
                      Text(
                        '위 아래 핸들을 움직여 공유할 영역을 조절하세요.',
                        style: TextStyle(fontSize: 16),
                      ),
                      SizedBox(height: 20),
                      if (_imageDisplayWidth > 0 && _imageDisplayHeight > 0)
                        SizedBox(
                          key: _imageAreaKey, // Key for coordinate conversion
                          width: _imageDisplayWidth,
                          height: _imageDisplayHeight,
                          child: Stack(
                            clipBehavior:
                                Clip.none, // Allow handles to be slightly outside if needed
                            children: [
                              CustomPaint(
                                size: Size(
                                  _imageDisplayWidth,
                                  _imageDisplayHeight,
                                ),
                                painter: ImageCropPainter(
                                  image: _decodedImage!,
                                  cropTopY: _cropTopY,
                                  cropBottomY: _cropBottomY,
                                ),
                              ),
                              _buildTopHandle(),
                              _buildBottomHandle(),
                            ],
                          ),
                        )
                      else
                        Container(
                          // Placeholder if image dimensions are not yet calculated
                          height: 200, // Arbitrary height
                          child: Center(child: Text("이미지 로딩 중...")),
                        ),
                      SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _resetCrop,
                        child: Text('자르기 초기화'),
                      ),
                    ],
                  ),
                ),
              ),
    );
  }
}

class ImageCropPainter extends CustomPainter {
  final ui.Image image;
  final double cropTopY;
  final double cropBottomY;

  ImageCropPainter({
    required this.image,
    required this.cropTopY,
    required this.cropBottomY,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // size is _imageDisplayWidth, _imageDisplayHeight
    final imagePaint = Paint();

    // Draw the scaled image to fit the CustomPaint area
    canvas.drawImageRect(
      image,
      Rect.fromLTWH(
        0,
        0,
        image.width.toDouble(),
        image.height.toDouble(),
      ), // Source rect (original image)
      Rect.fromLTWH(
        0,
        0,
        size.width,
        size.height,
      ), // Destination rect (display area)
      imagePaint,
    );

    final dimPaint = Paint()..color = Colors.black.withOpacity(0.6);

    // Dim area above top handle
    canvas.drawRect(Rect.fromLTRB(0, 0, size.width, cropTopY), dimPaint);
    // Dim area below bottom handle
    canvas.drawRect(
      Rect.fromLTRB(0, cropBottomY, size.width, size.height),
      dimPaint,
    );

    // Draw thin lines across the width at cropTopY and cropBottomY
    final linePaint =
        Paint()
          ..color = Colors.white.withOpacity(0.7)
          ..strokeWidth = 1.5;
    canvas.drawLine(
      Offset(0, cropTopY),
      Offset(size.width, cropTopY),
      linePaint,
    );
    canvas.drawLine(
      Offset(0, cropBottomY),
      Offset(size.width, cropBottomY),
      linePaint,
    );
  }

  @override
  bool shouldRepaint(ImageCropPainter oldDelegate) {
    return oldDelegate.image != image ||
        oldDelegate.cropTopY != cropTopY ||
        oldDelegate.cropBottomY != cropBottomY;
  }
}
