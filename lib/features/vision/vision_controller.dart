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
      controller = CameraController(
        cameras[0],
        ResolutionPreset.medium, // Keseimbangan antara akurasi AI & performa
        enableAudio: false,      // Kita hanya butuh visual untuk deteksi jalan
      );

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
      // Menghasilkan nilai acak antara 0.2 hingga 0.8 agar kotak tidak keluar dari layar
      mockX = 0.2 + random.nextDouble() * 0.6;
      mockY = 0.2 + random.nextDouble() * 0.6;
      notifyListeners(); // Beritahu UI untuk digambar ulang di posisi baru
    });
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
