import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:jungle_jumpping/utils/ads_key_constant.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../game/game_background.dart';
import '../game/game_constants.dart';
import '../game/game_models.dart';
import '../game/game_world_painter.dart';
import '../game/level_builder.dart';
import '../services/app_open_ad_service.dart';
import '../services/best_score_service.dart';
import '../services/coin_history_service.dart';
import '../services/game_sound_service.dart';
import '../services/leaderboard_service.dart';
import '../services/level_progress_service.dart';
import '../services/premium_service.dart';
import '../utils/colors.dart';
import '../widgets/level_complete_dialog.dart';
import 'game_over_screen.dart';
import 'pause_screen.dart';

export '../game/game_constants.dart' show kMaxLevel;

class GameScreen extends StatefulWidget {
  final int level;
  const GameScreen({super.key, this.level = 1});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen>
    with SingleTickerProviderStateMixin {
  static const String _usingCharacterKey = 'shop_using_character';
  static const Map<String, String> _characterEmojiMap = {
    'Monkey': '🐒',
    'Panda': '🐼',
    'Koala': '🐨',
    'Frog': '🐸',
    'Fox': '🦊',
    'Tiger': '🐯',
    'Rabbit': '🐰',
    'Deer': '🦌',
    'Zebra': '🦓',
    'Bear': '🐻',
    'Lion': '🦁',
    'Wolf': '🐺',
    'Gorilla': '🦍',
    'Elephant': '🐘',
  };

  late Ticker _ticker;
  Duration _lastElapsed = Duration.zero;

  // ── Level data ───────────────────────────────
  late LevelData _level;

  // ── Player ───────────────────────────────────
  static const double _pW = kTile * 0.72;
  static const double _pH = kTile * 0.88;
  double _px = kTile * 2;
  double _py = kWorldH - kTile - _pH;
  double _pvx = 0;
  double _pvy = 0;
  bool _onGround = false;
  bool _doubleJumpUsed = false;
  bool _invincible = false;
  double _invincibleTimer = 0;

  // Long-press power jump
  bool _isCharging = false;
  DateTime? _pressStart;
  double _chargeRatio = 0.0;
  static const int _maxChargeMs = 500;

  // ── Camera ───────────────────────────────────
  double _camX = 0;

  // ── Game state ───────────────────────────────
  int _score = 0;
  int _coins = 0;
  int _lives = 3;
  int _currentLevel = 1;
  bool _isPlaying = true;
  bool _levelComplete = false;

  // ── Misc ─────────────────────────────────────
  final Random _rng = Random();
  double _timeElapsed = 0;
  double _runSpeed = kRunSpeed;
  String _playerEmoji = '🐒';
  final GameSoundService _sounds = GameSoundService();
  InterstitialAd? _interstitialAd;
  bool _isInterstitialLoading = false;
  RewardedAd? _rewardedAd;
  bool _isRewardedLoading = false;

  final GameWorldSnapshot _snapshot = GameWorldSnapshot();
  final ValueNotifier<int> _repaint = ValueNotifier(0);
  late final WorldPainter _worldPainter =
      WorldPainter(_snapshot, repaint: _repaint);
  double _screenScale = 1;

  @override
  void initState() {
    super.initState();
    PremiumService.instance.addListener(_onPremiumChanged);
    _currentLevel = widget.level.clamp(1, kMaxLevel);
    final difficulty = (_currentLevel - 1) / (kMaxLevel - 1);
    _runSpeed = kRunSpeed + (difficulty * 120.0);
    _level = buildLevel(_currentLevel);
    _loadSelectedCharacter();
    _refreshSoundPrefs();
    _initAds();
    _snapshot.level = _level;
    _snapshot.goalX = _level.goalX;
    _syncFrame();
    _ticker = createTicker(_tick)..start();
  }

  void _onPremiumChanged() {
    if (!mounted) return;
    if (!PremiumService.instance.canShowAds()) {
      _interstitialAd?.dispose();
      _interstitialAd = null;
      _isInterstitialLoading = false;
    } else {
      _loadInterstitialAd();
    }
    setState(() {});
  }

  void _initAds() {
    _loadRewardedAd();
    if (PremiumService.instance.canShowAds()) {
      _loadInterstitialAd();
    }
  }

  bool _usesRewardedAdOnLevelComplete() => _currentLevel % 3 == 0;

  void _loadInterstitialAd() {
    if (!PremiumService.instance.canShowAds() ||
        _isInterstitialLoading ||
        _interstitialAd != null) {
      return;
    }
    _isInterstitialLoading = true;
    InterstitialAd.load(
      adUnitId: AdsKeyConstant.getInterstitialAdUnitId(),
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _isInterstitialLoading = false;
          _interstitialAd = ad;
        },
        onAdFailedToLoad: (error) {
          _isInterstitialLoading = false;
          _interstitialAd = null;
        },
      ),
    );
  }

  Future<void> _showInterstitialIfAvailable() async {
    if (!PremiumService.instance.canShowAds()) return;
    final ad = _interstitialAd;
    if (ad == null) {
      _loadInterstitialAd();
      return;
    }
    final completer = Completer<void>();
    final appOpenAds = AppOpenAdService.instance;
    appOpenAds.setFullscreenAdShowing(true);
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        appOpenAds.setFullscreenAdShowing(false);
        ad.dispose();
        if (!completer.isCompleted) completer.complete();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        appOpenAds.setFullscreenAdShowing(false);
        ad.dispose();
        if (!completer.isCompleted) completer.complete();
      },
    );
    _interstitialAd = null;
    ad.show();
    await completer.future;
    _loadInterstitialAd();
  }

  void _loadRewardedAd() {
    if (_isRewardedLoading || _rewardedAd != null) return;
    _isRewardedLoading = true;
    RewardedAd.load(
      adUnitId: AdsKeyConstant.getRewardedAdUnitId(),
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _isRewardedLoading = false;
          _rewardedAd = ad;
        },
        onAdFailedToLoad: (error) {
          _isRewardedLoading = false;
          _rewardedAd = null;
        },
      ),
    );
  }

  Future<void> _showRewardedIfAvailable() async {
    final ad = _rewardedAd;
    if (ad == null) {
      _loadRewardedAd();
      if (PremiumService.instance.canShowAds()) {
        await _showInterstitialIfAvailable();
      }
      return;
    }
    final completer = Completer<void>();
    final appOpenAds = AppOpenAdService.instance;
    appOpenAds.setFullscreenAdShowing(true);
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        appOpenAds.setFullscreenAdShowing(false);
        ad.dispose();
        if (!completer.isCompleted) completer.complete();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        appOpenAds.setFullscreenAdShowing(false);
        ad.dispose();
        if (!completer.isCompleted) completer.complete();
      },
    );
    _rewardedAd = null;
    ad.show(onUserEarnedReward: (_, __) {});
    await completer.future;
    _loadRewardedAd();
  }

  Future<void> _showLevelCompleteAd() async {
    if (_usesRewardedAdOnLevelComplete()) {
      await _showRewardedIfAvailable();
    } else {
      await _showInterstitialIfAvailable();
    }
  }

  Future<void> _refreshSoundPrefs() async {
    final p = await SharedPreferences.getInstance();
    if (!mounted) return;
    _sounds.enabled = p.getBool(GameSoundService.kSfxPrefsKey) ?? true;
  }

  Future<void> _loadSelectedCharacter() async {
    final prefs = await SharedPreferences.getInstance();
    final usingName = prefs.getString(_usingCharacterKey) ?? 'Monkey';
    final emoji = _characterEmojiMap[usingName] ?? '🐒';
    if (!mounted) return;
    setState(() => _playerEmoji = emoji);
  }


  void _syncFrame() {
    _snapshot.level = _level;
    _snapshot.camX = _camX;
    _snapshot.scale = _screenScale;
    _snapshot.px = _px;
    _snapshot.py = _py;
    _snapshot.pW = _pW;
    _snapshot.pH = _pH;
    _snapshot.invincible = _invincible;
    _snapshot.invTimer = _invincibleTimer;
    _snapshot.goalX = _level.goalX;
    _snapshot.timeElapsed = _timeElapsed;
    _snapshot.playerEmoji = _playerEmoji;
    _repaint.value++;
  }

  @override
  void dispose() {
    _repaint.dispose();
    PremiumService.instance.removeListener(_onPremiumChanged);
    _ticker.dispose();
    _interstitialAd?.dispose();
    _rewardedAd?.dispose();
    _sounds.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────────
  //  Game Loop
  // ─────────────────────────────────────────────

  void _tick(Duration elapsed) {
    if (!_isPlaying || !mounted) return;
    final dt = _lastElapsed == Duration.zero
        ? 0.0
        : (elapsed - _lastElapsed).inMicroseconds / 1e6;
    _lastElapsed = elapsed;
    if (dt <= 0 || dt > 0.05) return;

    var coinCollected = false;
    _timeElapsed += dt;

    if (_isCharging && _pressStart != null) {
      final ms = DateTime.now().difference(_pressStart!).inMilliseconds;
      _chargeRatio = (ms / _maxChargeMs).clamp(0.0, 1.0);
    } else {
      _chargeRatio = 0.0;
    }

    _updatePlayer(dt);
    _updateEnemies(dt);
    coinCollected = _updateCollectibles(dt);
    _updateCamera();
    _updateEffects(dt);
    _checkLevelComplete();

    if (_invincible) {
      _invincibleTimer -= dt;
      if (_invincibleTimer <= 0) _invincible = false;
    }

    _syncFrame();
    if (coinCollected) {
      _sounds.playCoin();
    }
  }

  // ─────────────────────────────────────────────
  //  Player Physics
  // ─────────────────────────────────────────────

  void _updatePlayer(double dt) {
    // Auto-run right
    _pvx = _runSpeed;

    // Gravity
    _pvy += kGravity * dt;

    // Variable jump-height while button is held:
    // jump starts immediately on press, and holding reduces fall / adds lift.
    if (_isCharging && _pvy < 0 && _pressStart != null) {
      final holdMs = DateTime.now().difference(_pressStart!).inMilliseconds;
      final holdT = (holdMs / _maxChargeMs).clamp(0.0, 1.0);
      // Extra upward acceleration while rising (stronger as hold time increases).
      _pvy -= (1900.0 * holdT + 450.0) * dt;
    }

    // Proposed new position
    double nx = _px + _pvx * dt;
    double ny = _py + _pvy * dt;

    // Clamp to world
    nx = nx.clamp(0, _level.worldWidth - _pW);

    // ── Horizontal platform collision ────────
    final hRect = Rect2(nx, _py + 4, _pW, _pH - 8);
    for (final p in _level.platforms) {
      if (p.broken) continue;
      if (hRect.overlaps(p.bounds)) {
        // Special rule: hitting a pipe from the side costs one life
        // and nudges the player past it so the run can continue.
        if (p.type == TileType.pipe && !_invincible) {
          _onHit(); // non-fatal: reduces a heart and gives brief i-frames
          // Nudge to far side of the pipe so we don't get stuck.
          if (_pvx > 0) {
            nx = p.bounds.x + p.bounds.w + 2;
          } else {
            nx = p.bounds.x - _pW - 2;
          }
        } else {
          if (_pvx > 0)
            nx = p.bounds.x - _pW;
          else
            nx = p.bounds.x + p.bounds.w;
          _pvx = 0;
        }
      }
    }

    // ── Vertical platform collision ──────────
    final vRect = Rect2(nx + 4, ny, _pW - 8, _pH);
    _onGround = false;
    for (final p in _level.platforms) {
      if (p.broken) continue;
      if (vRect.overlaps(p.bounds)) {
        if (_pvy > 0) {
          // Landing on top
          ny = p.bounds.y - _pH;
          _pvy = 0;
          _onGround = true;
          _doubleJumpUsed = false;
        } else if (_pvy < 0) {
          // Hitting from below
          ny = p.bounds.y + p.bounds.h;
          _pvy = 0;
          // Breakable block hit from below
          if (p.type == TileType.breakable && !p.broken) {
            _breakBlock(p);
          }
        }
      }
    }

    // Fall off world bottom → die
    if (ny > kWorldH) {
      _onHit(fatal: true);
      return;
    }

    _px = nx;
    _py = ny;
  }

  void _breakBlock(Platform p) {
    p.broken = true;
    _spawnParticles(
      p.bounds.x + p.bounds.w / 2,
      p.bounds.y + p.bounds.h / 2,
      count: 8,
      color: const Color(0xFFE8A020),
    );
    _score += 10;
    _snapshot.floatTexts.add(
      FloatingText(
        p.bounds.x + p.bounds.w / 2,
        p.bounds.y,
        '+10',
        const Color(0xFFF5E642),
      ),
    );
  }

  // ─────────────────────────────────────────────
  //  Enemies
  // ─────────────────────────────────────────────

  void _updateEnemies(double dt) {
    for (final e in _level.enemies) {
      if (!e.alive) {
        if (e.deathTimer > 0) {
          e.deathTimer -= dt;
          e.vy += kGravity * dt;
          e.y += e.vy * dt;
        }
        continue;
      }

      // Fly enemies bob up and down
      if (e.type == EnemyType.fly) {
        e.y =
            (_level.platforms.isNotEmpty
                ? kWorldH - kTile * 5
                : kWorldH - kTile * 4) +
            sin(_timeElapsed * 2.5 + e.x * 0.01) * kTile;
      } else {
        // Gravity
        e.vy += kGravity * dt;
        e.y += e.vy * dt;
        // Horizontal walk
        e.x += e.vx * dt;

        // Ground collision
        for (final p in _level.platforms) {
          if (p.broken) continue;
          final er = Rect2(
            e.x + 4,
            e.y + 4,
            kTile * 0.75 - 8,
            kTile * 0.75 - 8,
          );
          if (er.overlaps(p.bounds)) {
            if (e.vy > 0) {
              e.y = p.bounds.y - kTile * 0.75;
              e.vy = 0;
            }
            // Bounce off walls horizontally
            final hE = Rect2(
              e.x + e.vx * dt * 2,
              e.y + 4,
              kTile * 0.75 - 8,
              kTile * 0.75 - 8,
            );
            if (hE.overlaps(p.bounds)) {
              e.vx = -e.vx;
              e.facingLeft = e.vx < 0;
            }
          }
        }
      }

      // Turn around at world edges
      if (e.x < 0 || e.x > _level.worldWidth - kTile) {
        e.vx = -e.vx;
        e.facingLeft = e.vx < 0;
      }

      // ── Player vs Enemy ────────────────────
      final pb = Rect2(_px + 8, _py + 8, _pW - 16, _pH - 16);
      final eb = e.bounds;

      if (pb.overlaps(eb)) {
        final playerBottom = _py + _pH;
        final enemyTop = e.y;
        final stomping = _pvy > 0 && playerBottom < enemyTop + kTile * 0.3;

        if (stomping) {
          // Stomp! Kill enemy
          e.alive = false;
          e.deathTimer = 0.5;
          e.vy = -400;
          _pvy = -500; // small bounce
          final pts = e.type == EnemyType.turtle ? 200 : 100;
          _score += pts;
          _snapshot.floatTexts.add(
            FloatingText(
              e.x + kTile * 0.4,
              e.y - 20,
              '+$pts',
              const Color(0xFFF5E642),
            ),
          );
          _spawnParticles(
            e.x + kTile * 0.4,
            e.y + kTile * 0.4,
            count: 6,
            color: const Color(0xFFE84040),
          );
        } else {
          _onHit();
        }
      }
    }
  }

  // ─────────────────────────────────────────────
  //  Collectibles
  // ─────────────────────────────────────────────

  /// Returns true if a coin was collected this frame (for SFX).
  bool _updateCollectibles(double dt) {
    final pb = Rect2(_px + 6, _py + 6, _pW - 12, _pH - 12);
    var coinThisFrame = false;
    for (final c in _level.collectibles) {
      if (c.collected) continue;
      c.floatPhase += dt * 3.0;
      if (pb.overlaps(c.bounds)) {
        c.collected = true;
        if (c.type == PowerUpType.coin) {
          coinThisFrame = true;
          _coins++;
          _score += 30;
          _snapshot.floatTexts.add(
            FloatingText(c.x, c.y, '+30', const Color(0xFFFFD840)),
          );
          _spawnParticles(
            c.x + 16,
            c.y + 16,
            count: 4,
            color: const Color(0xFFFFD840),
          );
        } else if (c.type == PowerUpType.star) {
          _score += 500;
          _snapshot.floatTexts.add(
            FloatingText(c.x, c.y, '⭐ +500', const Color(0xFFF5E642)),
          );
          _spawnParticles(
            c.x + 16,
            c.y + 16,
            count: 12,
            color: const Color(0xFFF5E642),
          );
        }
        if (_coins >= 100) {
          _coins = 0;
          _lives++;
        }
      }
    }
    return coinThisFrame;
  }

  // ─────────────────────────────────────────────
  //  Camera
  // ─────────────────────────────────────────────

  void _updateCamera() {
    if (_screenScale <= 0) return;
    final screenW = MediaQuery.sizeOf(context).width;
    final targetCam = _px - (screenW / _screenScale) * 0.25;
    _camX += (targetCam - _camX) * 0.15;
    _camX = _camX.clamp(0, _level.worldWidth - screenW / _screenScale);
  }

  // ─────────────────────────────────────────────
  //  Effects
  // ─────────────────────────────────────────────

  void _spawnParticles(
    double x,
    double y, {
    int count = 6,
    Color color = Colors.white,
  }) {
    for (int i = 0; i < count; i++) {
      _snapshot.particles.add(
        Particle(
          x,
          y,
          (_rng.nextDouble() - 0.5) * 300,
          -(_rng.nextDouble() * 400 + 100),
          0.6 + _rng.nextDouble() * 0.4,
          color,
          3 + _rng.nextDouble() * 5,
        ),
      );
    }
  }

  void _updateEffects(double dt) {
    _snapshot.particles.removeWhere((p) => p.life <= 0);
    for (final p in _snapshot.particles) {
      p.x += p.vx * dt;
      p.y += p.vy * dt;
      p.vy += 800 * dt;
      p.life -= dt;
    }

    _snapshot.floatTexts.removeWhere((t) => t.life <= 0);
    for (final t in _snapshot.floatTexts) {
      t.y += t.vy * dt;
      t.life -= dt;
    }
  }

  // ─────────────────────────────────────────────
  //  Win / Lose
  // ─────────────────────────────────────────────

  void _checkLevelComplete() {
    if (_px >= _level.goalX && !_levelComplete) {
      _levelComplete = true;
      _isPlaying = false;
      _ticker.stop();
      Future.delayed(const Duration(milliseconds: 800), () async {
        if (mounted) {
          await CoinHistoryService.addCoinsForLevel(_currentLevel, _coins);
          await LeaderboardService.syncCurrentScore();
          await LevelProgressService.recordStars(
            _currentLevel,
            _lives.clamp(1, LevelProgressService.maxStars),
          );
          await LevelProgressService.unlockNextAfter(_currentLevel);
          await _showLevelCompleteAd();
          if (!mounted) return;
          await _showLevelCompleteDialog();
        }
      });
    }
  }

  Future<void> _showLevelCompleteDialog() async {
    await showGeneralDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'level_complete',
      barrierColor: Colors.black.withOpacity(0.35),
      transitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (_, __, ___) => SafeArea(
        child: Stack(
          children: [
            Center(
              child: LevelCompleteDialog(
                level: _currentLevel,
                score: _score,
                coins: _coins,
                onNext: () {
                  Navigator.pop(context);
                  final nextLevel = min(_currentLevel + 1, kMaxLevel);
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (_) => GameScreen(level: nextLevel),
                    ),
                  );
                },
                onHome: () {
                  Navigator.pop(context);
                  Navigator.of(context).popUntil((r) => r.isFirst);
                },
              ),
            ),
          ],
        ),
      ),
      transitionBuilder: (_, anim, __, child) =>
          FadeTransition(opacity: anim, child: child),
    );
  }

  void _onHit({bool fatal = false}) {
    if (_invincible) return;
    if (fatal) {
      _lives--;
    } else {
      _invincible = true;
      _invincibleTimer = 2.0;
      _lives--;
      _pvy = -600; // knockback bounce
      _spawnParticles(
        _px + _pW / 2,
        _py + _pH / 2,
        count: 8,
        color: Colors.red,
      );
    }

    if (_lives <= 0) {
      _isPlaying = false;
      _ticker.stop();
      // Future.delayed(const Duration(milliseconds: 300), () async {
        if (!mounted) return;
         CoinHistoryService.addCoinsForLevel(_currentLevel, _coins);
         LeaderboardService.syncCurrentScore();
        if (!mounted) return;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => GameOverScreen(
              score: _score,
              level: _currentLevel,
            ),
          ),
        );
         _showInterstitialIfAvailable();
      // });
    }
  }

  // ─────────────────────────────────────────────
  //  Input — Listener (zero delay)
  // ─────────────────────────────────────────────

  void _onPointerDown(PointerDownEvent _) {
    if (!_isPlaying) return;
    var jumped = false;
    _isCharging = true;
    _pressStart = DateTime.now();
    _chargeRatio = 0.0;

    if (_onGround) {
      _pvy = -kJumpVel;
      _onGround = false;
      _doubleJumpUsed = false;
      jumped = true;
    } else if (!_doubleJumpUsed) {
      _pvy = -(kJumpVel * 0.85);
      _doubleJumpUsed = true;
      jumped = true;
    }
    _syncFrame();
    if (jumped) {
      _sounds.playJump();
    }
  }

  void _onPointerUp(PointerUpEvent _) => _releasePointer();
  void _onPointerCancel(PointerCancelEvent _) => _releasePointer();

  void _releasePointer() {
    if (!_isPlaying) return;
    _isCharging = false;
    _pressStart = null;
    _chargeRatio = 0.0;
    _syncFrame();
  }

  // ─────────────────────────────────────────────
  //  Pause
  // ─────────────────────────────────────────────

  void _openPause() async {
    if (!_isPlaying) return;
    setState(() => _isPlaying = false);
    _ticker.stop();

    final result = await Navigator.push<String>(
      context,
      PageRouteBuilder(
        opaque: false,
        pageBuilder: (_, __, ___) => PauseScreen(score: _score),
        transitionsBuilder: (_, a, __, child) =>
            FadeTransition(opacity: a, child: child),
      ),
    );

    if (!mounted) return;
    await _refreshSoundPrefs();
    if (!mounted) return;
    if (result == 'resume') {
      _lastElapsed = Duration.zero;
      setState(() => _isPlaying = true);
      _ticker.start();
    } else if (result == 'restart') {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => GameScreen(level: _currentLevel)),
      );
    } else if (result == 'home') {
      Navigator.of(context).popUntil((r) => r.isFirst);
    }
  }

  // ─────────────────────────────────────────────
  //  Build
  // ─────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Listener(
        onPointerDown: _onPointerDown,
        onPointerUp: _onPointerUp,
        onPointerCancel: _onPointerCancel,
        behavior: HitTestBehavior.opaque,
        child: LayoutBuilder(
          builder: (ctx, constraints) {
            final w = constraints.maxWidth;
            final h = constraints.maxHeight;
            final scale = h / kWorldH;
            _screenScale = scale;
            return Stack(
              children: [
                ValueListenableBuilder<int>(
                  valueListenable: _repaint,
                  builder: (_, __, ___) => _buildBackground(w, h),
                ),
                CustomPaint(
                  size: Size(w, h),
                  painter: _worldPainter,
                ),
                ValueListenableBuilder<int>(
                  valueListenable: _repaint,
                  builder: (_, __, ___) => _buildHUD(h),
                ),
                ValueListenableBuilder<int>(
                  valueListenable: _repaint,
                  builder: (_, __, ___) {
                    if (!_isCharging) return const SizedBox.shrink();
                    return Positioned(
                      left: w * 0.25 - 4,
                      bottom: h - ((_py + _pH) * scale),
                      child: _ChargeBar(
                        ratio: _chargeRatio,
                        width: _pW * scale + 8,
                      ),
                    );
                  },
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  //  Background
  // ─────────────────────────────────────────────

  Widget _buildBackground(double w, double h) {
    return Stack(
      children: [
        // Sky gradient
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF4EC5F1), Color(0xFF90DFF5), Color(0xFFB8EEF0)],
              stops: [0.0, 0.6, 1.0],
            ),
          ),
        ),
        // Sun
        Positioned(
          top: h * 0.06,
          right: w * 0.12,
          child: Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: const Color(0xFFFFE040),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFFE040).withOpacity(0.5),
                  blurRadius: 24,
                  spreadRadius: 8,
                ),
              ],
            ),
          ),
        ),
        // Clouds (slow parallax using camX)
        ...buildParallaxClouds(width: w, height: h, camX: _camX),
        // Far mountains
        CustomPaint(
          size: Size(w, h),
          painter: GameMountainsPainter(camX: _camX * 0.15),
        ),
        // Mid tree layer
        CustomPaint(
          size: Size(w, h),
          painter: GameTreeLayerPainter(camX: _camX * 0.4),
        ),
      ],
    );
  }

  List<Widget> _buildClouds(double w, double h) {
    // Static cloud positions, parallax by 0.25 of camX
    final clouds = [
      [0.05, 0.08, 110.0, 44.0],
      [0.30, 0.13, 80.0, 32.0],
      [0.55, 0.06, 130.0, 50.0],
      [0.75, 0.15, 90.0, 36.0],
    ];
    return clouds.map((c) {
      final cloudW = c[2];
      final cloudH = c[3];
      final baseX = c[0] * w * 4; // spread across 4 screen widths
      final screenX = baseX - (_camX * 0.25 * (w / (kWorldH * 1.6))) % (w * 4);
      return Positioned(
        top: h * c[1],
        left: screenX % (w + cloudW) - cloudW,
        child: GameCloudWidget(width: cloudW, height: cloudH),
      );
    }).toList();
  }

  // ─────────────────────────────────────────────
  //  HUD
  // ─────────────────────────────────────────────

  Widget _buildHUD(double h) {
    final progress = (_px / _level.goalX).clamp(0.0, 1.0);
    final remainTiles = ((_level.goalX - _px) / kTile).clamp(0, 999).round();
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        color: Colors.black.withOpacity(0.30),
        padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top + 6,
          left: 16,
          right: 16,
          bottom: 10,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                // Lives
                Row(
                  children: List.generate(
                    3,
                    (i) => Padding(
                      padding: const EdgeInsets.only(right: 2),
                      child: Opacity(
                        opacity: i < _lives ? 1.0 : 0.22,
                        child: const Text('❤️', style: TextStyle(fontSize: 16)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                // Coins
                const Text('🪙', style: TextStyle(fontSize: 14)),
                const SizedBox(width: 4),
                Text(
                  '$_coins',
                  style: const TextStyle(
                    fontFamily: 'FredokaOne',
                    fontSize: 15,
                    color: JColors.yellow,
                  ),
                ),
                const Spacer(),
                // Score
                Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'SCORE',
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 9,
                        color: Colors.white.withOpacity(0.6),
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1,
                      ),
                    ),
                    Text(
                      '$_score',
                      style: const TextStyle(
                        fontFamily: 'FredokaOne',
                        fontSize: 18,
                        color: JColors.yellow,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                // Level
                Text(
                  'LVL $_currentLevel',
                  style: TextStyle(
                    fontFamily: 'FredokaOne',
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
                const SizedBox(width: 12),
                // Pause
                GestureDetector(
                  onTap: _openPause,
                  child: Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.white.withOpacity(0.3)),
                    ),
                    child: const Center(
                      child: Text('⏸', style: TextStyle(fontSize: 15)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  '🏁 ${remainTiles < 0 ? 0 : remainTiles} tiles',
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Colors.white.withOpacity(0.85),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    height: 8,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.16),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Stack(
                      children: [
                        FractionallySizedBox(
                          widthFactor: progress,
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [JColors.lightGreen, JColors.yellow],
                              ),
                              borderRadius: BorderRadius.circular(5),
                            ),
                          ),
                        ),
                        Align(
                          alignment: Alignment(progress * 2 - 1, 0),
                          child: const Text(
                            '🐒',
                            style: TextStyle(fontSize: 10),
                          ),
                        ),
                        const Align(
                          alignment: Alignment.centerRight,
                          child: Padding(
                            padding: EdgeInsets.only(right: 2),
                            child: Text('🏁', style: TextStyle(fontSize: 10)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ChargeBar extends StatelessWidget {
  final double ratio, width;
  const _ChargeBar({required this.ratio, required this.width});

  @override
  Widget build(BuildContext context) {
    final color = Color.lerp(
      const Color(0xFFF5E642),
      const Color(0xFFFF3300),
      ratio,
    )!;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (ratio > 0.88)
          Container(
            margin: const EdgeInsets.only(bottom: 2),
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
            decoration: BoxDecoration(
              color: const Color(0xFFFF3300).withOpacity(0.9),
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Text(
              'MAX!',
              style: TextStyle(
                fontFamily: 'FredokaOne',
                fontSize: 9,
                color: Colors.white,
              ),
            ),
          ),
        Container(
          width: width,
          height: 5,
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.28),
            borderRadius: BorderRadius.circular(3),
          ),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Container(
              width: width * ratio,
              height: 5,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

