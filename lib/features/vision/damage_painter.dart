import 'package:flutter/material.dart';

class DamagePainter extends CustomPainter {
  final double aiX; 
  final double aiY;
  const DamagePainter({required this.aiX, required this.aiY});

  @override
  void paint(Canvas canvas, Size size) {
    // Konfigurasi "Kuas" Digital
    final paint = Paint()
      ..color = Colors.redAccent
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke; // Garis pinggir saja, bukan blok warna
      
    // Menghitung Dimensi Kotak (Simulasi Pothole RDD-2022)
    // Membuat kotak di tengah layar seluas 50% dari lebar layar
    double boxSize = size.width * 0.45;
    double centerPointX = aiX * size.width;
    double centerPointY = aiY * size.height;
    double left = centerPointX - boxSize / 2;
    double top = centerPointY - boxSize / 2;

    if (left < 0) left = 0;//kiri
    if (left + boxSize > size.width) left = size.width - boxSize;//kanan  
    if (top < 25) top = 25; //atas
    if (top + boxSize > size.height) top = size.height - boxSize;//bawah

    final rect = Rect.fromLTWH(left, top, boxSize, boxSize);
    // Menggambar Kotak ke Kanvas
    canvas.drawRect(rect, paint);
    // Konstruksi Label Tipe Kerusakan
    const textStyle = TextStyle(
      color: Colors.white,
      fontSize: 14,
      fontWeight: FontWeight.bold,
      backgroundColor: Colors.redAccent,
    );

    final textSpan = TextSpan(
      text: " Searching for Road Damage... ", 
      style: textStyle,
    );

    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    );

    // 5. Proses Layouting & Rendering Teks
    textPainter.layout();
    // Gambar teks tepat di atas garis kotak (offset -25 pixel)
    double labelY = (top - 25) > 0 ? top - 25 : top + boxSize + 5;
    textPainter.paint(canvas, Offset(left, labelY));
  }  

  @override
  bool shouldRepaint(covariant DamagePainter oldDelegate) {
    //Kembalikan True jika koordinat AI berubah
    return oldDelegate.aiX != aiX || oldDelegate.aiY != aiY; 
  }
}
