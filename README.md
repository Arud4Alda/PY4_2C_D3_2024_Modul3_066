# 📸 Smart-Patrol Vision: PCD & OpenCV Explorer
> **Proyek Pengolahan Citra Digital - JTK Polban**

[![Flutter Version](https://img.shields.io/badge/Flutter-3.38.9-blue.svg?logo=flutter)](https://flutter.dev)
[![OpenCV](https://img.shields.io/badge/OpenCV-Dart-green.svg?logo=opencv)](https://pub.dev/packages/opencv_dart)
[![License](https://img.shields.io/badge/License-Academic-orange.svg)]()

Aplikasi mobile berbasis Flutter yang dirancang untuk mengeksplorasi algoritma **Pengolahan Citra Digital (PCD)** secara real-time. Proyek ini mengintegrasikan logika manual Dart dengan kekuatan **OpenCV C++** melalui sistem Isolate untuk performa maksimal tanpa menghambat UI. DAlam aplikasi ini terkandung 2 sistem yaitu pencatatan logbook untuk team juga ada vision patrol yang bisa menangkap gambar dan mensimulasikan pendeteksian objek yang hasil tangkapannya bisa diolah lagi ke berbagai filter dan operasi.

---

## 🚀 Fitur Utama

Aplikasi ini dibagi menjadi tiga kategori utama pemrosesan:

### 1. Operasi Titik (Point Operations)
* **Kecerahan Dinamis:** Penyesuaian intensitas cahaya via Slider.
* **Invers:** Membalikkan nilai warna piksel (Negatif).
* **Grayscale:** Konversi citra menjadi skala abu-abu (Luminance).

### 2. Filter Spasial (Spatial Filtering)
* **Smoothing:** Mean Filter & Gaussian Filter untuk mereduksi noise.
* **Sharpening:** High-pass Filter & Band-pass Filter untuk menonjolkan tepi.
* **Non-Linear:** Median Filter (Sangat efektif untuk *Salt & Pepper Noise*).

### 3. Algoritma Lanjutan (OpenCV Integration)
* **Histogram Spec & Adaptive Hist:** Perataan kontras cerdas (CLAHE).
* **Fourier Transform:** Visualisasi *Magnitude Spectrum* dalam domain frekuensi.
* **Noise Generator:** Simulasi Derau Gaussian, Salt & Pepper, dan Periodik.
* **Histogram Real-time:** Grafik distribusi intensitas piksel secara presisi.

---

## 🛠️ Arsitektur Teknis

Aplikasi ini dibangun dengan prinsip **Single Responsibility Principle (SRP)**:
* **`VisionView`**: Menangani input kamera dan overlay deteksi AI (Mock).
* **`ImageProcessingView`**: Antarmuka untuk manipulasi citra.
* **`ImageProcessingController`**: Otak aplikasi yang menjalankan algoritma berat di **Background Thread (Isolate)** menggunakan fungsi `compute`.



---

## 🔧 Panduan Penginstalan (Manual Setup)

Karena proyek ini menggunakan **OpenCV Dart**, diperlukan konfigurasi **NDK** dan **CMake** manual pada sistem operasi Anda.

### 1. Prasyarat Sistem
* **Flutter SDK:** v3.38.9-stable.
* **Android SDK Command-line Tools.**
* **Android NDK:** v25.1.8937393 atau v28.2.13676358.
* **CMake:** v3.22.1.

### 2. Konfigurasi Environment Variables
Daftarkan path berikut pada System Variables Windows Anda:
* `ANDROID_NDK_HOME` -> `D:\Path\To\Your\android-sdk\ndk\25.1.8937393`
* Tambahkan ke `Path` -> `D:\Path\To\Your\android-sdk\cmake\3.22.1\bin`

### 3. Setup Project
Kloning repositori ini dan masuk ke branch `main`:
```bash
git checkout main
flutter pub get

Jika Anda ingin mencoba proyek ini secara lokal tanpa melakukan `git clone`, Anda dapat mengunduhnya dalam format ZIP:
1. Klik tombol hijau **Code** di bagian kanan atas halaman ini.
2. Pilih menu **Download ZIP**.
3. Ekstrak file ZIP tersebut ke folder di komputer Anda (Disarankan folder tanpa spasi, contoh: `D:\Proyek_PCD\`).

### 4. Sinkronisasi Gradle
Pastikan file android/app/build.gradle memiliki konfigurasi:
android {
    ndkVersion = "25.1.8937393" // Sesuaikan dengan yang terinstal}

### 5. Menjalankan Aplikasi
Buka terminal di folder proyek dan jalankan "Ritual Pembersihan" berikut:
flutter clean
flutter pub get
flutter run


## 👤 Author
**Alda Pujama**
*Mahasiswa Teknik Komputer dan Informatika (JTK)*
**Politeknik Negeri Bandung (Polban)**

---
> **Catatan Pengembangan:**
> Proyek ini dikembangkan di bawah branch `main` sebagai pusat integrasi fitur Pengolahan Citra Digital (PCD) menggunakan OpenCV. Branch lain dalam repositori ini digunakan secara terpisah untuk dokumentasi modul praktikum mingguan.