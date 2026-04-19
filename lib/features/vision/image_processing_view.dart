import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:py4_2c_d3_2024_modul1_066/features/vision/image_processing_controller.dart';

class ImageProcessingPage extends StatefulWidget {
  final String imagePath;
  const ImageProcessingPage({super.key, required this.imagePath});

  @override
  State<ImageProcessingPage> createState() => _ImageProcessingPageState();
}

class _ImageProcessingPageState extends State<ImageProcessingPage> {
  String currentFilter = "Original";
  double brightnessValue = 0.0;
  int selectedIndex = 0;
  late ScrollController _scrollController;
  Uint8List? originalBytes;
  Uint8List? processedBytes;
  bool isProcessing = false;
  final List<Map<String, dynamic>> operations = [
    {"name": "Kecerahan", "icon": Icons.brightness_medium_rounded},
    {"name": "Invers", "icon": Icons.invert_colors_rounded},
    {"name": "Grayscale", "icon": Icons.gradient_rounded},
    {"name": "Histogram Spec", "icon": Icons.bar_chart_rounded},
    {"name": "Adaptive Hist", "icon": Icons.auto_fix_high},
    {"name": "Mean Filter", "icon": Icons.blur_on_rounded},
    {"name": "Gaussian Filter", "icon": Icons.blur_circular_rounded},
    {"name": "High Filter", "icon": Icons.filter_center_focus_rounded},
    {"name": "Bandpass Filter", "icon": Icons.waves_rounded},
    {"name": "Median Filter", "icon": Icons.grid_view_rounded},
    {"name": "Fourier", "icon": Icons.transform_rounded},
    {"name": "Salt & Pepper", "icon": Icons.grain_rounded},
    {"name": "Derau Gaussian", "icon": Icons.blur_linear_rounded},
    {"name": "Derau Periodik", "icon": Icons.calendar_view_week_rounded},
    {"name": "Histogram", "icon": Icons.analytics_outlined},
  ];

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    originalBytes = File(widget.imagePath).readAsBytesSync();
    processedBytes = originalBytes;
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // Fungsi untuk mengatur klik dan menggeser menu ke tengah
  void _onItemTapped(int index, double itemWidth) {
    setState(() {
      selectedIndex = index;
      if (index == 0) {
        currentFilter = "Kecerahan (${brightnessValue.toInt()})";
      } else {
        currentFilter = operations[index]['name'];
      }
    });    
    // Animasi geser ke tengah
    _scrollController.animateTo(
      index * itemWidth,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
    String opName = operations[index]['name'];
    _processImage(opName, brightnessValue);
  }

  Future<void> _processImage(String operation, [double value = 0.0]) async {
    if (originalBytes == null || operation == "Original") {
      setState(() {
        processedBytes = originalBytes;
        isProcessing = false;
      });
      return;
    }
    setState(() => isProcessing = true); // Munculkan indikator loading
    try {
      // Menjalankan fungsi runImageProcessing di Thread Latar Belakang
      final result = await compute(
        runImageProcessing,
        ProcessRequest(
          imageBytes: originalBytes!,
          operation: operation,
          value: value,
        ),
      );
      setState(() {
        processedBytes = result; // Update gambar di layar
        isProcessing = false;    // Matikan loading
      });
    } catch (e) {
      setState(() => isProcessing = false);
      print("Gagal memproses citra: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double itemWidth = screenWidth / 5;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Pengolahan Citra",style: TextStyle(color: Colors.white),),
        backgroundColor: const Color.fromARGB(255, 106, 160, 128),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: "Reset ke Original",
            onPressed: () {
              setState(() {
                currentFilter = "Original";
                brightnessValue = 0.0;
                _onItemTapped(0, itemWidth);
              });
            },
          ),
        ],
      ),
      backgroundColor: const Color(0xFFFFF8E7), // Warna background krem
      body: Column(
        //mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Menampilkan gambar yang baru saja difoto
          Container(
            margin: const EdgeInsets.all(16),
            width: double.infinity,
            // decoration: BoxDecoration(
            //   border: Border.all(color: Colors.grey, width: 2),
            //   borderRadius: BorderRadius.circular(12),
            // ),
            child: AspectRatio(
              aspectRatio: 3 / 4,
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: const Color.fromARGB(59, 234, 231, 231),
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  //boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 4))],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (processedBytes != null)
                        Image.memory(processedBytes!, fit: BoxFit.cover),// Menampilkan Byte dari Memori, bukan File lagi
                      if (isProcessing)
                              Container(
                                color: Colors.black45,
                                child: const Center(
                                  child: CircularProgressIndicator(color: Colors.white),// Indikator Loading Transparan di tengah gambar
                                ),
                              ),
                      Positioned(
                        top: 12,
                        right: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: const Color.fromARGB(53,0,0,0,), // Semi-transparan agar terbaca
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            " $currentFilter ",
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ), 
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          //horizontal menu
          SizedBox(
            height: 100,
            child: ListView.builder(
              controller: _scrollController,
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.symmetric(horizontal: (screenWidth - itemWidth) / 2),
              itemCount: operations.length,
              itemBuilder: (context, index) {
                bool isSelected = selectedIndex == index;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      selectedIndex = index;
                      currentFilter = operations[index]['name'];
                      _onItemTapped(index, itemWidth);
                    });
                  },
                  child: SizedBox(
                    width: itemWidth,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          operations[index]['name'],
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: isSelected
                                ? const Color.fromARGB(255, 106, 160, 128)
                                : Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color.fromARGB(255, 106, 160, 128)
                                : Colors.grey.shade100,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            operations[index]['icon'],
                            color: Colors.white,
                            size: 26,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          // slider
          SizedBox(
              height: 90, 
              child: selectedIndex == 0
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          " ${brightnessValue.toInt()} ",
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Color.fromARGB(255, 106, 160, 128)),
                        ),
                        Slider(
                          value: brightnessValue,
                          min: -100,
                          max: 100,
                          activeColor: const Color.fromARGB(255, 106, 160, 128),
                          inactiveColor: const Color.fromARGB(100, 106, 160, 128),
                          onChanged: (val) {
                            setState(() {
                              brightnessValue = val;
                              currentFilter = "Kecerahan (${val.toInt()})";
                            });
                          },
                          onChangeEnd: (val) {
                            _processImage("Kecerahan", val);
                          },
                        ),
                      ],
                    )
                  : const SizedBox.shrink(), // Kosong jika menu lain dipilih
            ),
            const SizedBox(height: 10),
        ],
      ),
    );
  }
}
