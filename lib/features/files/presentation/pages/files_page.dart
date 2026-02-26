import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'pdf_viewer_screen.dart';
import 'package:file_picker/file_picker.dart';

class FilesPage extends StatefulWidget {
  const FilesPage({super.key});

  @override
  State<FilesPage> createState() => _FilesPageState();
}

class _FilesPageState extends State<FilesPage> {
  List<File> files = [];
  Set<File> selectedFiles = {};
  bool selectionMode = false;

  @override
  void initState() {
    super.initState();
    loadFiles();
  }

  Future<void> loadFiles() async {
    final directory = await getApplicationDocumentsDirectory();
    final pdfDir = Directory('${directory.path}/DocForge');

    if (await pdfDir.exists()) {
      final loadedFiles = pdfDir
          .listSync()
          .where((file) => file.path.endsWith('.pdf'))
          .map((e) => File(e.path))
          .toList();

      loadedFiles.sort(
            (a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()),
      );

      setState(() {
        files = loadedFiles;
      });
    }
  }

  // ---------------- RENAME ----------------

  Future<void> renameFile(File file) async {
    final controller = TextEditingController(
        text: file.path.split('/').last.replaceAll('.pdf', ''));

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Rename File"),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: "Enter new file name",
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              final newName = controller.text.trim();
              if (newName.isEmpty) return;

              final newPath =
                  "${file.parent.path}/$newName.pdf";

              await file.rename(newPath);

              Navigator.pop(context);
              loadFiles();
            },
            child: const Text("Rename"),
          ),
        ],
      ),
    );
  }

  // ---------------- DELETE ----------------

  Future<void> deleteSelected() async {
    final filesToDelete = List<File>.from(selectedFiles);

    for (var file in filesToDelete) {
      if (await file.exists()) {
        await file.delete();
      }
    }

    setState(() {
      selectedFiles.clear();
      selectionMode = false;
    });

    loadFiles();
  }

  // ---------------- SHARE ----------------

  Future<void> shareSelected() async {
    final filesToShare =
    selectedFiles.map((e) => XFile(e.path)).toList();

    await Share.shareXFiles(filesToShare);

    setState(() {
      selectedFiles.clear();
      selectionMode = false;
    });
  }

  // ---------------- MOVE ----------------

  Future<void> saveSelectedToFolder() async {
    try {
      String? selectedDirectory =
      await FilePicker.platform.getDirectoryPath();

      if (selectedDirectory == null) return;

      for (var file in selectedFiles) {
        final fileName = file.path.split('/').last;
        final newPath = "$selectedDirectory/$fileName";

        final newFile = await File(newPath).create(recursive: true);
        await newFile.writeAsBytes(await file.readAsBytes());
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Saved to selected folder")),
      );

      setState(() {
        selectedFiles.clear();
        selectionMode = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }
  String formatBytes(int bytes) {
    if (bytes >= 1024 * 1024) {
      return "${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB";
    } else {
      return "${(bytes / 1024).toStringAsFixed(0)} KB";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: selectionMode
            ? Text("${selectedFiles.length} selected")
            : const Text("Files"),
        actions: selectionMode
            ? [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: shareSelected,
          ),
          IconButton(
            icon: const Icon(Icons.folder_open),
            onPressed: saveSelectedToFolder,
          ),
          IconButton(
            icon: const Icon(Icons.delete,
                color: Colors.red),
            onPressed: deleteSelected,
          ),
        ]
            : [],
      ),
      body: files.isEmpty
          ? const Center(
          child: Text("No PDFs yet",
              style: TextStyle(color: Colors.white54)))
          : ListView.builder(
        itemCount: files.length,
        itemBuilder: (context, index) {
          final file = files[index];
          final name = file.path.split('/').last;
          final size = formatBytes(file.lengthSync());

          final isSelected =
          selectedFiles.contains(file);

          return Card(
            margin: const EdgeInsets.symmetric(
                horizontal: 12, vertical: 6),
            color: isSelected
                ? const Color(0x33FF6B2B)
                : const Color(0xFF1A1A1F),
            child: ListTile(
              leading: Icon(
                Icons.picture_as_pdf,
                color: isSelected
                    ? Colors.orange
                    : const Color(0xFFFF6B2B),
              ),
              title: Text(name,
                  overflow: TextOverflow.ellipsis),
              subtitle: Text(size),
              onTap: () {
                if (selectionMode) {
                  setState(() {
                    if (isSelected) {
                      selectedFiles.remove(file);
                    } else {
                      selectedFiles.add(file);
                    }
                  });
                } else {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          PdfViewerScreen(
                              filePath: file.path),
                    ),
                  );
                }
              },
              onLongPress: () {
                setState(() {
                  selectionMode = true;
                  selectedFiles.add(file);
                });
              },
              trailing: !selectionMode
                  ? PopupMenuButton<String>(
                onSelected: (value) async {
                  if (value == "rename") {
                    renameFile(file);
                  } else if (value == "share") {
                    await Share.shareXFiles([XFile(file.path)]);
                  } else if (value == "save") {
                    String? selectedDirectory =
                    await FilePicker.platform.getDirectoryPath();

                    if (selectedDirectory != null) {
                      final fileName = file.path.split('/').last;
                      final newPath = "$selectedDirectory/$fileName";

                      final newFile = await File(newPath).create(recursive: true);
                      await newFile.writeAsBytes(await file.readAsBytes());

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Saved to folder")),
                      );
                    }
                  } else if (value == "delete") {
                    await file.delete();
                    loadFiles();
                  }
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(
                    value: "rename",
                    child: Text("Rename"),
                  ),
                  PopupMenuItem(
                    value: "share",
                    child: Text("Share"),
                  ),
                  PopupMenuItem(
                    value: "save",
                    child: Text("Save To Folder"),
                  ),
                  PopupMenuItem(
                    value: "delete",
                    child: Text(
                      "Delete",
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                ],
              )
                  : null,
            ),
          );
        },
      ),
      floatingActionButton: selectionMode
          ? FloatingActionButton(
        backgroundColor: Colors.grey,
        onPressed: () {
          setState(() {
            selectionMode = false;
            selectedFiles.clear();
          });
        },
        child: const Icon(Icons.close),
      )
          : null,
    );
  }
}