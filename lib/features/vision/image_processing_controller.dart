import 'dart:typed_data';
import 'package:image/image.dart' as img;
import 'package:opencv_dart/opencv_dart.dart' as cv;

// Objek untuk mengirim pesanan dari UI ke Isolate 
class ProcessRequest {
  final Uint8List imageBytes;
  final String operation;
  final double value;

  ProcessRequest({
    required this.imageBytes,
    required this.operation,
    this.value = 0.0,
  });
}

Future<Uint8List?> runImageProcessing(ProcessRequest request) async {
  String op = request.operation;
  List<String> cvOperations = [
    "Histogram Spec", "Adaptive Hist", "Fourier", 
    "Salt & Pepper", "Derau Gaussian", "Derau Periodik", "Buat Histogram"
  ];
  if (cvOperations.contains(op)) {
    // Decode gambar ke format Matriks OpenCV 
    cv.Mat src = cv.imdecode(request.imageBytes, cv.IMREAD_COLOR);
    cv.Mat dst = src.clone();
    try {
          if (op == "Histogram Spec") {
            cv.Mat ycrcb = cv.cvtColor(src, cv.COLOR_BGR2YCrCb);
            cv.VecMat channels = cv.split(ycrcb);
            channels[0] = cv.equalizeHist(channels[0]); 
            cv.Mat merged = cv.merge(channels);
            dst = cv.cvtColor(merged, cv.COLOR_YCrCb2BGR);
          } 
          
          else if (op == "Adaptive Hist") {
            cv.Mat ycrcb = cv.cvtColor(src, cv.COLOR_BGR2YCrCb);
            cv.VecMat channels = cv.split(ycrcb);
            
            var clahe = cv.createCLAHE(clipLimit: 2.0, tileGridSize: (8, 8)); // Batas kontras, Dibagi jadi blok 8x8 
            channels[0] = clahe.apply(channels[0]);
            
            cv.Mat merged = cv.merge(channels);
            dst = cv.cvtColor(merged, cv.COLOR_YCrCb2BGR);
          }

          else if (op == "Derau Gaussian") {
            // Menambahkan bintik-bintik derau dengan distribusi normal Gaussian 
            cv.Mat noise = cv.Mat.zeros(src.rows, src.cols, src.type);
            cv.randn(noise, cv.Scalar.all(0), cv.Scalar.all(50)); // mean 0, std 50
            cv.add(src, noise, dst: dst);
          }

          else if (op == "Salt & Pepper") {
            // Menambahkan bintik hitam (pepper) dan putih (salt) secara acak 
            cv.Mat noise = cv.Mat.zeros(src.rows, src.cols, cv.MatType.CV_8UC1);
            cv.randu(noise, cv.Scalar(0, 0, 0, 0), cv.Scalar(255, 255, 255, 0));
            
            cv.Mat maskSalt = cv.Mat.empty();
            cv.threshold(noise, 245, 255, cv.THRESH_BINARY, dst: maskSalt);
            
            cv.Mat maskPepper = cv.Mat.empty();
            cv.threshold(noise, 10, 255, cv.THRESH_BINARY_INV, dst: maskPepper);

            cv.Mat black = cv.Mat.zeros(src.rows, src.cols, src.type);
            cv.Mat white = cv.Mat.zeros(src.rows, src.cols, src.type);
            white.setTo(cv.Scalar.all(255));
            
            src.copyTo(dst);
            white.copyTo(dst, mask: maskSalt);
            black.copyTo(dst, mask: maskPepper);
          }

          else if (op == "Fourier") {
            // Transformasi ke Domain Frekuensi             
            cv.Mat gray = cv.cvtColor(src, cv.COLOR_BGR2GRAY);// Convert to Grayscale 
            cv.Mat floatGray = gray.convertTo(cv.MatType.CV_32FC1);  //Convert ke Float32 karena perhitungan frekuensi butuh desimal
            cv.Mat zeros = cv.Mat.zeros(floatGray.rows, floatGray.cols, cv.MatType.CV_32FC1);//Siapkan Matriks Kompleks
            cv.Mat complexI = cv.merge(cv.VecMat.fromList([floatGray, zeros]));

            cv.dft(complexI, dst: complexI, flags: cv.DFT_COMPLEX_OUTPUT); //Transformasi Fourier

            cv.VecMat planes = cv.split(complexI); 
            cv.Mat magI = cv.magnitude(planes[0], planes[1]); //Hitung Magnitude/Amplitudo

            cv.Mat ones = cv.Mat.zeros(magI.rows, magI.cols, cv.MatType.CV_32FC1);
            ones.setTo(cv.Scalar(1.0, 1.0, 1.0, 1.0));

            cv.add(magI, ones, dst: magI); //Skala Logaritmik
            cv.log(magI, dst: magI);
            magI = magI.region(cv.Rect(0, 0, magI.cols & -2, magI.rows & -2));//Potong matriks agar ukurannya genap
            
            int cx = magI.cols ~/ 2;//Memindahkan frekuensi rendah
            int cy = magI.rows ~/ 2;//Memindahkan frekuensi rendah
            
            cv.Mat q0 = magI.region(cv.Rect(0, 0, cx, cy));   // Kiri Atas
            cv.Mat q1 = magI.region(cv.Rect(cx, 0, cx, cy));  // Kanan Atas
            cv.Mat q2 = magI.region(cv.Rect(0, cy, cx, cy));  // Kiri Bawah
            cv.Mat q3 = magI.region(cv.Rect(cx, cy, cx, cy)); // Kanan Bawah

            cv.Mat tmp = q0.clone();// Tukar Kiri Atas dengan Kanan Bawah
            q3.copyTo(q0);
            tmp.copyTo(q3);

            tmp = q1.clone();// Tukar Kanan Atas dengan Kiri Bawah
            q2.copyTo(q1);
            tmp.copyTo(q2);
            
            cv.normalize(magI, magI, alpha: 0, beta: 255, normType: cv.NORM_MINMAX);//Normalisasi Spektrum Magnitude agar bisa dilihat mata
            
            cv.Mat finalMag = magI.convertTo(cv.MatType.CV_8UC1); //kembalikan ke format 8-bit dan BGR
            dst = cv.cvtColor(finalMag, cv.COLOR_GRAY2BGR);
          }

          else if (op == "Buat Histogram") {
            // Membuat grafik Histogram menggunakan OpenCV 
            cv.Mat gray = cv.cvtColor(src, cv.COLOR_BGR2GRAY);
            cv.Mat hist = cv.calcHist(cv.VecMat.fromList([gray]), cv.VecI32.fromList([0]), cv.Mat.empty(), cv.VecI32.fromList([256]), cv.VecF32.fromList([0, 256]));
            
            // Gambar kanvas hitam
            int histW = 512, histH = 400;
            dst = cv.Mat.zeros(histH, histW, cv.MatType.CV_8UC3);
            
            // Normalisasi data histogram agar pas di layar
            cv.normalize(hist, hist, alpha: 0, beta: histH.toDouble(), normType: cv.NORM_MINMAX);
            
            // Gambar garis
            for (int i = 1; i < 256; i++) {
              cv.line(
                dst, 
                cv.Point((i - 1) * 2, histH - hist.at<double>(i - 1,0).round()), 
                cv.Point(i * 2, histH - hist.at<double>(i,0).round()), 
                cv.Scalar(255, 255, 255), 
                thickness: 2
              );
            }
          }

          // Encode kembali ke JPG
          var (success, encoded) = cv.imencode(".jpg", dst);
          if (success) return encoded;

        } catch (e) {
          print("OpenCV Error: $e");
          return null;
        }
    }
    else {
      img.Image? image = img.decodeImage(request.imageBytes); //  Decode gambar mentah (JPG) menjadi bentuk Matriks 2D (Piksel)
      if (image == null) return null;
      img.Image result = image.clone();   // Kita buat salinan gambarnya asli

      if (request.operation.contains ("Kecerahan")) {
        int val = request.value.toInt();
        for (var p in result) {
          p.r = (p.r + val).clamp(0, 255);
          p.g = (p.g + val).clamp(0, 255);
          p.b = (p.b + val).clamp(0, 255);
        }
      } 
      else if (request.operation == "Invers") {
        for (var p in result) {
          p.r = 255 - p.r;
          p.g = 255 - p.g;
          p.b = 255 - p.b;
        }
      } 
      else if (request.operation == "Grayscale") {
        for (var p in result) {
          num gray = (0.299 * p.r) + (0.587 * p.g) + (0.114 * p.b);
          p.r = gray;
          p.g = gray;
          p.b = gray;
        } 
      }
      else if (request.operation == "Mean Filter") {
        List<List<int>> kernel = [
          [1, 1, 1],
          [1, 1, 1],
          [1, 1, 1]
        ];
        result = applyConvolution(image, kernel, 9);
      } 
      else if (request.operation == "Gaussian Filter") {
        List<List<int>> kernel = [
          [1, 1, 1],
          [1, 1, 1],
          [1, 1, 1]
        ];
        result = applyConvolution(image, kernel, 9);
      } 
      else if (request.operation == "High Filter") {
        List<List<int>> kernel = [
          [0, -1, 0],
          [-1, 4, -1],
          [0, -1, 0]
        ];
        result = applyConvolution(image, kernel, 1);
      } 
      else if (request.operation == "Bandpass Filter") {
        List<List<int>> kernel = [
          [0, -1, 0],
          [-1, 5, -1],
          [0, -1, 0]
        ];
        result = applyConvolution(image, kernel, 1);
      } 
      else if (request.operation == "Median Filter") {
        result = applyMedianFilter(image);
      }
      return img.encodeJpg(result, quality: 85);//Ubah kembali matriks piksel menjadi file JPG untuk dikirim ke UI
    }
  return null;
}

img.Image applyConvolution(img.Image src, List<List<int>> kernel, int divisor) {
  img.Image dst = src.clone();
  int w = src.width;
  int h = src.height;
  int kSize = kernel.length;
  int offset = kSize ~/ 2;

  for (int y = 0; y < h; y++) {
    for (int x = 0; x < w; x++) {
      int r = 0, g = 0, b = 0;

      // Iterasi Kernel (Jendela 3x3)
      for (int ky = 0; ky < kSize; ky++) {
        for (int kx = 0; kx < kSize; kx++) {
          int px = x + kx - offset;
          int py = y + ky - offset;

          // Same Padding: Jika keluar batas, gunakan piksel paling pinggir
          px = px.clamp(0, w - 1).toInt();
          py = py.clamp(0, h - 1).toInt();

          var p = src.getPixel(px, py);
          int weight = kernel[ky][kx];

          r += (p.r * weight).toInt();
          g += (p.g * weight).toInt();
          b += (p.b * weight).toInt();
        }
      }
      // Memasukkan nilai baru dengan pembagi dan mencegah nilai di luar 0-255
      dst.setPixelRgba(x, y, 
        (r ~/ divisor).clamp(0, 255), 
        (g ~/ divisor).clamp(0, 255), 
        (b ~/ divisor).clamp(0, 255), 
        255
      );
    }
  }
  return dst;
}

img.Image applyMedianFilter(img.Image src) {
  img.Image dst = src.clone();
  int w = src.width;
  int h = src.height;

  for (int y = 0; y < h; y++) {
    for (int x = 0; x < w; x++) {
      List<int> rs = [], gs = [], bs = [];

      for (int ky = -1; ky <= 1; ky++) {
        for (int kx = -1; kx <= 1; kx++) {
          int px = (x + kx).clamp(0, w - 1).toInt();
          int py = (y + ky).clamp(0, h - 1).toInt();

          var p = src.getPixel(px, py);
          rs.add(p.r.toInt());
          gs.add(p.g.toInt());
          bs.add(p.b.toInt());
        }
      }
      // Mengurutkan nilai ketetanggaan (Sorting)
      rs.sort(); gs.sort(); bs.sort();
      // Mengambil nilai tengah (indeks ke-4 dari 9 elemen) 
      dst.setPixelRgba(x, y, rs[4], gs[4], bs[4], 255);
    }
  }
  return dst;
}