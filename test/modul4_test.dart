import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mongo_dart/mongo_dart.dart';
import 'package:py4_2c_d3_2024_modul1_066/features/logbook/models/log_model.dart';
import 'package:py4_2c_d3_2024_modul1_066/features/logbook/log_controller.dart';
import 'package:py4_2c_d3_2024_modul1_066/services/mongo_service.dart';

// 1. Buat class Mock untuk MongoService
class MockMongoService extends Mock implements MongoService {}
// 2. Buat class Fake untuk LogModel (dibutuhkan Mocktail untuk parameter objek custom)
class FakeLogModel extends Fake implements LogModel {}

void main() {
  late LogController controller;
  late MockMongoService mockMongoService;
  // setUpAll dijalankan sekali sebelum semua test dimulai
  setUpAll(() {
    // Daftarkan fallback value agar fungsi mock yang menerima parameter LogModel bisa bekerja
    registerFallbackValue(FakeLogModel());
    registerFallbackValue(ObjectId());
  });
  // setUp dijalankan setiap kali sebelum test case dimulai (reset state)
  setUp(() {
    mockMongoService = MockMongoService();
    // Inject mock service ke dalam controller
    controller = LogController(mongoService: mockMongoService);
  });

  group('LogController Tests dengan Mocktail', () {    
    test('TC01: Menambahkan log baru harus menambah data ke dalam list logs', () async {
      // setup (arrange)
      // Atur behaviour Mock: Jika insertLog dipanggil dengan parameter apapun (any()), maka return sukses
      when(() => mockMongoService.insertLog(any())).thenAnswer((_) async {});      
      final initialCount = controller.logsNotifier.value.length;      
      // exercise (act)
      await controller.addLog("Rapat", "Pekerjaan", "Rapat proyek A");
      // verify (assert)
      final actualCount = controller.logsNotifier.value.length;
      final actualLog = controller.logsNotifier.value.last;
      expect(actualCount, initialCount + 1, reason: 'Jumlah data harus bertambah 1');
      expect(actualLog.title, "Rapat", reason: 'Title harus "Rapat"');
      expect(actualLog.category, "Pekerjaan", reason: 'Category harus "Pekerjaan"');     
      verify(() => mockMongoService.insertLog(any())).called(1);
    });

    test('TC02: Mengubah data log harus memperbarui data pada index log tersebut', () async {
      // setup (arrange)
      // Atur behaviour Mock
      when(() => mockMongoService.updateLog(any())).thenAnswer((_) async {});      
      // Manipulasi state awal secara langsung (isolasi test)
      final oldLog = LogModel(id: ObjectId(), title: "minum", category: "urgent", description: "kopi", date: "2024-01-01");
      controller.logsNotifier.value = [oldLog];
      // exercise (act)
      await controller.updateLog(oldLog, "Makan", "Pribadi", "Makan siang");
      // verify (assert)
      final index = controller.logsNotifier.value.indexWhere((log) => log.id == oldLog.id);
      final actualLog = controller.logsNotifier.value[index];
      expect(actualLog.title, "Makan", reason: 'Title harus berubah menjadi "Makan"');
      expect(actualLog.category, "Pribadi", reason: 'Category harus berubah menjadi "Pribadi"');
      expect(actualLog.description, "Makan siang", reason: 'Deskripsi harus "Makan siang"');      
      verify(() => mockMongoService.updateLog(any())).called(1);
    });

    test('TC03: Menghapus log yang valid harus mengurangi jumlah data di dalam list', () async {
      // setup (arrange)
      // Atur behaviour Mock (asumsikan deleteLog menerima ID bertipe String atau dynamic)
      when(() => mockMongoService.deleteLog(any())).thenAnswer((_) async {});      
      // Manipulasi state awal secara langsung agar ada data yang bisa dihapus
      final logToRemove = LogModel(id: ObjectId(), title: "Data Dummy", category: "Urgent", description: "Desk", date: "2024-01-01");
      controller.logsNotifier.value = [logToRemove];      
      final initialCount = controller.logsNotifier.value.length;
      // exercise (act)
      await controller.removeLog(logToRemove);
      // verify (assert)
      final actualCount = controller.logsNotifier.value.length;
      expect(actualCount, initialCount - 1, reason: 'Jumlah data harus berkurang 1');
      expect(actualCount, 0, reason: 'Sisa data harus 0 karena awalnya hanya 1');      
      verify(() => mockMongoService.deleteLog(any())).called(1);
    });

  });
}