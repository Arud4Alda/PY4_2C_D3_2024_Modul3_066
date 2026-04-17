import 'package:flutter/material.dart';
import 'package:py4_2c_d3_2024_modul1_066/features/logbook/log_controller.dart';
import 'package:py4_2c_d3_2024_modul1_066/features/onboarding/onboarding_view.dart';
import 'package:py4_2c_d3_2024_modul1_066/features/logbook/models/log_model.dart';

class LogView extends StatefulWidget 
{
  final String username;
  const LogView({super.key, required this.username});
  @override
  State<LogView> createState() => _LogViewState();
}

Color getCategoryColor(String category) 
{
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

class _LogViewState extends State<LogView> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  final LogController _controller = LogController();

  //INIT STATE
  @override
  void initState() 
  {
    super.initState();
    _controller.loadLogs();
    //_controller = LogController();
    Future.microtask(() => _initDatabase());
  }

  Future<void> _initDatabase() async {
    setState(() => _isLoading = true);
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

      // Mengaktifkan kembali koneksi dengan timeout 15 detik (lebih longgar untuk sinyal HP)
      await MongoService().connect().timeout(
        const Duration(seconds: 15),
        onTimeout: () => throw Exception(
          "Koneksi Cloud Timeout. Periksa sinyal/IP Whitelist.",
        ),
      );

      await LogHelper.writeLog(
        "UI: Koneksi MongoService BERHASIL.",
        source: "log_view.dart",
      );

      // Mengambil data log dari Cloud
      await LogHelper.writeLog(
        "UI: Memanggil controller.loadFromDisk()...",
        source: "log_view.dart",
      );

      await _controller.loadFromDisk();

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
      // 2. INILAH FINALLY: Apapun yang terjadi (Sukses/Gagal/Data Kosong), loading harus mati
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
  
  //SNACKBAR
  void showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white)),
        backgroundColor: const Color.fromARGB(255, 106, 160, 128),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        margin: const EdgeInsets.all(20),
      ),
    );
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
              onChanged: (value) {selectedCategory = value!;},
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
            onPressed: () {
              _controller.addLog(
                _titleController.text,
                selectedCategory,
                _contentController.text,
              );
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
              onChanged: (value) {selectedCategory = value!;},
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
            onPressed: () {
              _controller.updateLog(
                log,
                _titleController.text,
                selectedCategory,
                _contentController.text,
              );
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
            child: ValueListenableBuilder<List<LogModel>>(
              valueListenable: _controller.filteredLogs,
              builder: (context, currentLogs, child) {
                if (_isLoading) {
                  return const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text("Menghubungkan ke MongoDB Atlas..."),
                      ],
                    ),
                  );
                }

                if (currentLogs.isEmpty) {
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
                return ListView.builder(
                  itemCount: currentLogs.length,
                  itemBuilder: (context, index) {
                    final log = currentLogs[index];
                    return Dismissible(
                      key: ValueKey(log.title),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        color: Colors.red,
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      onDismissed: (direction) 
                      {
                        _controller.removeLog(log);
                      },
                      child: Card(
                        color: const Color.fromARGB(220, 255, 248, 231),
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: ListTile(
                          leading: Icon(Icons.android_rounded, color: getCategoryColor(log.category)),
                          title: Text(log.title),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(log.description),
                              const SizedBox(height: 4),
                              Text(
                                log.date,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                          trailing: Wrap(
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.edit,
                                  color: Color.fromARGB(185, 100, 152, 194),
                                ),
                                onPressed: () => _showEditLogDialog(log), 
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: Color.fromARGB(255, 199, 118, 111),
                                ),
                                onPressed: () {_controller.removeLog(log);},
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
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
