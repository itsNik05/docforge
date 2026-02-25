import 'dart:io';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart' as sfpdf;
import 'package:pdfx/pdfx.dart';
import 'package:path/path.dart' as p;

class MergePdfPage extends StatefulWidget {
  const MergePdfPage({super.key});

  @override
  State<MergePdfPage> createState() => _MergePdfPageState();
}

class _MergePdfPageState extends State<MergePdfPage> {
  List<File> selectedFiles = [];
  String? mergedPath;
  bool isProcessing = false;
  int totalPages = 0;
  Map<String, int> filePageCounts = {};
  int totalFileSizeBytes = 0;
  double mergeProgress = 0.0;


  Future<void> calculateFileStats() async {
    int pages = 0;
    int sizeBytes = 0;
    Map<String, int> pageMap = {};

    for (File file in selectedFiles) {
      final bytes = await file.readAsBytes();
      sizeBytes += bytes.length;

      final document = sfpdf.PdfDocument(inputBytes: bytes);
      final count = document.pages.count;

      pages += count;
      pageMap[file.path] = count;

      document.dispose();
    }

    setState(() {
      totalPages = pages;
      totalFileSizeBytes = sizeBytes;
      filePageCounts = pageMap;
    });
  }


  Future<void> pickFiles() async {
    final typeGroup = XTypeGroup(label: 'PDF', extensions: ['pdf']);
    final files = await openFiles(acceptedTypeGroups: [typeGroup]);

    if (files.isEmpty) return;

    setState(() {
      for (var file in files) {
        final newFile = File(file.path);

        // Prevent duplicate entries
        if (!selectedFiles.any((f) => f.path == newFile.path)) {
          selectedFiles.add(newFile);
        }
      }

      mergedPath = null; // reset preview when adding new files
    });
    await calculateFileStats();
  }
  Future<void> mergePdfs() async {
    if (selectedFiles.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Select at least 2 PDFs")),
      );
      return;
    }

    setState(() => isProcessing = true);

    final mergedDocument = sfpdf.PdfDocument();

    try {
      for (File file in selectedFiles) {
        final bytes = await file.readAsBytes();
        final sfpdf.PdfDocument document =
        sfpdf.PdfDocument(inputBytes: bytes);

        for (int i = 0; i < document.pages.count; i++) {
          final originalPage = document.pages[i];
          final template = originalPage.createTemplate();

          final section = mergedDocument.sections!.add();
          section.pageSettings.size =
              Size(originalPage.size.width, originalPage.size.height);
          section.pageSettings.margins.all = 0;

          final newPage = section.pages.add();

          newPage.graphics.drawPdfTemplate(
            template,
            const Offset(0, 0),
            Size(originalPage.size.width, originalPage.size.height),
          );
        }

        document.dispose();
      }

      // ✅ CREATE DocForge DIRECTORY
      final directory = await getApplicationDocumentsDirectory();
      final pdfDir = Directory('${directory.path}/DocForge');

      if (!await pdfDir.exists()) {
        await pdfDir.create(recursive: true);
      }

      // ✅ UNIQUE FILE NAME
      final fileName =
          'merged_${DateTime.now().millisecondsSinceEpoch}.pdf';

      final filePath = '${pdfDir.path}/$fileName';

      final bytes = mergedDocument.saveSync();
      await File(filePath).writeAsBytes(bytes);

      mergedDocument.dispose();

      print("Saved at: $filePath");

      setState(() {
        mergedPath = filePath;
        isProcessing = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("PDFs merged successfully!")),
      );
    } catch (e) {
      setState(() => isProcessing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  void removeFile(int index) async {
    setState(() {
      selectedFiles.removeAt(index);
    });

    await calculateFileStats();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Merge PDFs")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            ElevatedButton(
              onPressed: pickFiles,
              child: const Text("Select PDFs"),
            ),

            const SizedBox(height: 10),

            Text("Selected: ${selectedFiles.length} files"),

            const SizedBox(height: 10),

            /// 🔥 DRAG REORDER LIST
            if (selectedFiles.isNotEmpty)
              Expanded(
                child: ReorderableListView.builder(
                  itemCount: selectedFiles.length,
                  onReorder: (oldIndex, newIndex) {
                    setState(() {
                      if (newIndex > oldIndex) newIndex--;
                      final file = selectedFiles.removeAt(oldIndex);
                      selectedFiles.insert(newIndex, file);
                    });
                  },
                  itemBuilder: (context, index) {
                    final file = selectedFiles[index];

                    return Card(
                      key: ValueKey(file.path),
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      color: const Color(0xFF1A1A1F),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            const Icon(Icons.picture_as_pdf,
                                color: Color(0xFFFF6B2B), size: 32),

                            const SizedBox(width: 12),

                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    p.basename(file.path),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),

                                  const SizedBox(height: 4),

                                  FutureBuilder<int>(
                                    future: file.length(),
                                    builder: (context, snapshot) {
                                      if (!snapshot.hasData) return const SizedBox();

                                      final sizeInKB = snapshot.data! / 1024;
                                      final sizeInMB = sizeInKB / 1024;

                                      final sizeText = sizeInMB >= 1
                                          ? "${sizeInMB.toStringAsFixed(2)} MB"
                                          : "${sizeInKB.toStringAsFixed(0)} KB";

                                      return Text(
                                        sizeText,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.white54,
                                        ),
                                      );
                                    },
                                  ),
                                  if (filePageCounts.containsKey(file.path))
                                    Text(
                                      "${filePageCounts[file.path]} pages",
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.white38,
                                      ),
                                    ),
                                ],
                              ),
                            ),

                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.redAccent),
                              onPressed: () => removeFile(index),
                            ),

                            const Icon(Icons.drag_handle, color: Colors.white38),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

            if (selectedFiles.isNotEmpty)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () {
                    setState(() {
                      selectedFiles.clear();
                      totalPages = 0;
                      totalFileSizeBytes = 0;
                      filePageCounts.clear();
                      mergedPath = null;
                    });
                  },
                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                  label: const Text(
                    "Clear All",
                    style: TextStyle(color: Colors.redAccent),
                  ),
                ),
              ),

            const SizedBox(height: 10),

            if (selectedFiles.isNotEmpty)
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF131316),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFFF6B2B)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _statRow("Total Files", selectedFiles.length.toString()),
                    _statRow("Total Pages", totalPages.toString()),
                    _statRow("Combined Size", _formatBytes(totalFileSizeBytes)),
                  ],
                ),
              ),

            ElevatedButton(
              onPressed: isProcessing ? null : mergePdfs,
              child: isProcessing
                  ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
                  : const Text("Merge"),
            ),

            const SizedBox(height: 10),

            /// 🔥 PDF PREVIEW
            if (mergedPath != null)
              Expanded(
                child: PdfView(
                  controller: PdfController(
                    document: PdfDocument.openFile(mergedPath!),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
  Widget _statRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white54)),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFFFF6B2B),
            ),
          ),
        ],
      ),
    );
  }

  String _formatBytes(int bytes) {
    if (bytes >= 1024 * 1024) {
      return "${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB";
    } else {
      return "${(bytes / 1024).toStringAsFixed(0)} KB";
    }
  }
}