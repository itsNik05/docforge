import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  /// Request Camera Permission
  Future<bool> requestCameraPermission() async {
    final status = await Permission.camera.request();

    if (status.isGranted) {
      return true;
    }

    if (status.isPermanentlyDenied) {
      await openAppSettings();
    }

    return false;
  }

  /// Check Camera Permission
  Future<bool> isCameraGranted() async {
    return await Permission.camera.isGranted;
  }
}