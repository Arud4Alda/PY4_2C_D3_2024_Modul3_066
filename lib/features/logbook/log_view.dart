import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:py4_2c_d3_2024_modul1_066/features/logbook/log_controller.dart';
import 'package:py4_2c_d3_2024_modul1_066/features/onboarding/onboarding_view.dart';
import 'package:py4_2c_d3_2024_modul1_066/features/logbook/models/log_model.dart';
import 'package:py4_2c_d3_2024_modul1_066/helpers/log_helper.dart';
import 'package:py4_2c_d3_2024_modul1_066/services/mongo_service.dart';

class LogView extends StatefulWidget {
  final String username;
  const LogView({super.key, required this.username});
  @override
  State<LogView> createState() => _LogViewState();
}

class _LogViewState extends State<LogView> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  final LogController _controller = LogController();
  late Future<List<LogModel>> _futureLogs;

  //INIT STATE
  @override
  void initState() {
    super.initState();
    initializeDateFormatting('id_ID', null);
    _initDatabase();
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
              );
              setState(() {
                _futureLogs = MongoService().getLogs();
              });

              _titleController.clear();
              _contentController.clear();
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
              onChanged: (value) => _controller.searchLog(value),
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
                    child: Text(
                      "⚠️ Offline Mode Warning\nTidak dapat terhubung ke server.",
                      textAlign: TextAlign.center,
                    ),
                  );
                }

                final logs = snapshot.data ?? [];

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
                    itemCount: logs.length,
                    itemBuilder: (context, index) 
                    {
                      final log = logs[index];
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
                                    Text(log.description),
                                    const SizedBox(height: 4),
                                    Text(formattedDate),
                                  ],
                                ),
                                trailing: Wrap(
                                  children: [
                                    IconButton(
                                      icon: const Icon(
                                        Icons.edit,
                                        color: Color.fromARGB(185,100,152,194,),
                                      ),
                                      onPressed: () => _showEditLogDialog(log),
                                    ),
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
