import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'vision_controller.dart';
import 'damage_painter.dart';

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
    // WAJIB: Memutus akses kamera saat pindah halaman
    _visionController.dispose();
    super.dispose();
  }

  Widget _buildVisionStack() {
    return Stack(
      fit: StackFit.expand,
      children: [
        // LAYER 1: Hardware Preview
        // Menggunakan AspectRatio agar gambar tidak gepeng (Koneksi PCD)
        Center(
          child: AspectRatio(
            aspectRatio: 1 / _visionController.controller!.value.aspectRatio,
            child: CameraPreview(_visionController.controller!),
          ),
        ),

        // LAYER 2: Digital Overlay (Canvas)
        // Layer ini transparan dan berada tepat di atas kamera
        Positioned.fill(
          child: CustomPaint(
            painter: DamagePainter(
              aiX: _visionController.mockX, 
              aiY: _visionController.mockY,
            ), // Langkah 4
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Smart-Patrol Vision", style: TextStyle(color: Colors.white)),
        backgroundColor: const Color.fromARGB(255, 106, 160, 128),
        foregroundColor: Colors.white,
      ),
      body: ListenableBuilder(
        listenable: _visionController,
        builder: (context, child) {
          if (_visionController.errorMessage != null) {
            return Center(child: Text(_visionController.errorMessage!, style: const TextStyle(color: Colors.red)));
          }
          // Tampilkan loading jika kamera sedang inisialisasi
          if (!_visionController.isInitialized) {
            return const Center(child: CircularProgressIndicator(color: Color.fromARGB(255, 106, 160, 128)));
          }
          // Lanjut ke struktur Stack di sub-langkah berikutnya
          return _buildVisionStack();
        },
      ),
    );
  }  
}