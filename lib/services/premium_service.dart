import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Local premium state (no login). Interstitials, banners, app-open, and
/// native ads respect [canShowAds]. Rewarded ads are always available.
class PremiumService extends ChangeNotifier {
  PremiumService._();
  static final PremiumService instance = PremiumService._();

  static const String _premiumKey = 'is_premium_user';
  static const String _legacyAdsRemovedKey = 'ads_removed';

  bool _isPremiumUser = false;
  bool _initialized = false;

  bool get isPremiumUser => _isPremiumUser;
  bool get isInitialized => _initialized;

  bool canShowAds() => !_isPremiumUser;

  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getBool(_premiumKey);
    if (stored != null) {
      _isPremiumUser = stored;
    } else {
      _isPremiumUser = prefs.getBool(_legacyAdsRemovedKey) ?? false;
      if (_isPremiumUser) {
        await prefs.setBool(_premiumKey, true);
      }
    }
    _initialized = true;
    notifyListeners();
  }

  Future<void> grantPremium() async {
    if (_isPremiumUser) return;
    _isPremiumUser = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_premiumKey, true);
    await prefs.setBool(_legacyAdsRemovedKey, true);
    notifyListeners();
  }

  Future<void> revokePremiumForTesting() async {
    _isPremiumUser = false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_premiumKey, false);
    await prefs.setBool(_legacyAdsRemovedKey, false);
    notifyListeners();
  }
}
