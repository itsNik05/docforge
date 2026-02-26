import 'package:flutter/material.dart';
import '../../domain/models/scanned_document_model.dart';

class ScanResultBottomSheet extends StatelessWidget {
  final ScannedDocumentModel document;

  const ScanResultBottomSheet({super.key, required this.document});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        color: Colors.white,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            "Scan Completed",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          ListTile(
            leading: const Icon(Icons.picture_as_pdf),
            title: const Text("View Document"),
            onTap: () {
              Navigator.pop(context);
              // TODO: Navigate to PDF viewer
            },
          ),

          ListTile(
            leading: const Icon(Icons.share),
            title: const Text("Share"),
            onTap: () {
              Navigator.pop(context);
              // TODO: integrate ShareService
            },
          ),

          ListTile(
            leading: const Icon(Icons.delete),
            title: const Text("Delete"),
            onTap: () {
              Navigator.pop(context);
              // TODO: delete file
            },
          ),

          const SizedBox(height: 10),
        ],
      ),
    );
  }
}