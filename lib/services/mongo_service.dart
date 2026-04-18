import 'package:mongo_dart/mongo_dart.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:py4_2c_d3_2024_modul1_066/features/logbook/models/log_model.dart';
import 'package:py4_2c_d3_2024_modul1_066/helpers/log_helper.dart';

class MongoService {
  static final MongoService _instance = MongoService._internal();
  Db? _db;
  DbCollection? _collection;
  final String _source = "mongo_service.dart";

  factory MongoService() {
    return _instance;
  }
  MongoService._internal();

  // Fungsi Internal untuk memastikan koleksi siap digunakan (Anti-LateInitializationError)
  Future<DbCollection> _getSafeCollection() async {
    if (_db == null || !_db!.isConnected || _collection == null) {
      await LogHelper.writeLog(
        "INFO: Koleksi belum siap, mencoba rekoneksi...",
        source: _source,
        level: 3,
      );
      await connect();
    }
    return _collection!;
  }

  //inisiasi koneksi ke mongodb atlas
  Future<void> connect() async {
    await LogHelper.writeLog(
      "Mencoba koneksi MongoDB Atlas",
      source: "mongo_service.dart",
    );
    try{
    if (_db != null && _db!.isConnected) {
      return;
    }
    final uri = dotenv.env['MONGODB_URI'];
    if (uri == null) {
      throw Exception("MONGODB_URI tidak ditemukan di file .env");
    }

    _db = await Db.create(uri);
    await _db!.open().timeout(
      const Duration(seconds: 15),
      onTimeout: () {
        throw Exception("Koneksi MongoDB timeout");
      },
    );
    if (!_db!.isConnected) {
      throw Exception(
        "Koneksi Timeout. Cek IP Whitelist (0.0.0.0/0) atau Sinyal HP.",
      );
    }

    _collection = _db!.collection('logs');

      await LogHelper.writeLog(
        "DATABASE: Terhubung & Koleksi Siap",
        source: _source,
        level: 2,
      );
    } catch (e) {
      await LogHelper.writeLog(
        "DATABASE: Gagal Koneksi - $e",
        source: _source,
        level: 1,
      );
      rethrow;
    }

  }

  String? getDatabaseName() {
  return _db?.databaseName;
  }

  Future<void> close() async {
    if (_db != null && _db!.isConnected) {
      await _db!.close();
      await LogHelper.writeLog(
        "DATABASE: Koneksi ditutup",
        source: _source,
        level: 2,
      );
    }
  }

  
  /// CREATE: Menambahkan data baru
  Future<String?> insertLog(LogModel log) async 
  {
    try {
      final collection = await _getSafeCollection();
      final result = await collection.insertOne(log.toMap());
      
      await LogHelper.writeLog(
        "SUCCESS: Data '${log.title}' Saved to Cloud",
        source: _source,
        level: 2,
      );
      return result.id?.toString();
    } catch (e) {
      await LogHelper.writeLog(
        "ERROR: Insert Failed - $e",
        source: _source,
        level: 1,
      );
      rethrow;
    }
  }

  Future<List<LogModel>> getLogs(String teamId) async 
  {
    try {
      final collection = await _getSafeCollection(); 

      await LogHelper.writeLog(
        "INFO: Fetching data for Team: $teamId",
        source: _source,
        level: 3,
      );

      final List<Map<String, dynamic>> data = await collection
          .find(where.eq('teamId', teamId))
          .toList();
      return data.map((json) => LogModel.fromMap(json)).toList();
    } catch (e) {
      await LogHelper.writeLog(
        "ERROR: Fetch Failed - $e",
        source: _source,
        level: 1,
      );
      return [];
    }
  }
  /// UPDATE: Memperbarui data berdasarkan ID
  Future<void> updateLog(LogModel log) async 
  {
    try {
      final collection = await _getSafeCollection();
      if (log.id == null)
      throw Exception("ID Log tidak ditemukan untuk update");

      await collection.replaceOne(where.id(ObjectId.fromHexString(log.id!)), log.toMap());

      await LogHelper.writeLog(
        "DATABASE: Update '${log.title}' Berhasil",
        source: _source,
        level: 2,
      );
    } catch (e) {
      await LogHelper.writeLog(
        "DATABASE: Update Gagal - $e",
        source: _source,
        level: 1,
      );
      rethrow;
    }
  }

  /// DELETE: Menghapus dokumen
  Future<void> deleteLog(ObjectId id) async 
  {
    try {
      final collection = await _getSafeCollection();
      await collection.remove(where.id(id));

      await LogHelper.writeLog(
        "DATABASE: Hapus ID $id Berhasil",
        source: _source,
        level: 2,
      );
    } catch (e) {
      await LogHelper.writeLog(
        "DATABASE: Hapus Gagal - $e",
        source: _source,
        level: 1,
      );
      rethrow;
    }
  }

}
