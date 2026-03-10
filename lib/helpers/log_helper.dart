import 'dart:developer' as dev;
import 'package:intl/intl.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class LogHelper {static Future<void> writeLog(String message, {String source = "Unknown", int level = 3,}) async 
{
    final logLevel = int.parse(dotenv.env['LOG_LEVEL'] ?? '0');
    //final int configLevel = int.tryParse(dotenv.env['LOG_LEVEL'] ?? '2') ?? 2;
    final String muteSource = dotenv.env['LOG_MUTE'] ?? '';
    // cek apakah source dimute
    if (muteSource.isNotEmpty && source.contains(muteSource)) {
      return;
    }
    if (level > logLevel) return;

    try {
      String timestamp = DateFormat('HH:mm:ss').format(DateTime.now());
      String label = _getLabel(level);
      String color = _getColor(level);
      dev.log(message, name: source, time: DateTime.now(), level: level * 100);
      print('$color[$timestamp][$label][$source] -> $message\x1B[0m');
    } catch (e) {
      dev.log("Logging failed: $e", name: "SYSTEM", level: 1000);
    }
  }

  static String _getLabel(int level) {
    switch (level) {
      case 1:
        return "ERROR";
      case 2:
        return "INFO";
      case 3:
        return "VERBOSE";
      default:
        return "LOG";
    }
  }

  static String _getColor(int level) {
    switch (level) {
      case 1:
        return '\x1B[31m'; 
      case 2:
        return '\x1B[32m'; 
      case 3:
        return '\x1B[34m'; 
      default:
        return '\x1B[0m';
    }
  }
}
