import 'package:flutter/material.dart';
import '../../domain/models/scanned_document_model.dart';
import '../../domain/repositories/scan_repository.dart';
import '../../../../core/services/permission_service.dart';

class ScanProvider extends ChangeNotifier {
  final ScanRepository _repository;
  final PermissionService _permissionService;

  ScanProvider(this._repository, this._permissionService);

  bool _isScanning = false;
  bool get isScanning => _isScanning;

  ScannedDocumentModel? scannedFile;

  Future<void> startScan() async {
    final granted = await _permissionService.requestCameraPermission();

    if (!granted) return;

    _isScanning = true;
    notifyListeners();

    scannedFile = await _repository.scanDocument();

    _isScanning = false;
    notifyListeners();
  }
}