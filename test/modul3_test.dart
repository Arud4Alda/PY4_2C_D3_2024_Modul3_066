import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:py4_2c_d3_2024_modul1_066/features/logbook/models/log_model.dart';
import 'package:py4_2c_d3_2024_modul1_066/features/logbook/log_controller.dart'; 

void main() {
  group('LogController Tests - SharedPreferences & Filter', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });
    test('TC01: saveToDisk() - Menyimpan data log ke dalam memori perangkat (SharedPreferences)', () async {
      // setup (arrange, build)
      final controller = LogController();
      controller.addLog("percobaan", "Pribadi", "isi");
      // exercise (act, operate)
      await controller.saveToDisk();
      // verify (assert, check)
      final prefs = await SharedPreferences.getInstance();
      final String? jsonString = prefs.getString('user_logs_data');
      expect(jsonString, isNotNull, reason: 'Data JSON di SharedPreferences tidak boleh null');
      expect(jsonString!.contains('percobaan'), isTrue, reason: 'JSON harus mengandung judul "percobaan"');
      expect(jsonString.contains('Pribadi'), isTrue, reason: 'JSON harus mengandung kategori "Pribadi"');
    });

    test('TC02: loadLogs() - Memuat data log dari memori perangkat (SharedPreferences) ke dalam list', () async {
      // setup (arrange, build)
      final mockJson = '[{"title":"Test Load", "category":"Urgent", "description":"Load data", "date":"2024-01-01"}]';
      SharedPreferences.setMockInitialValues({
        'user_logs_data': mockJson
      });
      final controller = LogController();
      // exercise (act, operate)
      await controller.loadLogs();
      // verify (assert, check)
      final actualLogsCount = controller.logsNotifier.value.length;
      expect(actualLogsCount, 1, reason: 'logsNotifier harus berisi 1 data dari SharedPreferences');
      final actualFilteredCount = controller.filteredLogs.value.length;
      expect(actualFilteredCount, 1, reason: 'filteredLogs juga harus berisi 1 data');
      expect(controller.logsNotifier.value.first.title, "Test Load");
      expect(controller.logsNotifier.value.first.category, "Urgent");
    });

    test('TC03: _applyfilter() - Memfilter list data yang ditampilkan berdasarkan judul pencarian (query)', () {
      // setup (arrange, build)
      final controller = LogController();
      controller.logsNotifier.value = [
        LogModel(title: "Rapat A", category: "Pekerjaan", description: "desc", date: "2024-01-01"),
        LogModel(title: "Makan Siang", category: "Pribadi", description: "desc", date: "2024-01-01"),
        LogModel(title: "rapat B", category: "Pekerjaan", description: "desc", date: "2024-01-01"),
      ];
      // exercise (act, operate)
      controller.searchLog("rapat");
      // verify (assert, check)
      final filteredList = controller.filteredLogs.value;
      expect(filteredList.length, 2, reason: 'Hanya boleh ada 2 data yang mengandung kata "rapat"');
      final isMakanSiangExist = filteredList.any((log) => log.title == "Makan Siang");
      expect(isMakanSiangExist, false, reason: 'Data "Makan Siang" tidak boleh ada di list hasil pencarian');
    });
  });
}