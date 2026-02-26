import '../../data/scan_mlkit_service.dart';
import '../models/scanned_document_model.dart';

class ScanRepository {
  final ScanMlKitService _service;

  ScanRepository(this._service);

  Future<ScannedDocumentModel?> scanDocument() async {
    final result = await _service.scan();

    if (result?.pdf == null) return null;

    return ScannedDocumentModel(
      filePath: result!.pdf!.uri,
      pageCount: result.images.length,
      createdAt: DateTime.now(),
    );
  }
}