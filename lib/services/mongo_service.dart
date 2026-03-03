import 'package:mongo_dart/mongo_dart.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class MongoService {
  static final MongoService _instance = MongoService._internal();
  factory MongoService() {
    return _instance;
  }
  MongoService._internal();
  Db? _db;

  Future<void> connect() async {
    if (_db != null && _db!.isConnected) {
      return; 
    }

    final uri = dotenv.env['MONGODB_URI'];

    if (uri == null) {
      throw Exception("MONGODB_URI tidak ditemukan di file .env");
    }

    _db = await Db.create(uri);
    await _db!.open();

    if (!_db!.isConnected) {
      throw Exception("Koneksi MongoDB gagal");
    }
  }

  Future<void> close() async {
    if (_db != null && _db!.isConnected) {
      await _db!.close();
    }
  }

  Future<void> insertLog(Map<String, dynamic> data) async {
    await connect(); // Pastikan koneksi aktif
    final collection = _db!.collection('logs');
    await collection.insertOne(data);
  }

 Future<List<Map<String, dynamic>>> getLogs() async {
    await connect();
    final collection = _db!.collection('logs');
    return await collection.find().toList();
  }

  Future<void> updateLog(
      ObjectId id, Map<String, dynamic> updatedData) async {
    await connect();
    final collection = _db!.collection('logs');

    await collection.updateOne(
      where.id(id),
      modify.set('title', updatedData['title'])
            .set('category', updatedData['category'])
            .set('date', updatedData['date'])
            .set('description', updatedData['description']),
    );
  }

  Future<void> deleteLog(ObjectId id) async {
    await connect();
    final collection = _db!.collection('logs');
    await collection.deleteOne(where.id(id));
  }
}