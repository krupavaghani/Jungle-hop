import 'dart:async';

import 'package:audioplayers/audioplayers.dart';

/// Short SFX for gameplay. Respects [enabled] (sync); set from `settings_sfx`.
class GameSoundService {
  static const String kSfxPrefsKey = 'settings_sfx';

  final AudioPlayer _jump = AudioPlayer();
  final AudioPlayer _coin = AudioPlayer();

  bool enabled = true;

  GameSoundService() {
    for (final p in [_jump, _coin]) {
      unawaited(p.setReleaseMode(ReleaseMode.release));
    }
  }

  Future<void> dispose() async {
    await _jump.dispose();
    await _coin.dispose();
  }

  void playJump() {
    if (!enabled) return;
    _play(_jump, 'audio/jump.wav');
  }

  void playCoin() {
    if (!enabled) return;
    _play(_coin, 'audio/collectCoin.wav');
  }

  void _play(AudioPlayer player, String assetPath) {
    if (!enabled) return;
    unawaited(() async {
      try {
        await player.stop();
        await player.play(AssetSource(assetPath));
      } catch (_) {}
    }());
  }
}
