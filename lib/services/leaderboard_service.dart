import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/leaderboard_entry.dart';
import 'coin_history_service.dart';
import 'device_id_service.dart';
import 'guest_player_service.dart';

/// Step 3–5: Firestore leaderboard — save score & fetch top players.
class LeaderboardService {
  static const _collection = 'leaderboard';
  static const int topLimit = 10;

  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  static CollectionReference<Map<String, dynamic>> get _players =>
      _db.collection(_collection);

  /// After uninstall + reinstall, local guest id is new but device id is the same.
  /// Deletes the previous install's Firestore row for this device.
  static Future<void> _removePreviousInstallRecords({
    required String deviceId,
    required String currentGuestId,
  }) async {
    final snapshot =
        await _players.where('deviceId', isEqualTo: deviceId).get();

    for (final doc in snapshot.docs) {
      if (doc.id != currentGuestId) {
        await doc.reference.delete();
      }
    }
  }

  /// Deletes the current player's leaderboard document (e.g. game data reset).
  static Future<void> deleteCurrentPlayer() async {
    final guestId = await GuestPlayerService.getOrCreateGuestId();
    await _players.doc(guestId).delete();
    await GuestPlayerService.clearLocalProfile();
  }

  /// Ensures guest profile exists in Firestore.
  static Future<({String guestId, String playerName})> ensureGuestProfile() async {
    final guestId = await GuestPlayerService.getOrCreateGuestId();
    final playerName = await GuestPlayerService.getOrCreatePlayerName();
    final deviceId = await DeviceIdService.getDeviceId();

    await _removePreviousInstallRecords(
      deviceId: deviceId,
      currentGuestId: guestId,
    );

    final doc = _players.doc(guestId);
    final snap = await doc.get();
    if (!snap.exists) {
      await doc.set({
        'guestId': guestId,
        'playerName': playerName,
        'deviceId': deviceId,
        'score': 0,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } else {
      await doc.set({
        'deviceId': deviceId,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }

    return (guestId: guestId, playerName: playerName);
  }

  /// Step 4 — save score (keeps highest value).
  static Future<void> saveScore(int score) async {
    if (score < 0) return;

    final profile = await ensureGuestProfile();
    final deviceId = await DeviceIdService.getDeviceId();
    final doc = _players.doc(profile.guestId);
    final snap = await doc.get();
    final current = (snap.data()?['score'] as num?)?.toInt() ?? 0;
    final nextScore = score > current ? score : current;

    await doc.set({
      'guestId': profile.guestId,
      'playerName': profile.playerName,
      'deviceId': deviceId,
      'score': nextScore,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Sync from local coin balance (leaderboard uses available coins).
  static Future<void> syncCurrentScore() async {
    final coins = await CoinHistoryService.getAvailableCoins();
    await saveScore(coins);
  }

  /// Step 5 — load top players once (read-only, no live updates).
  static Future<List<LeaderboardEntry>> fetchTopPlayers({int limit = topLimit}) async {
    final snapshot = await _players
        .orderBy('score', descending: true)
        .limit(limit)
        .get();

    return snapshot.docs
        .map((doc) => LeaderboardEntry.fromMap(doc.id, doc.data()))
        .toList();
  }

  static Future<String> currentGuestId() =>
      GuestPlayerService.getOrCreateGuestId();
}
