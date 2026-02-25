import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'pdf_viewer_screen.dart';

class FilesPage extends StatefulWidget {
  const FilesPage({super.key});

  @override
  State<FilesPage> createState() => _FilesPageState();
}

class _FilesPageState extends State<FilesPage> {
  List<FileSystemEntity> files = [];

  @override
  void initState() {
    super.initState();
    loadFiles();
  }

  Future<void> loadFiles() async {
    final directory = await getApplicationDocumentsDirectory();
    final pdfDir = Directory('${directory.path}/DocForge');

    if (await pdfDir.exists()) {
      setState(() {
        files = pdfDir
            .listSync()
            .where((file) => file.path.endsWith('.pdf'))
            .toList();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Files")),
      body: files.isEmpty
          ? const Center(child: Text("No PDFs yet"))
          : ListView.builder(
        itemCount: files.length,
        itemBuilder: (context, index) {
          final file = files[index] as File;
          final name = file.path.split('/').last;

          return ListTile(
            leading: const Icon(Icons.picture_as_pdf),
            title: Text(name),
            subtitle: Text(file.path),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PdfViewerScreen(filePath: file.path),
                ),
              );
            },
          );
        },
      ),
    );
  }
}