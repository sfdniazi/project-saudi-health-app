import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';
import 'package:permission_handler/permission_handler.dart';

/// 🎯 MLKit Service for barcode scanning and food data processing
class MLKitService {
  static MLKitService? _instance;
  static MLKitService get instance => _instance ??= MLKitService._();
  MLKitService._();

  BarcodeScanner? _barcodeScanner;
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _isInitialized = false;

  /// 🎯 Initialize camera and ML Kit components
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Initialize barcode scanner
      _barcodeScanner = BarcodeScanner(formats: [
        BarcodeFormat.ean13,
        BarcodeFormat.ean8,
        BarcodeFormat.upca,
        BarcodeFormat.upce,
        BarcodeFormat.code128,
        BarcodeFormat.code39,
        BarcodeFormat.qrCode,
      ]);

      // Get available cameras
      _cameras = await availableCameras();
      _isInitialized = true;
    } catch (e) {
      debugPrint('MLKitService initialization error: $e');
      rethrow;
    }
  }

  /// 🎯 Request camera permission
  Future<bool> requestCameraPermission() async {
    final status = await Permission.camera.request();
    return status == PermissionStatus.granted;
  }

  /// 🎯 Start camera for barcode scanning
  Future<CameraController?> startCamera() async {
    if (_cameras == null || _cameras!.isEmpty) {
      throw Exception('No cameras available');
    }

    final hasPermission = await requestCameraPermission();
    if (!hasPermission) {
      throw Exception('Camera permission denied');
    }

    // Use back camera if available
    final camera = _cameras!.firstWhere(
      (camera) => camera.lensDirection == CameraLensDirection.back,
      orElse: () => _cameras!.first,
    );

    _cameraController = CameraController(
      camera,
      ResolutionPreset.medium,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.nv21, // Optimal for ML Kit
    );

    await _cameraController!.initialize();
    return _cameraController;
  }

  /// 🎯 Scan barcode from camera image
  Future<String?> scanBarcodeFromImage(CameraImage image) async {
    if (_barcodeScanner == null) {
      throw Exception('Barcode scanner not initialized');
    }

    try {
      // Convert CameraImage to InputImage for ML Kit
      final inputImage = _convertCameraImage(image);
      final barcodes = await _barcodeScanner!.processImage(inputImage);

      if (barcodes.isNotEmpty) {
        // Return the first detected barcode value
        return barcodes.first.rawValue;
      }
      return null;
    } catch (e) {
      debugPrint('Barcode scanning error: $e');
      return null;
    }
  }

  /// 🎯 Convert CameraImage to InputImage for ML Kit processing
  InputImage _convertCameraImage(CameraImage image) {
    final bytes = _concatenatePlanes(image.planes);
    final Size imageSize = Size(image.width.toDouble(), image.height.toDouble());
    const InputImageRotation rotation = InputImageRotation.rotation0deg;
    final InputImageFormat format = _getInputImageFormat(image.format.group);

    return InputImage.fromBytes(
      bytes: bytes,
      metadata: InputImageMetadata(
        size: imageSize,
        rotation: rotation,
        format: format,
        bytesPerRow: image.planes.first.bytesPerRow,
      ),
    );
  }

  /// 🎯 Helper method to concatenate image plane data
  Uint8List _concatenatePlanes(List<Plane> planes) {
    final WriteBuffer allBytes = WriteBuffer();
    for (final Plane plane in planes) {
      allBytes.putUint8List(plane.bytes);
    }
    return allBytes.done().buffer.asUint8List();
  }

  /// 🎯 Get InputImageFormat from ImageFormatGroup
  InputImageFormat _getInputImageFormat(ImageFormatGroup format) {
    switch (format) {
      case ImageFormatGroup.nv21:
        return InputImageFormat.nv21;
      case ImageFormatGroup.yuv420:
        return InputImageFormat.yuv420;
      default:
        return InputImageFormat.nv21;
    }
  }

  /// 🎯 Get mock food data for barcode (placeholder implementation)
  Map<String, dynamic> getFoodDataForBarcode(String barcode) {
    // 🎯 Mock food database - in production, connect to real food API
    final mockFoodDatabase = {
      '0123456789012': {
        'name': 'Organic Whole Wheat Bread',
        'calories': 69,
        'protein': 3.6,
        'carbs': 12.8,
        'fat': 1.2,
        'brand': 'Nature\'s Best',
        'serving': '1 slice (28g)',
      },
      '1234567890123': {
        'name': 'Greek Yogurt Plain',
        'calories': 59,
        'protein': 10.0,
        'carbs': 3.6,
        'fat': 0.4,
        'brand': 'Premium Dairy',
        'serving': '100g',
      },
      '2345678901234': {
        'name': 'Banana',
        'calories': 89,
        'protein': 1.1,
        'carbs': 22.8,
        'fat': 0.3,
        'brand': 'Fresh Produce',
        'serving': '1 medium (118g)',
      },
      '3456789012345': {
        'name': 'Chicken Breast Grilled',
        'calories': 165,
        'protein': 31.0,
        'carbs': 0.0,
        'fat': 3.6,
        'brand': 'Premium Poultry',
        'serving': '100g',
      },
      '4567890123456': {
        'name': 'Brown Rice',
        'calories': 111,
        'protein': 2.6,
        'carbs': 22.8,
        'fat': 0.9,
        'brand': 'Healthy Grains',
        'serving': '100g cooked',
      },
    };

    // Return mock data if barcode exists, otherwise return unknown food
    return mockFoodDatabase[barcode] ?? {
      'name': 'Unknown Food Item',
      'calories': 0,
      'protein': 0.0,
      'carbs': 0.0,
      'fat': 0.0,
      'brand': 'Unknown',
      'serving': 'N/A',
    };
  }

  /// 🎯 Stop camera and release resources
  Future<void> stopCamera() async {
    await _cameraController?.dispose();
    _cameraController = null;
  }

  /// 🎯 Dispose of all resources
  void dispose() {
    _barcodeScanner?.close();
    _cameraController?.dispose();
    _barcodeScanner = null;
    _cameraController = null;
    _isInitialized = false;
  }

  /// 🎯 Check if service is initialized
  bool get isInitialized => _isInitialized;

  /// 🎯 Get camera controller
  CameraController? get cameraController => _cameraController;
}
