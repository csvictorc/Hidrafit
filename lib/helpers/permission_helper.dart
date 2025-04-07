import 'package:permission_handler/permission_handler.dart';

class PermissionHelper {
  static Future<bool> checkActivityPermission() async {
    return await Permission.activityRecognition.isGranted;
  }

  static Future<bool> requestActivityPermission() async {
    final result = await Permission.activityRecognition.request();
    return result.isGranted;
  }
}