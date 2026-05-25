import 'package:shared_preferences/shared_preferences.dart';

class LevelProgressService {
  static const String _unlockedKey = 'highest_unlocked_level';
  static const String _starsKeyPrefix = 'level_stars_';
  static const int maxLevel = 100;
  static const int maxStars = 3;

  static Future<int> getHighestUnlockedLevel() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getInt(_unlockedKey) ?? 1;
    return value.clamp(1, maxLevel);
  }

  static Future<void> unlockLevel(int level) async {
    final prefs = await SharedPreferences.getInstance();
    final current = (prefs.getInt(_unlockedKey) ?? 1).clamp(1, maxLevel);
    final next = level.clamp(1, maxLevel);
    if (next > current) {
      await prefs.setInt(_unlockedKey, next);
    }
  }

  static Future<void> unlockNextAfter(int completedLevel) async {
    if (completedLevel >= maxLevel) return;
    await unlockLevel(completedLevel + 1);
  }

  static String _starsKey(int level) => '$_starsKeyPrefix$level';

  /// Stars earned from remaining lives (1–3). Keeps the best result per level.
  static Future<void> recordStars(int level, int stars) async {
    final prefs = await SharedPreferences.getInstance();
    final clamped = stars.clamp(1, maxStars);
    final key = _starsKey(level.clamp(1, maxLevel));
    final current = prefs.getInt(key) ?? 0;
    if (clamped > current) {
      await prefs.setInt(key, clamped);
    }
  }

  static Future<int> getStarsForLevel(int level) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_starsKey(level.clamp(1, maxLevel))) ?? 0;
  }

  static Future<Map<int, int>> getAllLevelStars() async {
    final prefs = await SharedPreferences.getInstance();
    final stars = <int, int>{};
    for (final key in prefs.getKeys()) {
      if (!key.startsWith(_starsKeyPrefix)) continue;
      final level = int.tryParse(key.substring(_starsKeyPrefix.length));
      final value = prefs.getInt(key);
      if (level != null && value != null && value > 0) {
        stars[level] = value.clamp(1, maxStars);
      }
    }
    return stars;
  }

  static Future<void> resetProgress() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_unlockedKey, 1);
    for (final key in prefs.getKeys()) {
      if (key.startsWith(_starsKeyPrefix)) {
        await prefs.remove(key);
      }
    }
  }
}
