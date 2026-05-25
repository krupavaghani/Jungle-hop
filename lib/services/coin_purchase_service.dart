import 'dart:async';

import 'package:in_app_purchase/in_app_purchase.dart';

import '../utils/iap_product_ids.dart';
import 'coin_history_service.dart';

/// One coin pack loaded from Google Play / App Store.
class CoinPack {
  final ProductDetails product;
  final int coins;
  final String imageAsset;
  final bool isBestValue;

  const CoinPack({
    required this.product,
    required this.coins,
    required this.imageAsset,
    this.isBestValue = false,
  });

  String get productId => product.id;
  String get localizedPrice => product.price;
}

/// Fetches coin pack products from the store and handles consumable purchases.
class CoinPurchaseService {
  CoinPurchaseService._();
  static final CoinPurchaseService instance = CoinPurchaseService._();

  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _subscription;

  bool _storeAvailable = false;
  bool _loading = true;
  String? _loadError;
  List<CoinPack> _packs = [];
  String? _purchasingProductId;
  final StreamController<CoinPurchaseResult> _purchaseResultController =
      StreamController<CoinPurchaseResult>.broadcast();

  bool get storeAvailable => _storeAvailable;
  bool get isLoading => _loading;
  String? get loadError => _loadError;
  List<CoinPack> get packs => List.unmodifiable(_packs);
  String? get purchasingProductId => _purchasingProductId;
  Stream<CoinPurchaseResult> get purchaseResults =>
      _purchaseResultController.stream;

  Future<void> initialize() async {
    _storeAvailable = await _iap.isAvailable();
    if (!_storeAvailable) {
      _loading = false;
      _loadError = 'Store is not available';
      return;
    }

    _subscription ??= _iap.purchaseStream.listen(
      _onPurchaseUpdates,
      onError: (_) {},
    );

    await refreshProducts();
  }

  Future<void> refreshProducts() async {
    if (!_storeAvailable) {
      _packs = [];
      _loading = false;
      return;
    }

    _loading = true;
    _loadError = null;

    final response =
        await _iap.queryProductDetails(IapProductIds.coinPackIdSet);

    if (response.error != null) {
      _loadError = response.error!.message;
      _packs = [];
      _loading = false;
      return;
    }

    final built = <CoinPack>[];
    for (final product in response.productDetails) {
      final coins = parseCoinsFromProductId(product.id);
      if (coins == null || coins <= 0) continue;
      built.add(
        CoinPack(
          product: product,
          coins: coins,
          imageAsset: imageAssetForCoins(coins),
        ),
      );
    }

    built.sort((a, b) => a.coins.compareTo(b.coins));
    _packs = _markBestValue(built);
    _loading = false;
  }

  /// Parses coin amount from product id: `coins_100`, `coin_1000`, etc.
  static int? parseCoinsFromProductId(String productId) {
    final match = RegExp(r'coins?_?(\d+)', caseSensitive: false)
        .firstMatch(productId);
    if (match == null) return null;
    return int.tryParse(match.group(1)!);
  }

  static String imageAssetForCoins(int coins) =>
      'assets/images/${coins}Coin.png';

  static List<CoinPack> _markBestValue(List<CoinPack> packs) {
    return [
      for (final pack in packs)
        CoinPack(
          product: pack.product,
          coins: pack.coins,
          imageAsset: pack.imageAsset,
          isBestValue: pack.productId == IapProductIds.bestValueCoinPack,
        ),
    ];
  }

  Future<bool> buyPack(CoinPack pack) async {
    if (!_storeAvailable) return false;
    if (_purchasingProductId != null) return false;

    _purchasingProductId = pack.productId;
    try {
      return await _iap.buyConsumable(
        purchaseParam: PurchaseParam(productDetails: pack.product),
        autoConsume: true,
      );
    } catch (_) {
      _purchasingProductId = null;
      return false;
    }
  }

  Future<void> _onPurchaseUpdates(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      if (!IapProductIds.coinPackIdSet.contains(purchase.productID)) {
        continue;
      }

      switch (purchase.status) {
        case PurchaseStatus.purchased:
          final coins = parseCoinsFromProductId(purchase.productID);
          if (coins != null && coins > 0) {
            await CoinHistoryService.grantPurchasedCoins(coins);
            _purchaseResultController.add(
              CoinPurchaseResult.success(coins: coins),
            );
          } else {
            _purchaseResultController.add(
              const CoinPurchaseResult.failed(
                message: 'Unknown coin pack.',
              ),
            );
          }
          if (purchase.pendingCompletePurchase) {
            await _iap.completePurchase(purchase);
          }
          _purchasingProductId = null;
        case PurchaseStatus.pending:
          break;
        case PurchaseStatus.canceled:
          _purchaseResultController.add(const CoinPurchaseResult.canceled());
          if (purchase.pendingCompletePurchase) {
            await _iap.completePurchase(purchase);
          }
          _purchasingProductId = null;
        case PurchaseStatus.error:
          _purchaseResultController.add(
            CoinPurchaseResult.failed(
              message: purchase.error?.message ?? 'Purchase failed.',
            ),
          );
          if (purchase.pendingCompletePurchase) {
            await _iap.completePurchase(purchase);
          }
          _purchasingProductId = null;
        case PurchaseStatus.restored:
          // Consumables should not restore; complete and ignore.
          if (purchase.pendingCompletePurchase) {
            await _iap.completePurchase(purchase);
          }
          _purchasingProductId = null;
      }
    }
  }

  Future<void> dispose() async {
    await _subscription?.cancel();
    _subscription = null;
    await _purchaseResultController.close();
  }
}

class CoinPurchaseResult {
  final bool success;
  final bool canceled;
  final int? coins;
  final String? message;

  const CoinPurchaseResult._({
    required this.success,
    required this.canceled,
    this.coins,
    this.message,
  });

  const CoinPurchaseResult.success({required int coins})
      : this._(success: true, canceled: false, coins: coins);

  const CoinPurchaseResult.canceled()
      : this._(success: false, canceled: true);

  const CoinPurchaseResult.failed({required String message})
      : this._(success: false, canceled: false, message: message);
}
