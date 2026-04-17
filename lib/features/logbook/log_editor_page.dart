import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:py4_2c_d3_2024_modul1_066/features/logbook/models/log_model.dart';
import 'package:py4_2c_d3_2024_modul1_066/features/logbook/log_controller.dart';

class LogEditorPage extends StatefulWidget {
  final LogModel? log;
  final int? index;
  final LogController controller;
  final dynamic currentUser;

  const LogEditorPage({
    super.key,
    this.log,
    this.index,
    required this.controller,
    required this.currentUser,
  });

  @override
  State<LogEditorPage> createState() => _LogEditorPageState();
}

class _LogEditorPageState extends State<LogEditorPage> {
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  String selectedCategory = "Mechanical";
  bool _isPublic = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.log?.title ?? '');
    selectedCategory = widget.log?.category ?? "Mechanical";
    _contentController = TextEditingController(
      text: widget.log?.description ?? '',
    );
    _isPublic = widget.log?.isPublic ?? false;
    _contentController.addListener(() {
      setState(() {});
    });
  }

  void _save() async{
    if (widget.log == null) {
      // Tambah Baru
      await widget.controller.addLog(
        _titleController.text,
        selectedCategory,
        _contentController.text,
        widget.currentUser['uid'],
        widget.currentUser['teamId'],
        _isPublic,
      );
    } else {
      // Update
      widget.controller.updateLog(
        widget.log!,
        _titleController.text,
        selectedCategory,
        _contentController.text,
        widget.currentUser['uid'],
        widget.currentUser['teamId'],
        _isPublic,
      );
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Catatan berhasil disimpan"),
          backgroundColor: Colors.green,
        ),
      );
    }
    Navigator.pop(context);
  }

  @override
  void dispose() {
    // JANGAN LUPA: Bersihkan controller agar tidak memory leak
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.log == null ? "Catatan Baru" : "Edit Catatan"),
          bottom: const TabBar(
            tabs: [
              Tab(text: "Editor"),
              Tab(text: "Pratinjau"),
            ],
          ),
          actions: [IconButton(icon: const Icon(Icons.save), onPressed: _save)],
        ),
        body: TabBarView(
          children: [
            // Tab 1: Editor
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  TextField(
                    controller: _titleController,
                    decoration: const InputDecoration(labelText: "Judul"),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    initialValue: selectedCategory,
                    decoration: const InputDecoration(labelText: "Kategori"),
                    items: ["Mechanical", "Electronic", "Software"]
                        .map(
                          (c) => DropdownMenuItem(
                            value: c,
                            child: Text(c),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedCategory = value!;
                      });
                    },
                  ),
                  const SizedBox(height: 10),
                    SwitchListTile(
                      title: const Text("Buat Publik? (Bisa dilihat tim)"),
                      value: _isPublic,
                      activeColor: const Color.fromARGB(255, 106, 160, 128),
                      onChanged: (bool value) {
                        setState(() {
                          _isPublic = value;
                        });
                      },
                    ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: TextField(
                      controller: _contentController,
                      maxLines: null,
                      expands: true,
                      keyboardType: TextInputType.multiline,
                      decoration: const InputDecoration(
                        hintText: "Tulis laporan dengan format Markdown...",
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Tab 2: Markdown Preview
            Markdown(data: _contentController.text),
          ],
        ),
      ),
    );
  }
}