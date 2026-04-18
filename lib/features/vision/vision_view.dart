import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'vision_controller.dart';
import 'damage_painter.dart';
import 'package:permission_handler/permission_handler.dart';

class VisionView extends StatefulWidget {
  const VisionView({super.key});
  @override
  State<VisionView> createState() => _VisionViewState();
}

class _VisionViewState extends State<VisionView> {
  // Inisialisasi controller secara lokal untuk halaman ini
  late VisionController _visionController;

  @override
  void initState() {
    super.initState();
    _visionController = VisionController();
  }

  @override
  void dispose() {
    // Memutus akses kamera saat pindah halaman
    _visionController.dispose();
    super.dispose();
  }

  Widget _buildVisionStack() {
    return Column(
      children: [
        // Menggunakan AspectRatio agar gambar tidak gepeng
        Stack(
          children: [
            AspectRatio(
              aspectRatio: 1 / _visionController.controller!.value.aspectRatio,
              child: CameraPreview(_visionController.controller!),
            ),
            if (_visionController.isOverlayVisible)
              Positioned.fill(
                child: CustomPaint(
                  painter: DamagePainter(
                    aiX: _visionController.mockX,
                    aiY: _visionController.mockY,
                    label: _visionController.mockLabel,
                  ), // Langkah 4
                ),
              ),
        // Layer ini transparan dan berada tepat di atas kamera
        Positioned(
          bottom: 15,
          left: 15,
          child: Container(
            decoration: const BoxDecoration(
              color:  Color.fromARGB(255, 106, 160, 128),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: Icon(
                _visionController.isFlashOn ? Icons.flash_on : Icons.flash_off,
                color: _visionController.isFlashOn? Colors.amber : Colors.white,
              ),
              onPressed: () => _visionController.toggleFlash(),
            ),
          ),
        ),
        Positioned(
          bottom: 15,
          right: 15,// SWITCH UNTUK OVERLAY PAINTER
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: const Color.fromARGB(32, 0, 0, 0),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Row(
              children: [
                Icon(
                  _visionController.isOverlayVisible ? Icons.visibility : Icons.visibility_off,
                  color: const Color.fromARGB(255, 106, 160, 128),
                  size: 30,
                ),
                Switch(
                  value: _visionController.isOverlayVisible,
                  activeThumbColor: const Color.fromARGB(255, 255, 255, 255),
                  activeTrackColor: const Color.fromARGB(255, 106, 160, 128),
                  inactiveThumbColor: const Color.fromARGB(255, 106, 160, 128),
                  inactiveTrackColor: const Color.fromARGB(255, 255, 255, 255),
                  onChanged: (value) {
                   _visionController.toggleOverlay();
                  },
                ),
              ],              
            ),
          ),
        ),
      ],
    ),
    ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Smart-Patrol Vision",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color.fromARGB(255, 106, 160, 128),
        foregroundColor: Colors.white,
      ),
      body: ListenableBuilder(
        listenable: _visionController,
        builder: (context, child) {
          if (_visionController.errorMessage != null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.videocam_off, color: Colors.red, size: 60),
                    const SizedBox(height: 16),
                    Text(
                      _visionController.errorMessage!,
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromARGB(255,106,160,128,),
                      ),
                      onPressed: () => openAppSettings(), // Buka settingan HP
                      icon: const Icon(Icons.settings, color: Colors.white),
                      label: const Text(
                        "Open Settings",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }
          // Tampilkan loading jika kamera sedang inisialisasi
          if (!_visionController.isInitialized) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    color: Color.fromARGB(255, 106, 160, 128),
                  ),
                  Text(
                    "Menghubungkan ke Sensor Visual...",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            );
          }
          // Lanjut ke struktur Stack di sub-langkah berikutnya
          return _buildVisionStack();
        },
      ),
    );
  }
}
