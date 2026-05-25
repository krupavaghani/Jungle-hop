import 'premium_service.dart';

/// @deprecated Use [PremiumService] instead. Kept for backward compatibility.
class AdsPreferencesService {
  static Future<bool> areAdsRemoved() async {
    if (!PremiumService.instance.isInitialized) {
      await PremiumService.instance.initialize();
    }
    return PremiumService.instance.isPremiumUser;
  }

  static Future<void> setAdsRemoved(bool value) async {
    if (value) {
      await PremiumService.instance.grantPremium();
    }
  }
}
