import 'package:flutter/material.dart';
import 'package:py4_2c_d3_2024_modul1_066/features/logbook/models/log_model.dart';
import 'package:py4_2c_d3_2024_modul1_066/services/access_control_service.dart';
import 'package:py4_2c_d3_2024_modul1_066/services/mongo_service.dart';
import 'package:py4_2c_d3_2024_modul1_066/helpers/log_helper.dart';

class LogController {
  final ValueNotifier<List<LogModel>> logsNotifier = ValueNotifier([]);
  final ValueNotifier<List<LogModel>> filteredLogs = ValueNotifier([]);
  String _currentQuery = "";
  List<LogModel> get logs => logsNotifier.value;
  LogController();

  //LOAD
  Future<void> loadLogs() async {
    final data = await MongoService().getLogs();
    logsNotifier.value = data;
    _applyFilter();
  }

  //ADD
  Future<void> addLog(String title, String category, String desc, String teamId) async {
    final newLog = LogModel(
      //id: ObjectId(),
      title: title,
      category: category,
      description: desc,
      date: DateTime.now().toString(),
      authorId: "currentUserId", 
      teamId: teamId,
    );
    await MongoService().insertLog(newLog);
    final current = List<LogModel>.from(logsNotifier.value);
    current.add(newLog);
    logsNotifier.value = current;
    _applyFilter();
  }

  //UPDATE
  Future<void> updateLog(LogModel oldLog,String title,String category,String desc, String teamId) async {
    final updatedLog = LogModel(
      id: oldLog.id,
      title: title,
      category: category,
      description: desc,
      date: DateTime.now().toString(),
      authorId: oldLog.authorId,
      teamId: teamId,
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
  Future<void> removeLog(LogModel log) async
  {
    if (!AccessControlService.canPerform(currentUserRole, 'delete', isOwner: log.authorId == current)) {
    await LogHelper.writeLog("SECURITY BREACH: Unauthorized delete attempt", level: 1);
    return; }

    if (log.id == null) return;
    await MongoService().deleteLog(log.id!);

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
      filteredLogs.value = logsNotifier.value
          .where(
            (log) =>
                log.title.toLowerCase().contains(_currentQuery.toLowerCase()),
          )
          .toList();
    }
  }
}
