import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

/// Step 1 & 2: persistent guest id + random jungle player name.
class GuestPlayerService {
  static const _guestIdKey = 'leaderboard_guest_id';
  static const _playerNameKey = 'leaderboard_player_name';

  static const _adjectives = [
    'Swift',
    'Mighty',
    'Wild',
    'Brave',
    'Golden',
    'Shadow',
    'Jungle',
    'Turbo',
    'Epic',
    'Cosmic',
  ];

  static const _nouns = [
    'Kong',
    'Gorilla',
    'Monkey',
    'Tiger',
    'Panther',
    'Falcon',
    'Viper',
    'Hopper',
    'Ranger',
    'Champion',
  ];

  static final Random _random = Random();

  /// Step 1 — unique guest id stored locally.
  static Future<String> getOrCreateGuestId() async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getString(_guestIdKey);
    if (existing != null && existing.isNotEmpty) return existing;

    final guestId =
        'guest_${DateTime.now().millisecondsSinceEpoch}_${_random.nextInt(999999)}';
    await prefs.setString(_guestIdKey, guestId);
    return guestId;
  }

  /// Step 2 — random display name, generated once per install.
  static Future<String> getOrCreatePlayerName() async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getString(_playerNameKey);
    if (existing != null && existing.isNotEmpty) return existing;

    final name = generateRandomPlayerName();
    await prefs.setString(_playerNameKey, name);
    return name;
  }

  static String generateRandomPlayerName() {
    final adjective = _adjectives[_random.nextInt(_adjectives.length)];
    final noun = _nouns[_random.nextInt(_nouns.length)];
    final suffix = _random.nextInt(90) + 10;
    return '$adjective$noun$suffix';
  }

  /// Clears local guest profile (used when leaderboard data is reset).
  static Future<void> clearLocalProfile() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_guestIdKey);
    await prefs.remove(_playerNameKey);
  }
}
