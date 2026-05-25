/// In-app product IDs — must match Google Play Console / App Store Connect.
///
/// Coin packs use `coins_<amount>` (e.g. `coins_100` → 100 coins). Add or remove
/// IDs here when you add products in Play Console; the shop loads whatever the
/// store returns for these SKUs.
class IapProductIds {
  IapProductIds._();

  static const String removeAds = 'remove_ads';

  static const String bestValueCoinPack = 'coin_1000';

  static const List<String> coinPackIds = [
    'coin_100',
    'coin_250',
    'coin_500',
    'coin_1000',
    'coin_2500',
    'coin_5000',
  ];

  static Set<String> get coinPackIdSet => coinPackIds.toSet();
}
