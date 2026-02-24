import 'dart:io';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart' as sfpdf;
import 'package:pdfx/pdfx.dart';

class MergePdfPage extends StatefulWidget {
  const MergePdfPage({super.key});

  @override
  State<MergePdfPage> createState() => _MergePdfPageState();
}

class _MergePdfPageState extends State<MergePdfPage> {
  List<File> selectedFiles = [];
  String? mergedPath;
  bool isProcessing = false;

  Future<void> pickFiles() async {
    final typeGroup = XTypeGroup(label: 'PDF', extensions: ['pdf']);
    final files = await openFiles(acceptedTypeGroups: [typeGroup]);

    setState(() {
      selectedFiles = files.map((e) => File(e.path)).toList();
    });
  }

  Future<void> mergePdfs() async {
    if (selectedFiles.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Select at least 2 PDFs")),
      );
      return;
    }

    setState(() => isProcessing = true);

    try {
      final sfpdf.PdfDocument mergedDocument = sfpdf.PdfDocument();

      for (File file in selectedFiles) {
        final bytes = await file.readAsBytes();
        final sfpdf.PdfDocument document =
        sfpdf.PdfDocument(inputBytes: bytes);

        for (int i = 0; i < document.pages.count; i++) {
          mergedDocument.pages.add().graphics.drawPdfTemplate(
            document.pages[i].createTemplate(),
            const Offset(0, 0),
          );
        }

        document.dispose();
      }

      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/merged_output.pdf';

      final List<int> bytes = mergedDocument.saveSync();
      await File(filePath).writeAsBytes(bytes);

      mergedDocument.dispose();

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

            const SizedBox(height: 20),

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

            const SizedBox(height: 20),

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
}