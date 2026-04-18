import 'package:flutter/material.dart';

class DamagePainter extends CustomPainter {
  final double aiX; 
  final double aiY;
  final String label;
  const DamagePainter({required this.aiX, required this.aiY, required this.label});

  @override
  void paint(Canvas canvas, Size size) {
    Color color;
    String typeName;
    
    if (label == "D40") {
      color = Color.fromARGB(255, 199, 118, 111); typeName = "POTHOLE";
    } else if (label == "D20") {
      color = Color.fromARGB(255, 199, 197, 111); typeName = "ALLIGATOR CRACK";
    } else if (label == "D10") {
      color = Color.fromARGB(255, 111, 199, 126); typeName = "TRANSVERSE CRACK";
    } else {
      color = Color.fromARGB(255, 199, 111, 186); typeName = "LONGITUDINAL CRACK";
    }
    
    // Menghitung Dimensi Kotak
    // Membuat kotak di tengah layar seluas 50% dari lebar layar
    final paint = Paint()..color = color..strokeWidth = 3.0..style = PaintingStyle.stroke;
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
    final textPainter = TextPainter(
      text: TextSpan(
        text: "[$label] $typeName",
        style: TextStyle(
          color: Colors.white, 
          fontSize: 14, 
          fontWeight: FontWeight.bold, 
          backgroundColor: color,
          shadows: const [Shadow(color: Color.fromARGB(200, 0, 0, 0), offset: Offset(1, 1), blurRadius: 3), ]
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
 
    textPainter.paint(canvas, Offset(left, top - 25));
  }  

  @override
  bool shouldRepaint(covariant DamagePainter oldDelegate) {
    //Kembalikan True jika koordinat AI berubah
    return oldDelegate.aiX != aiX || oldDelegate.aiY != aiY || oldDelegate.label != label; 
  }
}
