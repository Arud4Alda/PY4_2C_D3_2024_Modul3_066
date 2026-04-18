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
    // Ambil dari LOCAL (Hive)
    logsNotifier.value = _box.values.toList();
    _applyFilter();
    // Sync dari CLOUD
    try {
      final clouddata = await MongoService().getLogs(teamId);
      // final pendingLogs = _box.values.where((log) => log.id == null).toList();
      // final combinedData = [...data, ...pendingLogs];
      // final teamdata = data.where((log) => log.teamId == teamId).toList();
      final localData = _box.values.toList();
      List<LogModel> finalData = [];
      // Mencegah editan offline hilang
      for (var cloudLog in clouddata) {
        try {
          // Cari apakah log dari cloud ini ada di HP kita
          final localLog = localData.firstWhere((l) => l.id == cloudLog.id);          
          // Bandingkan waktunya
          DateTime cloudDate = DateTime.parse(cloudLog.date);
          DateTime localDate = DateTime.parse(localLog.date);
          // Jika data di HP lebih baru hasil EDIT OFFLINE
          if (localDate.isAfter(cloudDate)) {
            finalData.add(localLog);             
            // unggah perubahannya ke Cloud
            MongoService().updateLog(localLog).catchError((e) {
              LogHelper.writeLog("Auto-Sync Edit Tertunda", level: 1);
            });
          } else { // Jika tidak, pakai data dari Cloud
            finalData.add(cloudLog);
          }
        } catch (e) {// Jika tidak ada di lokal 
          finalData.add(cloudLog);
        }
      }
      // Tambahkan data PENDING 
      final pendingLogs = localData.where((log) => log.id == null).toList();
      finalData.addAll(pendingLogs);
      await _box.clear();
      await _box.addAll(finalData);
      logsNotifier.value = finalData;
      await LogHelper.writeLog(
        "SYNC: Data berhasil diperbarui dari Atlas dan Lokal",
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
    //await MongoService().updateLog(updatedLog);
    final allLocalLogs = _box.values.toList();
    final indexInBox = allLocalLogs.indexWhere((item) => item.id == oldLog.id);
    if (indexInBox != -1) {
      await _box.putAt(indexInBox, updatedLog); // Timpa data lama di Hive
    }
    final current = List<LogModel>.from(logsNotifier.value);
    final index = current.indexOf(oldLog);
    if (index != -1) {
      current[index] = updatedLog;
    }
    logsNotifier.value = current;
    try {
      await MongoService().updateLog(updatedLog);
      await LogHelper.writeLog("SYNC: Perubahan '${updatedLog.title}' berhasil diunggah", level: 2);
    } catch (e) {
      await LogHelper.writeLog("OFFLINE: Perubahan disimpan lokal, gagal sinkron ke cloud", level: 1);
    }
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

