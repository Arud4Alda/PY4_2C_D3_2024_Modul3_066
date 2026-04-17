import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:py4_2c_d3_2024_modul1_066/features/logbook/models/log_model.dart';

class LogController {
  final ValueNotifier<List<LogModel>> logsNotifier = ValueNotifier([]);
  final ValueNotifier<List<LogModel>> filteredLogs = ValueNotifier([]);
  static const String _storageKey = 'user_logs_data';

  String _currentQuery = "";
  LogController();
  //LogController() {loadLogs();}

  //ADD
  void addLog(String title, String category, String desc) {
    final newLog = LogModel(
      title: title,
      category: category,
      description: desc,
      date: DateTime.now().toString(),
    );
    logsNotifier.value = [...logsNotifier.value, newLog];
    _applyFilter();
    saveToDisk();
  }

  //UPDATE
  void updateLog(LogModel oldLog, String title, String category, String desc) {
    final currentLogs = List<LogModel>.from(logsNotifier.value);
    final index = currentLogs.indexOf(oldLog);

    if (index != -1) {
      currentLogs[index] = LogModel(
        title: title,
        category: category,
        description: desc,
        date: DateTime.now().toString(),
      );
    }
    logsNotifier.value = currentLogs;
    _applyFilter();
    saveToDisk();
  }

  //DELETE
  void removeLog(LogModel log) {
    final currentLogs = List<LogModel>.from(logsNotifier.value);
    currentLogs.remove(log);
    logsNotifier.value = currentLogs;
    _applyFilter();
    saveToDisk();
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
      filteredLogs.value = logsNotifier.value
          .where(
            (log) =>
                log.title.toLowerCase().contains(_currentQuery.toLowerCase()),
          )
          .toList();
    }
  }

  //SAVE
  Future<void> saveToDisk() async {
    final prefs = await SharedPreferences.getInstance();
    final String encodedData = jsonEncode(
      logsNotifier.value.map((e) => e.toMap()).toList(),
    );
    await prefs.setString(_storageKey, encodedData);
  }

  //LOAD
  Future<void> loadLogs() async {
    final prefs = await SharedPreferences.getInstance();
    final String? rawJson = prefs.getString(_storageKey);

    if (rawJson != null) {
      // 1. Decode String ke List<Map>
      final List decoded = jsonDecode(rawJson);
      // 2. Map kembali ke List<LogModel>
      logsNotifier.value = decoded
          .map((item) => LogModel.fromMap(item))
          .toList();
    }
    _applyFilter();
  }
}
