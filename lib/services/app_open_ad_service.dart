import 'dart:async';

import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:jungle_jumpping/utils/ads_key_constant.dart';

import 'premium_service.dart';

/// Test App Open ad unit (Google sample).
/// Loads and shows app open ads when the app returns from background.
class AppOpenAdService  {
  AppOpenAdService._();
  static final AppOpenAdService instance = AppOpenAdService._();

  AppOpenAd? _appOpenAd;
  bool _isLoading = false;
  bool _isShowingAd = false;
  bool _skipNextResume = true;
  bool _attached = false;
  bool _showWhenLoaded = false;
  bool _blockAppOpenForFullscreenAd = false;

  /// True while an interstitial/rewarded ad is on screen.
  bool get isFullscreenAdShowing => _blockAppOpenForFullscreenAd;

  /// Set while an interstitial/rewarded ad is on screen so app-open does not fire.
  void setFullscreenAdShowing(bool showing) {
    if (_blockAppOpenForFullscreenAd && !showing) {
      // Closing fullscreen ad triggers resumed; skip that resume for app-open.
      _skipNextResume = true;
    }
    _blockAppOpenForFullscreenAd = showing;
  }

  void attach() {
    if (_attached) return;
    _attached = true;
    PremiumService.instance.addListener(_onPremiumChanged);
    if (PremiumService.instance.canShowAds()) {
      _loadAd();
    }
  }

  void _onPremiumChanged() {
    if (!PremiumService.instance.canShowAds()) {
      _showWhenLoaded = false;
      _disposeCachedAd();
    } else if (_appOpenAd == null && !_isLoading) {
      _loadAd();
    }
  }

  void _disposeCachedAd() {
    _appOpenAd?.dispose();
    _appOpenAd = null;
  }

  void _loadAd() {
    if (!PremiumService.instance.canShowAds() ||
        _isLoading ||
        _appOpenAd != null) {
      return;
    }

    _isLoading = true;
    AppOpenAd.load(
      adUnitId: AdsKeyConstant.getAppOpenAdUnitId(),
      request: const AdRequest(),
      adLoadCallback: AppOpenAdLoadCallback(
        onAdLoaded: (ad) {
          _isLoading = false;
          _appOpenAd = ad;
        },
        onAdFailedToLoad: (error) {
          _isLoading = false;
          _appOpenAd = null;
          _showWhenLoaded = false;
        },
      ),
    );
  }

  void onAppPaused() {
    if (!PremiumService.instance.canShowAds()) return;
    if (_blockAppOpenForFullscreenAd) return;

    if (_appOpenAd == null) {
      _disposeCachedAd();
      _loadAd();
    }
  }

  Future<void> onAppResumed() async {
    if (!PremiumService.instance.canShowAds()) return;
    if (_blockAppOpenForFullscreenAd) return;

    if (_skipNextResume) {
      _skipNextResume = false;
      return;
    }

    _showAdIfAvailable();
  }

  void _showAdIfAvailable() async {
    if (!PremiumService.instance.canShowAds() ||
        _isShowingAd ||
        _blockAppOpenForFullscreenAd) {
      return;
    }

    if (_appOpenAd == null) {
      _disposeCachedAd();
      _showWhenLoaded = true;
      if (_isLoading) return;
      _loadAd();
      return;
    }

    final ad = _appOpenAd!;
    _isShowingAd = true;

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (_) {},
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _isShowingAd = false;
        _appOpenAd = null;
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _isShowingAd = false;
        _appOpenAd = null;
      },
    );

    ad.show();
  }
}
