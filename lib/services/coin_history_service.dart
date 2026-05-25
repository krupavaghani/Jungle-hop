import 'package:shared_preferences/shared_preferences.dart';

class CoinHistoryService {
  static const int maxLevel = 100;
  static const String _prefix = 'coins_level_';
  static const String _spentKey = 'coins_spent_total';
  static const String _iapKey = 'coins_iap_total';

  static String _keyForLevel(int level) => '$_prefix$level';

  static Future<void> addCoinsForLevel(int level, int coins) async {
    if (coins <= 0) return;
    final lv = level.clamp(1, maxLevel);
    final prefs = await SharedPreferences.getInstance();
    final key = _keyForLevel(lv);
    final current = prefs.getInt(key) ?? 0;
    await prefs.setInt(key, current + coins);
  }

  static Future<List<int>> getAllLevelCoins() async {
    final prefs = await SharedPreferences.getInstance();
    return List<int>.generate(
      maxLevel,
      (i) => prefs.getInt(_keyForLevel(i + 1)) ?? 0,
    );
  }

  static Future<int> getTotalCollectedCoins() async {
    final all = await getAllLevelCoins();
    return all.fold<int>(0, (sum, v) => sum + v);
  }

  static Future<int> getSpentCoins() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_spentKey) ?? 0;
  }

  static Future<int> getPurchasedCoins() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_iapKey) ?? 0;
  }

  static Future<void> grantPurchasedCoins(int amount) async {
    if (amount <= 0) return;
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getInt(_iapKey) ?? 0;
    await prefs.setInt(_iapKey, current + amount);
  }

  static Future<int> getAvailableCoins() async {
    final collected = await getTotalCollectedCoins();
    final purchased = await getPurchasedCoins();
    final spent = await getSpentCoins();
    final available = collected + purchased - spent;
    return available < 0 ? 0 : available;
  }

  static Future<bool> spendCoins(int amount) async {
    if (amount <= 0) return true;
    final prefs = await SharedPreferences.getInstance();
    final collected = await getTotalCollectedCoins();
    final spent = prefs.getInt(_spentKey) ?? 0;
    if (collected - spent < amount) return false;
    await prefs.setInt(_spentKey, spent + amount);
    return true;
  }

  static Future<void> resetAll() async {
    final prefs = await SharedPreferences.getInstance();
    for (int i = 1; i <= maxLevel; i++) {
      await prefs.remove(_keyForLevel(i));
    }
    await prefs.remove(_spentKey);
    await prefs.remove(_iapKey);
  }
}
