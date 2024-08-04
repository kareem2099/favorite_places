import 'package:permission_handler/permission_handler.dart';

class PermissionHandler {
  // Check and request camera permission
  Future<bool> requestCameraPermission() async {
    var status = await Permission.camera.status;
    if (status.isGranted) {
      return true;
    } else if (status.isDenied || status.isRestricted || status.isLimited) {
      status = await Permission.camera.request();
      return status.isGranted;
    } else {
      return false;
    }
  }

  // Check and request location permission
  Future<bool> requestLocationPermission() async {
    var status = await Permission.location.status;
    if (status.isGranted) {
      return true;
    } else if (status.isDenied || status.isRestricted || status.isLimited) {
      status = await Permission.location.request();
      return status.isGranted;
    } else {
      return false;
    }
  }

  // Check and request storage permission
  Future<bool> requestStoragePermission() async {
    var status = await Permission.storage.status;
    if (status.isGranted) {
      return true;
    } else if (status.isDenied || status.isRestricted || status.isLimited) {
      status = await Permission.storage.request();
      return status.isGranted;
    } else {
      return false;
    }
  }
}
