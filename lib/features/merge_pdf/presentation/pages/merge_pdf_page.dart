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
  bool isMergedPreviewReady = false;

  int totalPages = 0;
  Map<String, int> filePageCounts = {};
  int totalFileSizeBytes = 0;

  // ---------------- FILE STATS ----------------

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

  // ---------------- PICK FILES ----------------

  Future<void> pickFiles() async {
    final typeGroup = XTypeGroup(label: 'PDF', extensions: ['pdf']);
    final files = await openFiles(acceptedTypeGroups: [typeGroup]);

    if (files.isEmpty) return;

    setState(() {
      for (var file in files) {
        final newFile = File(file.path);

        if (!selectedFiles.any((f) => f.path == newFile.path)) {
          selectedFiles.add(newFile);
        }
      }

      mergedPath = null;
      isMergedPreviewReady = false;
    });

    await calculateFileStats();
  }

  // ---------------- MERGE ----------------

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
        final document = sfpdf.PdfDocument(inputBytes: bytes);

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

      final directory = await getApplicationDocumentsDirectory();
      final pdfDir = Directory('${directory.path}/DocForge');

      if (!await pdfDir.exists()) {
        await pdfDir.create(recursive: true);
      }

      final fileName =
          'merged_${DateTime.now().millisecondsSinceEpoch}.pdf';

      final filePath = '${pdfDir.path}/$fileName';

      final bytes = mergedDocument.saveSync();
      await File(filePath).writeAsBytes(bytes);

      mergedDocument.dispose();

      setState(() {
        mergedPath = filePath;
        isMergedPreviewReady = true;
        isProcessing = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("PDF merged successfully!")),
      );
    } catch (e) {
      setState(() => isProcessing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  // ---------------- EXPORT ----------------

  void exportPdf() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("PDF saved successfully!")),
    );

    setState(() {
      selectedFiles.clear();
      totalPages = 0;
      totalFileSizeBytes = 0;
      filePageCounts.clear();
      isMergedPreviewReady = false;
      mergedPath = null;
    });
  }

  void removeFile(int index) async {
    setState(() {
      selectedFiles.removeAt(index);
    });
    await calculateFileStats();
  }

  // ---------------- UI ----------------

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
              child: Text(
                selectedFiles.isEmpty ? "Select PDFs" : "Add PDFs",
              ),
            ),

            const SizedBox(height: 10),

            Text("Selected: ${selectedFiles.length} files"),

            const SizedBox(height: 10),

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
                      color: const Color(0xFF1A1A1F),
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      child: ListTile(
                        leading: const Icon(Icons.picture_as_pdf,
                            color: Color(0xFFFF6B2B)),
                        title: Text(
                          p.basename(file.path),
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_formatBytes(file.lengthSync())),
                            if (filePageCounts.containsKey(file.path))
                              Text("${filePageCounts[file.path]} pages"),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.delete,
                                  color: Colors.redAccent),
                              onPressed: () => removeFile(index),
                            ),
                            const Icon(Icons.drag_handle,
                                color: Colors.white38),
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
                      isMergedPreviewReady = false;
                    });
                  },
                  icon: const Icon(Icons.delete_outline,
                      color: Colors.redAccent),
                  label: const Text("Clear All",
                      style: TextStyle(color: Colors.redAccent)),
                ),
              ),

            if (selectedFiles.isNotEmpty)
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF131316),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: const Color(0xFFFF6B2B)),
                ),
                child: Column(
                  children: [
                    _statRow("Total Files",
                        selectedFiles.length.toString()),
                    _statRow(
                        "Total Pages", totalPages.toString()),
                    _statRow("Combined Size",
                        _formatBytes(totalFileSizeBytes)),
                  ],
                ),
              ),

            if (selectedFiles.isNotEmpty || isMergedPreviewReady)
              ElevatedButton(
                onPressed: isProcessing
                    ? null
                    : isMergedPreviewReady
                    ? exportPdf
                    : mergePdfs,
                child: isProcessing
                    ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
                    : Text(
                  isMergedPreviewReady
                      ? "Export PDF"
                      : "Merge PDFs",
                ),
              ),

            if (mergedPath != null)
              Expanded(
                child: PdfView(
                  controller: PdfController(
                    document:
                    PdfDocument.openFile(mergedPath!),
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
      padding:
      const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment:
        MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(
                  color: Colors.white54)),
          Text(value,
              style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFFF6B2B))),
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