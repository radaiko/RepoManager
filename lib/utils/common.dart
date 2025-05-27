import 'dart:io';

import 'package:path_provider/path_provider.dart';

class Common {
  static Future<String> getAppSupportPath() async {
    // Use getApplicationSupportDirectory for app-specific support files
    final directory = await getApplicationSupportDirectory();
    return directory.path;
  }

  static Future<String> getAppDataPath() async {
    // Use getApplicationDocumentsDirectory for persistent app data
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  static Future<String> getTempPath() async {
    // Use getTemporaryDirectory for temporary files
    final directory = await getTemporaryDirectory();
    return directory.path;
  }

  static String getCurrentDevice() {
    if (Platform.isAndroid) {
      return 'Android';
    } else if (Platform.isIOS) {
      return 'iOS';
    } else if (Platform.isMacOS) {
      return 'macOS';
    } else if (Platform.isWindows) {
      return 'Windows';
    } else if (Platform.isLinux) {
      return 'Linux';
    } else {
      return 'Unknown Device';
    }
  }
}
