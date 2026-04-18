import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:async';

class VisionController extends ChangeNotifier with WidgetsBindingObserver {
  CameraController? controller;
  bool isInitialized = false;
  String? errorMessage;
  Timer? _mockTimer;
  double mockX = 0.5; 
  double mockY = 0.5;
  String mockLabel = "D40"; 
  bool isFlashOn = false;
  bool isOverlayVisible = true;

  VisionController() {
    // Mendaftarkan observer agar bisa memantau status aplikasi (Lifecycle)
    WidgetsBinding.instance.addObserver(this);
    initCamera();
  }

  Future<void> initCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        errorMessage = "No camera detected on device.";
        notifyListeners();
        return;
      }
      // Memilih Kamera Belakang (Index 0)
      controller = CameraController(cameras[0],ResolutionPreset.medium,enableAudio: false,);
      await controller!.initialize();
      isInitialized = true;
      errorMessage = null;
      startMockDetection();
    } catch (e) {
      errorMessage = "Failed to initialize camera: $e";
    }
    notifyListeners();
  }

  void startMockDetection() {
    _mockTimer?.cancel(); 
    _mockTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final random = Random();
      // Menghasilkan nilai acak
      mockX = 0.2 + random.nextDouble() * 0.6;
      mockY = 0.2 + random.nextDouble() * 0.6;
      List<String> labels = ["D00", "D10", "D20", "D40"];
      mockLabel = labels[random.nextInt(labels.length)];
      notifyListeners(); // Beritahu UI untuk digambar ulang di posisi baru
    });
  }

  void toggleOverlay() {
    isOverlayVisible = !isOverlayVisible;
    notifyListeners();
  }

  Future<void> toggleFlash() async {
    if (controller == null || !controller!.value.isInitialized) return;
    try {
      isFlashOn = !isFlashOn;
      await controller!.setFlashMode(isFlashOn ? FlashMode.torch : FlashMode.off,);
      notifyListeners();
    } catch (e) {
      print("Gagal menyalakan senter: $e");
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final CameraController? cameraController = controller;
    // Jika controller belum ada atau belum siap, abaikan
    if (cameraController == null || !cameraController.value.isInitialized) {
      return;
    }
    if (state == AppLifecycleState.inactive) {
      _mockTimer?.cancel();
      cameraController.dispose();
      isInitialized = false;
      notifyListeners();
    } else if (state == AppLifecycleState.resumed) {
      // Menginisialisasi ulang saat pengguna kembali ke aplikasi
      initCamera();
    }
  }

  @override
  void dispose() {
    _mockTimer?.cancel();
    // Menghapus observer agar tidak terjadi memory leak
    WidgetsBinding.instance.removeObserver(this);
    controller?.dispose();
    super.dispose();
  }
}
