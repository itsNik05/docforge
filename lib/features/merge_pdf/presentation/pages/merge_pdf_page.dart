import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

class MergePdfPage extends StatefulWidget {
  const MergePdfPage({super.key});

  @override
  State<MergePdfPage> createState() => _MergePdfPageState();
}

class _MergePdfPageState extends State<MergePdfPage> {
  bool isMerging = false;
  String? savedPath;

  Future<void> mergePdfs() async {
    setState(() => isMerging = true);

    try {
      final ByteData data1 =
      await rootBundle.load('assets/pdfs/sample1.pdf');
      final ByteData data2 =
      await rootBundle.load('assets/pdfs/sample2.pdf');

      final PdfDocument document1 =
      PdfDocument(inputBytes: data1.buffer.asUint8List());
      final PdfDocument document2 =
      PdfDocument(inputBytes: data2.buffer.asUint8List());

      // 🔥 NEW MERGE METHOD
      final PdfDocument mergedDocument = PdfDocument();
      mergedDocument.pages.add().graphics.drawPdfTemplate(
        document1.pages[0].createTemplate(),
        const Offset(0, 0),
      );

      for (int i = 1; i < document1.pages.count; i++) {
        mergedDocument.pages.add().graphics.drawPdfTemplate(
          document1.pages[i].createTemplate(),
          const Offset(0, 0),
        );
      }

      for (int i = 0; i < document2.pages.count; i++) {
        mergedDocument.pages.add().graphics.drawPdfTemplate(
          document2.pages[i].createTemplate(),
          const Offset(0, 0),
        );
      }

      final List<int> bytes = await mergedDocument.save();

      document1.dispose();
      document2.dispose();
      mergedDocument.dispose();

      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/merged_output.pdf';
      final file = File(filePath);
      await file.writeAsBytes(bytes);

      setState(() {
        savedPath = filePath;
        isMerging = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("PDFs merged successfully!")),
      );
    } catch (e) {
      setState(() => isMerging = false);
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
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: isMerging ? null : mergePdfs,
              child: isMerging
                  ? const CircularProgressIndicator()
                  : const Text("Merge Sample PDFs"),
            ),
            const SizedBox(height: 30),
            if (savedPath != null)
              Text(
                "Saved at:\n$savedPath",
                textAlign: TextAlign.center,
              ),
          ],
        ),
      ),
    );
  }
}