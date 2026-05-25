import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// Firestore document: `app_config/update`
///
/// Fields:
/// - `force_update` (bool): when true and version is below minimum, block the app
/// - `min_version` (string): minimum for all platforms, e.g. "1.0.0"
/// - `min_android_version` (string, optional): overrides min_version on Android
/// - `min_ios_version` (string, optional): overrides min_version on iOS
/// - `android_store_url` (string, optional)
/// - `ios_store_url` (string, optional)
/// - `message` (string, optional): shown on the force-update screen
class AppUpdateService {
  static const _configCollection = 'app_config';
  static const _updateDocId = 'update';

  static const androidStoreUrl =
      'https://play.google.com/store/apps/details?id=com.jungle.hop.app';
  static const iosStoreUrl =
      'https://apps.apple.com/app/id0000000000'; // Replace with your App Store ID

  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  static Future<AppUpdateCheckResult> checkForUpdate() async {
    if (kIsWeb) {
      return AppUpdateCheckResult.notRequired();
    }

    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;

      final snap = await _db
          .collection(_configCollection)
          .doc(_updateDocId)
          .get()
          .timeout(const Duration(seconds: 8));

      if (!snap.exists) {
        return AppUpdateCheckResult.notRequired(currentVersion: currentVersion);
      }

      final data = snap.data();
      if (data == null) {
        return AppUpdateCheckResult.notRequired(currentVersion: currentVersion);
      }

      final forceUpdate = data['force_update'] == true;
      if (!forceUpdate) {
        return AppUpdateCheckResult.notRequired(currentVersion: currentVersion);
      }

      final minVersion = _resolveMinVersion(data);
      if (minVersion.isEmpty) {
        return AppUpdateCheckResult.notRequired(currentVersion: currentVersion);
      }

      if (!_isVersionLower(currentVersion, minVersion)) {
        return AppUpdateCheckResult.notRequired(currentVersion: currentVersion);
      }

      final storeUrl = _resolveStoreUrl(data);
      final message = (data['message'] as String?)?.trim();

      return AppUpdateCheckResult(
        requiresUpdate: true,
        currentVersion: currentVersion,
        minVersion: minVersion,
        storeUrl: storeUrl,
        message: message?.isNotEmpty == true
            ? message!
            : 'A new version of Jungle Hop is available. Please update to keep playing.',
      );
    } catch (_) {
      return AppUpdateCheckResult.notRequired();
    }
  }

  static String _resolveMinVersion(Map<String, dynamic> data) {
    if (!kIsWeb && Platform.isAndroid) {
      final android = (data['min_android_version'] as String?)?.trim();
      if (android != null && android.isNotEmpty) return android;
    }
    if (!kIsWeb && Platform.isIOS) {
      final ios = (data['min_ios_version'] as String?)?.trim();
      if (ios != null && ios.isNotEmpty) return ios;
    }
    return (data['min_version'] as String?)?.trim() ?? '';
  }

  static String _resolveStoreUrl(Map<String, dynamic> data) {
    if (!kIsWeb && Platform.isAndroid) {
      final url = (data['android_store_url'] as String?)?.trim();
      if (url != null && url.isNotEmpty) return url;
      return androidStoreUrl;
    }
    if (!kIsWeb && Platform.isIOS) {
      final url = (data['ios_store_url'] as String?)?.trim();
      if (url != null && url.isNotEmpty) return url;
      return iosStoreUrl;
    }
    return androidStoreUrl;
  }

  static bool _isVersionLower(String current, String minimum) {
    final currentParts = _parseVersion(current);
    final minimumParts = _parseVersion(minimum);
    final length = currentParts.length > minimumParts.length
        ? currentParts.length
        : minimumParts.length;

    for (var i = 0; i < length; i++) {
      final c = i < currentParts.length ? currentParts[i] : 0;
      final m = i < minimumParts.length ? minimumParts[i] : 0;
      if (c < m) return true;
      if (c > m) return false;
    }
    return false;
  }

  static List<int> _parseVersion(String version) {
    return version
        .split('.')
        .map((part) => int.tryParse(part.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0)
        .toList();
  }

  static Future<String> getCurrentVersion() async {
    final info = await PackageInfo.fromPlatform();
    return info.version;
  }
}

class AppUpdateCheckResult {
  const AppUpdateCheckResult({
    required this.requiresUpdate,
    required this.currentVersion,
    this.minVersion = '',
    this.storeUrl = '',
    this.message = '',
  });

  factory AppUpdateCheckResult.notRequired({String currentVersion = ''}) {
    return AppUpdateCheckResult(
      requiresUpdate: false,
      currentVersion: currentVersion,
    );
  }

  final bool requiresUpdate;
  final String currentVersion;
  final String minVersion;
  final String storeUrl;
  final String message;
}
