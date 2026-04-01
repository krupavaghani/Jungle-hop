import 'package:shared_preferences/shared_preferences.dart';

class LevelProgressService {
  static const String _unlockedKey = 'highest_unlocked_level';
  static const int maxLevel = 100;

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

  static Future<void> resetProgress() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_unlockedKey, 1);
  }
}
