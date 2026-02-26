import 'package:flutter/material.dart';
import '../../domain/models/scanned_document_model.dart';

class ScanPreview extends StatelessWidget {
  final ScannedDocumentModel document;

  const ScanPreview({super.key, required this.document});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.picture_as_pdf, size: 60, color: Colors.red),
            const SizedBox(height: 12),
            Text(
              "Scanned Document",
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text("Pages: ${document.pageCount}"),
            const SizedBox(height: 4),
            Text(
              document.filePath,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}