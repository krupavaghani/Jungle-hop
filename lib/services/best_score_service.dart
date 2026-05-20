import 'package:shared_preferences/shared_preferences.dart';

/// Persists highest score per level (SharedPreferences).
class BestScoreService {
  static const int maxLevel = 100;
  static const String _prefix = 'best_score_level_';

  static String _key(int level) => '$_prefix${level.clamp(1, maxLevel)}';

  static Future<int> getBestForLevel(int level) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_key(level)) ?? 0;
  }

  /// Updates stored best if [score] is higher; returns the best value to display.
  static Future<int> recordScore(int level, int score) async {
    final s = score < 0 ? 0 : score;
    final prefs = await SharedPreferences.getInstance();
    final key = _key(level);
    final previous = prefs.getInt(key) ?? 0;
    if (s > previous) {
      await prefs.setInt(key, s);
      return s;
    }
    return previous;
  }

  static Future<void> resetAll() async {
    final prefs = await SharedPreferences.getInstance();
    for (int i = 1; i <= maxLevel; i++) {
      await prefs.remove(_key(i));
    }
  }
}
