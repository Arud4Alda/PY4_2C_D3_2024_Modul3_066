import 'package:flutter/material.dart';
import 'package:py4_2c_d3_2024_modul1_066/features/logbook/models/log_model.dart';
import 'package:py4_2c_d3_2024_modul1_066/services/mongo_service.dart';
import 'package:mongo_dart/mongo_dart.dart';
import 'package:py4_2c_d3_2024_modul1_066/helpers/log_helper.dart';
import 'package:hive/hive.dart' as hive;

class LogController {
  final ValueNotifier<List<LogModel>> logsNotifier = ValueNotifier([]);
  final ValueNotifier<List<LogModel>> filteredLogs = ValueNotifier([]);
  final hive.Box<LogModel> _box = hive.Hive.box<LogModel>('offline_logs');
  String _currentQuery = "";
  List<LogModel> get logs => logsNotifier.value;
  LogController();

  //LOAD
  Future<void> loadLogs(String teamId) async {
    // 1. Ambil dari LOCAL (Hive)
    logsNotifier.value = _box.values.toList();
    // 2. Sync dari CLOUD
    try {
      final data = await MongoService().getLogs(teamId);
      final teamdata = data.where((log) => log.teamId == teamId).toList();
      await _box.clear();
      await _box.addAll(teamdata);
      logsNotifier.value = teamdata;
      await LogHelper.writeLog(
        "SYNC: Data berhasil diperbarui dari Atlas",
        level: 2,
      );
    } catch (e) {
      await LogHelper.writeLog(
        "OFFLINE: Menggunakan data cache lokal",
        level: 2,
      );
    }
    _applyFilter();
  }

  //ADD
  Future<void> addLog(
    String title,
    String category,
    String desc,
    String authorId,
    String teamId,
    bool isPublic,
  ) async {
    final newLog = LogModel(
      title: title,
      category: category,
      description: desc,
      date: DateTime.now().toString(),
      authorId: authorId,
      teamId: teamId,
      isPublic: isPublic,
    );
    await _box.add(newLog);
    logsNotifier.value = [...logsNotifier.value, newLog];
    try {
      final insertedId = await MongoService().insertLog(newLog);
      newLog.id = insertedId;
      await _box.putAt(_box.length - 1, newLog);
    } catch (e) {
      await LogHelper.writeLog(
        "WARNING: Data tersimpan lokal, akan sinkron saat online",
        level: 1,
      );
    }
    _applyFilter();
  }

  //UPDATE
  Future<void> updateLog(
    LogModel oldLog,
    String title,
    String category,
    String desc,
    String authorId,
    String teamId,
    bool isPublic,
  ) async {
    final updatedLog = LogModel(
      id: oldLog.id,
      title: title,
      category: category,
      description: desc,
      date: DateTime.now().toString(),
      authorId: authorId,
      teamId: teamId,
      isPublic: isPublic,
    );
    await MongoService().updateLog(updatedLog);

    final current = List<LogModel>.from(logsNotifier.value);
    final index = current.indexOf(oldLog);
    if (index != -1) {
      current[index] = updatedLog;
    }

    logsNotifier.value = current;
    _applyFilter();
  }

  //DELETE
  Future<void> removeLog(LogModel log) async {
    if (log.id == null) return;
    await MongoService().deleteLog(ObjectId.fromHexString(log.id!));
    final current = List<LogModel>.from(logsNotifier.value);
    current.remove(log);
    logsNotifier.value = current;
    _applyFilter();
  }

  //SEARCH
  void searchLog(String query) {
    _currentQuery = query;
    _applyFilter();
  }

  //FILTER
  void _applyFilter() {
    if (_currentQuery.isEmpty) {
      filteredLogs.value = logsNotifier.value;
    } else {
      final query = _currentQuery.toLowerCase();
      filteredLogs.value = logsNotifier.value.where((log) {
        return log.title.toLowerCase().contains(query.toLowerCase()) ||
               log.description.toLowerCase().contains(query.toLowerCase());
      }).toList();
    }
  }

  Future<void> syncOfflineLogs() async {
    final localLogs = _box.values.toList();
    bool hasChanges = false;

    // Looping semua data di Hive
    for (int i = 0; i < localLogs.length; i++) {
      final log = localLogs[i];      
      // Jika id-nya null, berarti ini data offline yang belum masuk server
      if (log.id == null) {
        try {
          // Push ke MongoDB
          final insertedId = await MongoService().insertLog(log);          
          // Jika sukses, perbarui ID-nya dan simpan kembali ke Hive
          log.id = insertedId;
          await _box.putAt(i, log); 
          hasChanges = true;          
          await LogHelper.writeLog(
            "AUTO-SYNC: Data '${log.title}' berhasil diunggah ke Cloud",
            level: 2,
          );
        } catch (e) {
          await LogHelper.writeLog(
            "AUTO-SYNC PENDING: '${log.title}' gagal diunggah",
            level: 1,
          );
        }
      }
    }
    if (hasChanges) {
      _applyFilter();
    }
  }
}

