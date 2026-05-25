import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';

import '../utils/iap_product_ids.dart';
import 'premium_service.dart';

enum RestorePurchaseResult {
  restored,
  alreadyPremium,
  nothingFound,
  storeUnavailable,
  failed,
}

/// Google Play / App Store non-consumable for ad-free play (no account required).
class RemoveAdsPurchaseService {
  RemoveAdsPurchaseService._();
  static final RemoveAdsPurchaseService instance = RemoveAdsPurchaseService._();

  static const String productId = IapProductIds.removeAds;

  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _subscription;
  ProductDetails? _productDetails;
  bool _storeAvailable = false;
  bool _purchaseInFlight = false;
  final StreamController<void> _purchaseSettledController =
      StreamController<void>.broadcast();

  bool get storeAvailable => _storeAvailable;
  Stream<void> get purchaseSettled => _purchaseSettledController.stream;
  ProductDetails? get productDetails => _productDetails;
  String? get localizedPrice => _productDetails?.price;

  Future<void> initialize() async {
    _storeAvailable = await _iap.isAvailable();
    if (!_storeAvailable) return;

    _subscription ??= _iap.purchaseStream.listen(
      _onPurchaseUpdates,
      onError: (_) {},
    );

    await _loadProductDetails();
    await syncPurchasesFromStore();
  }

  Future<void> dispose() async {
    await _subscription?.cancel();
    _subscription = null;
    await _purchaseSettledController.close();
  }

  Future<void> _loadProductDetails() async {
    if (!_storeAvailable) return;
    final response = await _iap.queryProductDetails({productId});
    if (response.productDetails.isNotEmpty) {
      _productDetails = response.productDetails.first;
    }
  }

  /// Called on app start and after restore — checks Play Store ownership.
  Future<void> syncPurchasesFromStore() async {
    if (!_storeAvailable) return;

    if (defaultTargetPlatform == TargetPlatform.android) {
      final android = _iap.getPlatformAddition<InAppPurchaseAndroidPlatformAddition>();
      final response = await android.queryPastPurchases();
      for (final purchase in response.pastPurchases) {
        if (_isOwnedRemoveAds(purchase)) {
          await PremiumService.instance.grantPremium();
          return;
        }
      }
    }

    // iOS / fallback: restore delivers owned items on the purchase stream.
    await _iap.restorePurchases();
  }

  Future<bool> buyRemoveAds() async {
    if (PremiumService.instance.isPremiumUser) return true;
    if (!_storeAvailable) return false;
    if (_purchaseInFlight) return false;

    if (_productDetails == null) {
      await _loadProductDetails();
    }
    final product = _productDetails;
    if (product == null) return false;

    _purchaseInFlight = true;
    try {
      return await _iap.buyNonConsumable(
        purchaseParam: PurchaseParam(productDetails: product),
      );
    } finally {
      _purchaseInFlight = false;
    }
  }

  Future<RestorePurchaseResult> restorePurchases() async {
    if (PremiumService.instance.isPremiumUser) {
      return RestorePurchaseResult.alreadyPremium;
    }
    if (!_storeAvailable) {
      return RestorePurchaseResult.storeUnavailable;
    }

    try {
      await syncPurchasesFromStore();
      if (PremiumService.instance.isPremiumUser) {
        return RestorePurchaseResult.restored;
      }
      return RestorePurchaseResult.nothingFound;
    } catch (_) {
      return RestorePurchaseResult.failed;
    }
  }

  bool _isOwnedRemoveAds(PurchaseDetails purchase) {
    if (purchase.productID != productId) return false;
    return purchase.status == PurchaseStatus.purchased ||
        purchase.status == PurchaseStatus.restored;
  }

  Future<void> _onPurchaseUpdates(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      if (purchase.productID != productId) continue;

      switch (purchase.status) {
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          await PremiumService.instance.grantPremium();
          if (purchase.pendingCompletePurchase) {
            await _iap.completePurchase(purchase);
          }
        case PurchaseStatus.pending:
          break;
        case PurchaseStatus.canceled:
        case PurchaseStatus.error:
          if (purchase.pendingCompletePurchase) {
            await _iap.completePurchase(purchase);
          }
          _purchaseSettledController.add(null);
      }
    }
  }
}
