import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';

/// Stable per-device id (survives app uninstall/reinstall on the same phone).
class DeviceIdService {
  static String? _cached;

  static Future<String> getDeviceId() async {
    if (_cached != null) return _cached!;

    final plugin = DeviceInfoPlugin();
    if (kIsWeb) {
      _cached = 'web_${DateTime.now().millisecondsSinceEpoch}';
      return _cached!;
    }

    if (Platform.isAndroid) {
      final info = await plugin.androidInfo;
      _cached = 'android_${info.id}';
    } else if (Platform.isIOS) {
      final info = await plugin.iosInfo;
      _cached = 'ios_${info.identifierForVendor ?? 'unknown'}';
    } else {
      _cached = 'other_${DateTime.now().millisecondsSinceEpoch}';
    }

    return _cached!;
  }
}
