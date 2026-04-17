import 'package:flutter/material.dart';
import 'package:py4_2c_d3_2024_modul1_066/features/onboarding/onboarding_view.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:py4_2c_d3_2024_modul1_066/services/mongo_service.dart';

void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  final mongoService = MongoService();
  await mongoService.connect();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Logbook',
      theme: ThemeData(
       
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFA8D5BA)),
      ),
      debugShowCheckedModeBanner: false,
      home: const OnboardingView(),
    );
  }
}