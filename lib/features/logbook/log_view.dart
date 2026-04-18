import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:py4_2c_d3_2024_modul1_066/features/logbook/log_controller.dart';
import 'package:py4_2c_d3_2024_modul1_066/features/onboarding/onboarding_view.dart';
import 'package:py4_2c_d3_2024_modul1_066/features/logbook/models/log_model.dart';
import 'package:py4_2c_d3_2024_modul1_066/helpers/log_helper.dart';
import 'package:py4_2c_d3_2024_modul1_066/services/mongo_service.dart';
import 'package:py4_2c_d3_2024_modul1_066/services/access_control_service.dart';
import 'package:py4_2c_d3_2024_modul1_066/features/auth/login_controller.dart';
import 'package:py4_2c_d3_2024_modul1_066/features/logbook/log_editor_page.dart'; 
import 'package:py4_2c_d3_2024_modul1_066/features/auth/login_view.dart';

class LogView extends StatefulWidget {
  final String username;
  final dynamic currentUser;
  //const LogView({super.key, required this.username});
  const LogView({super.key, required this.username, required this.currentUser});
  @override
  State<LogView> createState() => _LogViewState();
}

class _LogViewState extends State<LogView> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  final TextEditingController _teamidController = TextEditingController();
  final LogController _controller = LogController();
  late Future<List<LogModel>> _futureLogs;
  String _searchQuery = "";

  //INIT STATE
  @override
  void initState() {
    super.initState();
    initializeDateFormatting('id_ID', null);
    _initDatabase();
    _controller = LogController();
    _controller.loadLogs(widget.currentUser['teamId']);

  }

  void _loadLogs() {
  _futureLogs = MongoService().getLogs();
}

  Future<void> _initDatabase() async {
    try {
      await LogHelper.writeLog(
        "UI: Memulai inisialisasi database...",
        source: "log_view.dart",
      );

      // Mencoba koneksi ke MongoDB Atlas (Cloud)
      await LogHelper.writeLog(
        "UI: Menghubungi MongoService.connect()...",
        source: "log_view.dart",
      );

      await MongoService().connect();
      _futureLogs = MongoService().getLogs();
      setState(() {});

      await LogHelper.writeLog(
        "UI: Koneksi MongoService BERHASIL.",
        source: "log_view.dart",
      );

      // Mengambil data log dari Cloud
      await LogHelper.writeLog(
        "UI: Memanggil controller.loadFromDisk()...",
        source: "log_view.dart",
      );

      await _controller.loadLogs();

      await LogHelper.writeLog(
        "UI: Data berhasil dimuat ke Notifier.",
        source: "log_view.dart",
      );
    } catch (e) {
      await LogHelper.writeLog(
        "UI: Error - $e",
        source: "log_view.dart",
        level: 1,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Masalah: $e"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        //setState(() => _isLoading = false);
      }
    }
  }

  Color getCategoryColor(String category) {
    switch (category) {
      case "Pekerjaan":
        return const Color.fromARGB(255, 93, 130, 163);
      case "Pribadi":
        return const Color.fromARGB(255, 100, 159, 102);
      case "Urgent":
        return const Color.fromARGB(255, 174, 98, 105);
      default:
        return Colors.grey.shade200;
    }
  }

  //DIALOG TAMBAH
  void _showAddLogDialog() {
    String selectedCategory = "Pribadi";
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Tambah Catatan Baru"),
        content: Column(
          mainAxisSize: MainAxisSize.min, // Agar dialog tidak memenuhi layar
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(hintText: "Judul Catatan"),
            ),
            DropdownButtonFormField<String>(
              initialValue: selectedCategory,
              items: ["Pekerjaan", "Pribadi", "Urgent"]
                  .map(
                    (category) => DropdownMenuItem(
                      value: category,
                      child: Text(category),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                selectedCategory = value!;
              },
            ),
            TextField(
              controller: _contentController,
              decoration: const InputDecoration(hintText: "Isi Deskripsi"),
            ),
            TextField(
              controller: _teamidController,
              decoration: const InputDecoration(hintText: "Isi ID Kelompok"),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Batal"),
          ),
          ElevatedButton(
            onPressed: () async {
              await _controller.addLog(
                _titleController.text,
                selectedCategory,
                _contentController.text,
                _teamidController.text,
              );
              setState(() {
                _futureLogs = MongoService().getLogs();
              });

              _titleController.clear();
              _contentController.clear();
              _teamidController.clear();
              Navigator.pop(context);
            },
            child: const Text("Simpan"),
          ),
        ],
      ),
    );
  }

  //DIALOG EDIT
  void _showEditLogDialog(LogModel log) {
    String selectedCategory = log.category;
    _titleController.text = log.title;
    _contentController.text = log.description;
    _teamidController.text = log.teamId;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Edit Catatan"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: _titleController),
            DropdownButtonFormField<String>(
              initialValue: selectedCategory,
              items: ["Pekerjaan", "Pribadi", "Urgent"]
                  .map(
                    (category) => DropdownMenuItem(
                      value: category,
                      child: Text(category),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                selectedCategory = value!;
              },
            ),
            TextField(controller: _contentController),
            TextField(controller: _teamidController),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Batal"),
          ),
          ElevatedButton(
            onPressed: () async {
              await _controller.updateLog(
                log,
                _titleController.text,
                selectedCategory,
                _contentController.text,
                _teamidController.text,
              );
              setState(() {
                _futureLogs = MongoService().getLogs();
              });
              Navigator.pop(context);
            },
            child: const Text("Update"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Logbook", style: TextStyle(color: Colors.white)),
        backgroundColor: const Color.fromARGB(255, 106, 160, 128),
        actions: [
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
                              builder: (context) => const OnboardingView(),
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
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              //onChanged: (value) => _controller.searchLog(value),
              onChanged: (value) {setState(() {_searchQuery = value.toLowerCase();});},
              decoration: const InputDecoration(
                labelText: "Cari Catatan...",
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
            ),
          ),
          Expanded(
            child: FutureBuilder<List<LogModel>>(
              future: _futureLogs,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 20),
                        Text(
                          "BMengambil Data dari Cloud...",
                          style: TextStyle(
                            color: Color.fromARGB(255, 106, 160, 128),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.wifi_off,size: 80,color: Colors.grey,),
                        SizedBox(height: 20),
                        Text(
                          "Anda sedang offline",
                          style: TextStyle(fontSize: 18),
                        ),
                        Text(
                          "Tidak dapat terhubung ke server",
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                }

                final logs = snapshot.data ?? [];
                final filteredLogs = logs.where((log) {
                  return log.title.toLowerCase().contains(_searchQuery) ||
                        log.description.toLowerCase().contains(_searchQuery);
                }).toList();

                if (logs.isEmpty) {
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
                    setState(() {
                      _futureLogs = MongoService().getLogs();
                    });
                  },
                  child: ListView.builder(
                    itemCount: filteredLogs.length,
                    itemBuilder: (context, index) 
                    {
                      final log = filteredLogs[index];
                      final formattedDate = DateFormat('dd MMM yyyy', 'id_ID').format(DateTime.parse(log.date));
                          return Dismissible(
                            key: ValueKey(log.title),
                            direction: DismissDirection.endToStart,
                            background: Container(
                              color: Colors.red,
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 20),
                              child: const Icon(
                                Icons.delete,
                                color: Colors.white,
                              ),
                            ),
                            onDismissed: (direction) async{
                              await _controller.removeLog(log);
                              setState(() {
                                _futureLogs = MongoService().getLogs();
                              });
                            },
                            child: Card(
                              color: const Color.fromARGB(220, 255, 248, 231),
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: ListTile(
                                leading: Icon(
                                  Icons.android_rounded,
                                  color: getCategoryColor(log.category),
                                ),
                                title: Text(log.title),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(log.teamId),
                                    Text(log.description),                                    
                                    const SizedBox(height: 4),
                                    Text(formattedDate),
                                  ],
                                ),
                                trailing: Wrap(
                                  children: [
                                  if (AccessControlService.canPerform(currentUserRole, AccessControlService.actionUpdate, isOwner: log.authorId == currentUserId))
                                    IconButton(
                                      icon: const Icon(
                                        Icons.edit,
                                        color: Color.fromARGB(185,100,152,194,),
                                      ),
                                      onPressed: () => _showEditLogDialog(log),
                                    ),
                                    if (AccessControlService.canPerform(currentUserRole, AccessControlService.actionDelete, isOwner: log.authorId == currentUserId))
                                      IconButton(
                                      icon: const Icon(
                                        Icons.delete,
                                        color: Color.fromARGB(255,199,118,111),
                                      ),
                                      onPressed: () async {
                                        await _controller.removeLog(log);
                                        setState(() {
                                          _futureLogs = MongoService().getLogs();
                                        });
                                      }, 
                                    ),
                                  ],
                                ),
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
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color.fromARGB(255, 106, 160, 128),
        foregroundColor: const Color.fromARGB(255, 255, 255, 255),
        onPressed: _showAddLogDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}
