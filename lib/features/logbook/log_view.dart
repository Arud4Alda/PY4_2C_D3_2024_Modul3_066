import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import 'package:intl/date_symbol_data_local.dart';
import 'package:py4_2c_d3_2024_modul1_066/features/logbook/log_controller.dart';
import 'package:py4_2c_d3_2024_modul1_066/features/logbook/models/log_model.dart';
import 'package:py4_2c_d3_2024_modul1_066/services/access_control_service.dart';
import 'package:py4_2c_d3_2024_modul1_066/features/logbook/log_editor_page.dart';
import 'package:py4_2c_d3_2024_modul1_066/features/auth/login_view.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

class LogView extends StatefulWidget {
  final dynamic currentUser;
  const LogView({super.key, required this.currentUser});
  @override
  State<LogView> createState() => _LogViewState();
}

class _LogViewState extends State<LogView> {
  late final LogController _controller;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  //INIT STATE
  @override
  void initState() {
    super.initState();
    initializeDateFormatting('id_ID', null);
    _controller = LogController();
    _controller.loadLogs(widget.currentUser['teamId']);
    _setupAutoSync();
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    super.dispose();
  }

  void _setupAutoSync() {
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((List<ConnectivityResult> results) async {
      // Cek apakah perangkat terhubung ke WiFi atau Mobile Data
      bool isConnected = results.contains(ConnectivityResult.mobile) || 
                         results.contains(ConnectivityResult.wifi);

      if (isConnected) {
        // Tampilkan notifikasi kecil bahwa sinkronisasi sedang berjalan (Opsional tapi bagus untuk UX)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Internet terhubung! Menjalankan sinkronisasi..."),
            backgroundColor: Color.fromARGB(255, 106, 160, 128),
            duration: Duration(seconds: 2),
          ),
        );
        // kirim data online ke cloud
        await _controller.syncOfflineLogs();
        // Memanggil loadLogs untuk mengambil data terbaru dari server
        await _controller.loadLogs(widget.currentUser['teamId']);
      }
    });
  }

  void _goToEditor({LogModel? log, int? index}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LogEditorPage(
          log: log,
          index: index,
          controller: _controller,
          currentUser: widget.currentUser,
        ),
      ),
    );
  }

  Color getCategoryColor(String category) {
    switch (category) {
      case "Mechanical":
        return const Color.fromARGB(255, 93, 130, 163);
      case "Electronic":
        return const Color.fromARGB(255, 100, 159, 102);
      case "Software":
        return const Color.fromARGB(255, 174, 98, 105);
      default:
        return Colors.grey.shade200;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      //judul atas
      appBar: AppBar(
        title: Text("Logbook ${widget.currentUser['username']}", style: TextStyle(color: Colors.white)),
        backgroundColor: const Color.fromARGB(255, 106, 160, 128),
        actions: [
          //logout
          IconButton(
            icon: const Icon(
              Icons.logout,
              color: Color.fromARGB(255, 255, 255, 255),
            ),
            onPressed: () {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: const Text("Konfirmasi Logout"),
                    content: const Text("Apakah Anda yakin akan tetap logout?"),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text("Batal"),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const LoginView(),
                            ),
                            (route) => false,
                          );
                        },
                        child: const Text(
                          "Ya, Keluar",
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ],
      ),

      backgroundColor: const Color.fromARGB(255, 255, 248, 231),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              onChanged: (value) => _controller.searchLog(value),
              decoration: const InputDecoration(
                labelText: "Cari Catatan...",
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
            ),
          ),
          Expanded(
            //child: FutureBuilder<List<LogModel>>(
            child: ValueListenableBuilder<List<LogModel>>(
              valueListenable: _controller.filteredLogs,
              //valueListenable: _controller.logsNotifier,
              builder: (context, logs, child) { 
                final String currentUserId = widget.currentUser['uid'];
                final List<LogModel> displayLogs = logs.where((log) {
                  return log.authorId == currentUserId || log.isPublic == true;
                }).toList();          
                if (displayLogs.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.border_color_rounded,
                          size: 100,
                          color: Color.fromARGB(255, 106, 160, 128),
                        ),
                        SizedBox(height: 20),
                        Text(
                          "Belum ada catatan",
                          style: TextStyle(
                            color: Color.fromARGB(255, 106, 160, 128),
                          ),
                        ),
                      ],
                    ),
                  );
                }
                return RefreshIndicator(
                  onRefresh: () async {
                    await _controller.loadLogs(widget.currentUser['teamId']);
                  },
                  child: ListView.builder(
                 // return ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: displayLogs.length,
                    itemBuilder: (context, index) {              
                      final log = displayLogs[index];
                      final isOwner = log.authorId == widget.currentUser['uid'];
                      final formattedDate = DateFormat(
                        'dd MMM yyyy',
                        'id_ID',
                      ).format(DateTime.parse(log.date));                      
                      return Card(
                          color: const Color.fromARGB(220, 255, 248, 231),
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: ListTile(
                            leading: Icon(
                              //Icons.android_rounded,
                              log.id != null
                                ? Icons.cloud_done
                                : Icons.cloud_upload_outlined,
                              color: getCategoryColor(log.category),
                            ),
                            title: Text(log.title),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                MarkdownBody(
                                  data: log.description,
                                  styleSheet: MarkdownStyleSheet(
                                    p: const TextStyle(fontSize: 14, color: Colors.black87),
                                    strong: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                ),
                                const SizedBox(height: 8), 
                                Text(formattedDate, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                Text(
                                  "Oleh: ${log.authorId} | Team: ${log.teamId}",
                                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                                ),
                              ],
                            ),
                            trailing: Wrap(
                              children: [
                                if (AccessControlService.canPerform(widget.currentUser['role'],AccessControlService.actionUpdate,isOwner: isOwner,))
                                  IconButton(
                                    icon: const Icon(
                                      Icons.edit,
                                      color: Color.fromARGB(185, 100, 152, 194),
                                    ),
                                    onPressed: ()  => _goToEditor(log: log, index: index),
                                  ),
                                if (AccessControlService.canPerform(widget.currentUser['role'],AccessControlService.actionDelete,isOwner: isOwner,))
                                  IconButton(
                                    icon: const Icon(
                                      Icons.delete,
                                      color: Color.fromARGB(255, 199, 118, 111),
                                    ),
                                    onPressed: () => _controller.removeLog(log),
                                  ),
                              ],
                            ),
                          ),                        
                      );
                    },                  
                ),
               );
              },
            ),
          ),
        ],
      ),
      floatingActionButton:
          AccessControlService.canPerform(widget.currentUser['role'], AccessControlService.actionCreate,)
          ? FloatingActionButton(
              backgroundColor: const Color.fromARGB(255, 106, 160, 128),
              foregroundColor: const Color.fromARGB(255, 255, 255, 255),
              onPressed: () => _goToEditor(),
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
}
