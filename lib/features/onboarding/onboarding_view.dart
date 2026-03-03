import 'package:flutter/material.dart';
import 'package:py4_2c_d3_2024_modul1_066/features/auth/login_view.dart';

class OnboardingView extends StatefulWidget {
  const OnboardingView({super.key});
  @override
  State<OnboardingView> createState() => _OnboardingViewState();
}

class _OnboardingViewState extends State<OnboardingView> {
  int step = 1; //var banyaknya step gambar di onboarding
  final List<String> images = [
    "assets/images/1.jpg",
    "assets/images/2.jpg",
    "assets/images/3.jpg",
  ]; //untuk mengambil aset gambar
  final List<String> descriptions = [
    "Pantau Logbook yang tampil menarik dan mudah dipahami",
    "Mudah digunakan untuk mencatat aktivitas harianmu",
    "Fokus pada aktivitasmu, biar logbook yang urus pencatatan",
  ]; //untuk kata kata onboarding bawah gambar

  //mengatur looping penampilan gambar sesuai step dan mengalihkan ke login
  void nextStep() {
    if (step < 3) {
      setState(() => step++); //menambah step jika kurang dari 3
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginView()),
      ); //jika lebih dari 3 pindahkan dan ganti menjadi halaman login
    }
  }

  //membuat bulat indikator step onboarding
  Widget buildIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (index) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 5),
          width: step == index + 1 ? 14 : 10,
          height: step == index + 1 ? 14 : 10,
          decoration: BoxDecoration(
            color: step == index + 1
                ? const Color.fromARGB(255, 106, 160, 128)
                : Colors.grey.shade300,
            shape: BoxShape.circle,
          ),
        );
      }),
    );
  }

  //membangun tampilan onboarding dengan gambar, deskripsi, indikator, dan tombol lanjut/mulai
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8E7),
      body: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(25),
              child: Image.asset(
                images[step - 1],
                height: 320,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),

            const SizedBox(height: 30),

            Text(
              descriptions[step - 1],
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Color(0xFF4F7C6D),
              ),
            ),

            const SizedBox(height: 30),

            buildIndicator(),

            const SizedBox(height: 40),

            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 106, 160, 128),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 40,
                  vertical: 15,
                ),
              ),
              onPressed: nextStep,
              child: Text(step == 3 ? "Mulai" : "Lanjut"),
            ),
          ],
        ),
      ),
    );
  }
}
