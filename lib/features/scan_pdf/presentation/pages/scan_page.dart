import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../provider/scan_provider.dart';
import '../widgets/scan_result_bottom_sheet.dart';

class ScanPage extends StatelessWidget {
  const ScanPage({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ScanProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text("Scan Document")),
      body: Center(
        child: provider.isScanning
            ? const CircularProgressIndicator()
            : ElevatedButton(
          onPressed: () async {
            await provider.startScan();
            if (provider.scannedFile != null) {
              showModalBottomSheet(
                context: context,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                builder: (_) => ScanResultBottomSheet(
                  document: provider.scannedFile!,
                ),
              );
            }
          },
          child: const Text("Start Scanning"),
        ),
      ),
    );
  }
}