import 'package:google_mlkit_document_scanner/google_mlkit_document_scanner.dart';

class ScanMlKitService {
  final DocumentScanner _scanner = DocumentScanner(
    options: DocumentScannerOptions(
      mode: ScannerMode.full,
      documentFormat: DocumentFormat.pdf,
      isGalleryImport: true,
    ),
  );

  Future<DocumentScanningResult?> scan() async {
    return await _scanner.scanDocument();
  }
}