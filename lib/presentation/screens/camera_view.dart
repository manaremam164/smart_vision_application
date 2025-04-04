import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_object_detection/google_mlkit_object_detection.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

class ObjectDetectionScreen extends StatefulWidget {
  const ObjectDetectionScreen({super.key});

  @override
  State<ObjectDetectionScreen> createState() => _ObjectDetectionScreenState();
}

class _ObjectDetectionScreenState extends State<ObjectDetectionScreen> {
  late CameraController _cameraController;
  late ObjectDetector _objectDetector;
  bool _isDetecting = false;
  List<DetectedObject> _objects = [];
  late List<CameraDescription> _cameras;
  bool _isInitialized = false;
  double _zoomLevel = 1.0;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _initializeDetector();
  }

  Future<void> _initializeCamera() async {
    _cameras = await availableCameras();
    _cameraController = CameraController(
      _cameras[0], // Use first camera (typically back camera)
      ResolutionPreset.high,
      enableAudio: false,
    );

    await _cameraController.initialize();
    if (!mounted) return;

    setState(() => _isInitialized = true);
    _cameraController.startImageStream(_processCameraImage);
  }

  void _initializeDetector() {
    // Configure object detector
    final options = ObjectDetectorOptions(
      mode: DetectionMode.single,
      classifyObjects: true,
      multipleObjects: true,
    );
    _objectDetector = ObjectDetector(options: options);
  }

  Future<void> _processCameraImage(CameraImage image) async {
    if (_isDetecting) return;
    
    _isDetecting = true;
    final WriteBuffer allBytes = WriteBuffer();
    for (Plane plane in image.planes) {
      allBytes.putUint8List(plane.bytes);
    }
    final bytes = allBytes.done().buffer.asUint8List();

    final inputImage = InputImage.fromBytes(
      bytes: bytes,
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: InputImageRotation.rotation0deg,
        format: InputImageFormatValue.fromRawValue(image.format.raw) ?? 
          InputImageFormat.nv21,
        bytesPerRow: image.planes[0].bytesPerRow,
      ),
    );

    try {
      final objects = await _objectDetector.processImage(inputImage);
      if (mounted) {
        setState(() => _objects = objects);
      }
    } catch (e) {
      debugPrint('Error detecting objects: $e');
    } finally {
      _isDetecting = false;
    }
  }

  @override
  void dispose() {
    _cameraController.dispose();
    _objectDetector.close();
    super.dispose();
  }

  Widget _buildCameraPreview() {
    if (!_isInitialized) {
      return Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
        ),
      );
    }

    return SizedBox(
      width: MediaQuery.of(context).size.width,
      height: MediaQuery.of(context).size.height,
      child: CameraPreview(_cameraController),
    );
  }

  Widget _buildDetectionOverlay() {
    return CustomPaint(
      painter: ObjectDetectionPainter(
        objects: _objects,
        previewSize: Size(
          MediaQuery.of(context).size.width,
          MediaQuery.of(context).size.height,
        ),
      ),
    );
  }

  Widget _buildZoomControls() {
    return Positioned(
      right: 16,
      bottom: 100,
      child: Column(
        children: [
          IconButton(
            icon: Icon(Icons.zoom_in, color: Colors.white),
            onPressed: () {
              setState(() => _zoomLevel = (_zoomLevel + 0.5).clamp(1.0, 5.0));
              _cameraController.setZoomLevel(_zoomLevel);
            },
          ),
          IconButton(
            icon: Icon(Icons.zoom_out, color: Colors.white),
            onPressed: () {
              setState(() => _zoomLevel = (_zoomLevel - 0.5).clamp(1.0, 5.0));
              _cameraController.setZoomLevel(_zoomLevel);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildObjectInfoPanel() {
    if (_objects.isEmpty) {
      return const SizedBox();
    }

    return Positioned(
      bottom: 20,
      left: 20,
      right: 20,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.7),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Detected Objects',
              style: AppTextStyles.headline2.copyWith(
                color: Colors.white,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _objects
                  .map((obj) => Chip(
                        backgroundColor: AppColors.primary.withOpacity(0.2),
                        label: Text(
                          '${obj.labels.first.text} (${(obj.labels.first.confidence * 100).toStringAsFixed(1)}%)',
                          style: TextStyle(color: Colors.white),
                        ),
                      ))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          _buildCameraPreview(),
          _buildDetectionOverlay(),
          _buildZoomControls(),
          _buildObjectInfoPanel(),
          _buildAppBar(),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return Positioned(
      top: MediaQuery.of(context).padding.top,
      left: 0,
      right: 0,
      child: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Object Detection',
          style: AppTextStyles.headline2.copyWith(color: Colors.white),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              Icons.flash_on,
              color: Colors.white,
            ),
            onPressed: _toggleFlash,
          ),
        ],
      ),
    );
  }

  Future<void> _toggleFlash() async {
    try {
      if (_cameraController.value.flashMode == FlashMode.off) {
        await _cameraController.setFlashMode(FlashMode.torch);
      } else {
        await _cameraController.setFlashMode(FlashMode.off);
      }
    } catch (e) {
      debugPrint('Error toggling flash: $e');
    }
  }
}

class ObjectDetectionPainter extends CustomPainter {
  final List<DetectedObject> objects;
  final Size previewSize;

  ObjectDetectionPainter({
    required this.objects,
    required this.previewSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );

    for (final object in objects) {
      // Draw bounding box
      final rect = object.boundingBox;
      paint.color = _getColorForConfidence(object.labels.first.confidence);
      
      canvas.drawRect(
        Rect.fromLTRB(
          rect.left,
          rect.top,
          rect.right,
          rect.bottom,
        ),
        paint,
      );

      // Draw label
      final label = '${object.labels.first.text} ${(object.labels.first.confidence * 100).toStringAsFixed(1)}%';
      final textSpan = TextSpan(
        text: label,
        style: TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.bold,
          background: Paint()..color = Colors.black.withOpacity(0.5),
        ),
      );

      textPainter.text = textSpan;
      textPainter.layout();

      textPainter.paint(
        canvas,
        Offset(
          rect.left,
          rect.top - textPainter.height,
        ),
      );
    }
  }

  Color _getColorForConfidence(double confidence) {
    final int green = (confidence * 255).toInt();
    return Color.fromARGB(255, 255 - green, green, 0);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}