import 'package:flutter/material.dart';
import 'package:py4_2c_d3_2024_modul1_066/features/onboarding/onboarding_view.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:py4_2c_d3_2024_modul1_066/services/mongo_service.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:py4_2c_d3_2024_modul1_066/features/logbook/models/log_model.dart';

void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  await Hive.initFlutter();
  // INIT HIVE
  await Hive.initFlutter();
  Hive.registerAdapter(LogModelAdapter());
  await Hive.openBox<LogModel>('offline_logs');
  // mongo
  final mongoService = MongoService();
  await mongoService.connect();
  print("DATABASE: ${mongoService.getDatabaseName()}");
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

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