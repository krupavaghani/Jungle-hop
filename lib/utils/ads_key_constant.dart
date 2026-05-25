import 'package:flutter/foundation.dart';

class AdsKeyConstant {
  static const String testAppOpenAdUnitId = 'ca-app-pub-3940256099942544/9257395921';
  static const String appOpenAdUnitId = 'ca-app-pub-5608116751441902/3353834950';

  static const String testInterstitialAdUnitId = 'ca-app-pub-3940256099942544/1033173712';
  static const String interstitialAdUnitId = 'ca-app-pub-5608116751441902/5368666340';

  static const String testRewardedAdUnitId = 'ca-app-pub-3940256099942544/5224354917';
  static const String rewardedAdUnitId = 'ca-app-pub-5608116751441902/4447424776';

  
  static const String testBannerAdUnitId = 'ca-app-pub-3940256099942544/6300978111';
  static const String bannerAdUnitId = 'ca-app-pub-5608116751441902/5596854916';

  static const String testNativeAdvancedAdUnitId = 'ca-app-pub-3940256099942544/2247696110';
  static const String nativeAdvancedAdUnitId = 'ca-app-pub-5608116751441902/8003526400';

  static String getAppOpenAdUnitId() {
    return kDebugMode ? testAppOpenAdUnitId : appOpenAdUnitId;
  }
  static String getInterstitialAdUnitId() {
    return kDebugMode ? testInterstitialAdUnitId : interstitialAdUnitId;
  }
  static String getRewardedAdUnitId() {
    return kDebugMode ? testRewardedAdUnitId : rewardedAdUnitId;
  }
  static String getBannerAdUnitId() {
    return kDebugMode ? testBannerAdUnitId : bannerAdUnitId;
  }
  static String getNativeAdvancedAdUnitId() {
    return kDebugMode ? testNativeAdvancedAdUnitId : nativeAdvancedAdUnitId;
  }
}