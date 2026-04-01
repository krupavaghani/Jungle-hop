import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/coin_history_service.dart';
import '../services/level_progress_service.dart';
import '../utils/colors.dart';
import 'pause_screen.dart';
import 'game_over_screen.dart';

// ═══════════════════════════════════════════════════════════════════════════
//  JUNGLE ADVENTURES  —  Side-Scrolling Platformer
//
//  Architecture:
//   • All world coordinates are in "world pixels" (wp).
//     The camera scrolls so the player stays near 25% of the screen width.
//   • Screen pixels = (worldX - cameraX) * scale,  where scale fits height.
//   • Gravity pulls the player down; jumping gives upward velocity.
//   • Platforms are solid AABB tiles the player can stand on.
//   • Enemies walk on platforms and die when the player lands on top.
//   • Coins are collected on overlap.
//   • Breakable blocks reward coins when hit from below.
// ═══════════════════════════════════════════════════════════════════════════

// ── World dimensions ────────────────────────────────────────────────────────
const double kWorldH   = 800.0;   // world height in wp
const double kTile     = 64.0;    // 1 tile = 64 wp
const double kGravity  = 2200.0;  // wp/s²
const double kJumpVel  = 900.0;   // wp/s upward on tap
const double kBigJump  = 1340.0;  // wp/s on long-press full charge
const double kRunSpeed = 240.0;   // player auto-run speed wp/s
const int kMaxLevel = 100;

// ── Entity types ─────────────────────────────────────────────────────────────
enum TileType { ground, platform, brick, breakable, pipe, water }
enum EnemyType { mushroom, turtle, fly }
enum PowerUpType { coin, star, mushroom, cherry }

// ─────────────────────────────────────────────
//  Data classes
// ─────────────────────────────────────────────

class Rect2 {
  double x, y, w, h;
  Rect2(this.x, this.y, this.w, this.h);
  bool overlaps(Rect2 o) =>
      x < o.x + o.w && x + w > o.x && y < o.y + o.h && y + h > o.y;
  Rect get asRect => Rect.fromLTWH(x, y, w, h);
}

class Platform {
  final Rect2 bounds;
  final TileType type;
  bool broken;
  Platform(double x, double y, double w, double h, this.type)
      : bounds = Rect2(x, y, w, h),
        broken = false;
}

class Enemy {
  double x, y;
  double vx, vy;
  EnemyType type;
  bool alive;
  bool facingLeft;
  double deathTimer; // counts down, -1 = not dying
  Enemy(this.x, this.y, this.type)
      : vx = -80,
        vy = 0,
        alive = true,
        facingLeft = true,
        deathTimer = -1;
  Rect2 get bounds => Rect2(x, y, kTile * 0.75, kTile * 0.75);
}

class Collectible {
  double x, y;
  PowerUpType type;
  bool collected;
  double floatPhase; // for bobbing animation
  Collectible(this.x, this.y, this.type)
      : collected = false,
        floatPhase = 0;
  Rect2 get bounds => Rect2(x + 8, y + 8, kTile - 16, kTile - 16);
}

class Particle {
  double x, y, vx, vy, life, maxLife;
  Color color;
  double size;
  Particle(this.x, this.y, this.vx, this.vy, this.life, this.color, this.size)
      : maxLife = life;
}

class FloatingText {
  double x, y, vy, life;
  String text;
  Color color;
  FloatingText(this.x, this.y, this.text, this.color)
      : vy = -120,
        life = 1.0;
}

// ─────────────────────────────────────────────
//  Level Builder
// ─────────────────────────────────────────────

class LevelData {
  final List<Platform> platforms;
  final List<Enemy> enemies;
  final List<Collectible> collectibles;
  final double worldWidth;
  final double goalX; // flag pole X

  LevelData({
    required this.platforms,
    required this.enemies,
    required this.collectibles,
    required this.worldWidth,
    required this.goalX,
  });
}

LevelData buildLevel(int levelNum) {
  final level = levelNum.clamp(1, kMaxLevel);
  final difficulty = (level - 1) / (kMaxLevel - 1); // 0.0 .. 1.0
  const double ground = kWorldH - kTile;        // y of ground row

  final plats = <Platform>[];
  final enemies = <Enemy>[];
  final coins = <Collectible>[];
  final rng = Random(level);

  // ── Ground (full length with a few gaps) ────────────────────────────────
  void gRow(double startX, double endX) {
    for (double x = startX; x < endX; x += kTile) {
      plats.add(Platform(x, ground, kTile, kTile, TileType.ground));
      // Dirt layer below
      plats.add(Platform(x, ground + kTile, kTile, kTile * 20, TileType.ground));
    }
  }

  // Generated running path: early levels easier, later levels harder.
  double mix(double a, double b) => a + (b - a) * difficulty;
  double cursor = 0;
  while (cursor < kTile * 95) {
    final runLen = mix(18, 10) + rng.nextDouble() * 2;
    final end = min(cursor + kTile * runLen, kTile * 95);
    gRow(cursor, end);
    cursor = end;
    if (cursor >= kTile * 95) break;
    final gapTiles = mix(1.2, 3.3) + rng.nextDouble() * 0.8;
    cursor += kTile * gapTiles;
  }

  // ── Floating platforms ───────────────────────────────────────────────────
  void fPlat(double x, double y, int cols, TileType t) {
    for (int i = 0; i < cols; i++) {
      plats.add(Platform(x + i * kTile, y, kTile, kTile * 0.5, t));
    }
  }

  // Extra path helpers above gaps.
  for (double x = kTile * 8; x < kTile * 90; x += kTile * 7.5) {
    final y = ground - kTile * (2.8 + rng.nextDouble() * (2.2 + difficulty * 2));
    final cols = (2 + rng.nextInt(3)) - (difficulty > 0.65 ? 1 : 0);
    fPlat(x, y, cols.clamp(1, 4), rng.nextBool() ? TileType.platform : TileType.brick);
  }

  // Breakable blocks with coins inside
  void breakBlock(double x, double y) {
    plats.add(Platform(x, y, kTile, kTile * 0.6, TileType.breakable));
    coins.add(Collectible(x + kTile * 0.5 - 16, y - kTile, PowerUpType.coin));
  }
  for (double x = kTile * 7; x < kTile * 90; x += kTile * 11) {
    if (rng.nextDouble() > 0.25 + difficulty * 0.2) {
      breakBlock(x, ground - kTile * (3 + rng.nextInt(2)));
    }
  }

  // Pipes (tall obstacles)
  void pipe(double x) {
    plats.add(Platform(x, ground - kTile * 2.5, kTile * 1.5, kTile * 0.5, TileType.pipe));
    plats.add(Platform(x + kTile * 0.15, ground - kTile * 2, kTile * 1.2, kTile * 2, TileType.pipe));
  }
  final pipeStep = mix(18, 11);
  for (double x = kTile * 18; x < kTile * 92; x += kTile * pipeStep) {
    if (rng.nextDouble() < (0.45 + difficulty * 0.35)) {
      pipe(x);
    }
  }

  // ── Enemies ──────────────────────────────────────────────────────────────
  void addEnemy(double tx, EnemyType t) {
    enemies.add(Enemy(tx * kTile, ground - kTile * 0.75, t));
  }
  final enemyCount = (8 + difficulty * 16).round();
  for (int i = 0; i < enemyCount; i++) {
    final tx = 8 + rng.nextInt(84);
    final roll = rng.nextDouble();
    final t = roll < (0.55 - difficulty * 0.2)
        ? EnemyType.mushroom
        : (roll < (0.85 - difficulty * 0.1) ? EnemyType.turtle : EnemyType.fly);
    addEnemy(tx.toDouble(), t);
  }

  // ── Coins ────────────────────────────────────────────────────────────────
  // Coin rows along platforms
  void coinRow(double startX, double y, int count) {
    for (int i = 0; i < count; i++) {
      coins.add(Collectible(startX + i * kTile * 0.8, y - kTile * 0.8, PowerUpType.coin));
    }
  }
  for (double x = kTile * 5; x < kTile * 88; x += kTile * 10) {
    final y = ground - kTile * (rng.nextDouble() < 0.6 ? 0 : (3 + rng.nextInt(4)));
    coinRow(x, y, (2 + rng.nextInt(4)).clamp(2, 5));
  }

  // Power-up stars
  final starCount = max(1, 3 - (difficulty * 2).round());
  for (int i = 0; i < starCount; i++) {
    final sx = (12 + i * 24 + rng.nextInt(10)) * kTile;
    final sy = ground - (3 + rng.nextInt(5)) * kTile;
    coins.add(Collectible(sx, sy, PowerUpType.star));
  }

  final worldW = kTile * 96.0;
  return LevelData(
    platforms: plats,
    enemies: enemies,
    collectibles: coins,
    worldWidth: worldW,
    goalX: kTile * 93,
  );
}

// ─────────────────────────────────────────────
//  GameScreen
// ─────────────────────────────────────────────

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
  bool _facingRight = true;

  // Long-press power jump
  bool      _isCharging  = false;
  DateTime? _pressStart;
  double    _chargeRatio = 0.0;
  static const int _maxChargeMs = 500;

  // ── Camera ───────────────────────────────────
  double _camX = 0;

  // ── Game state ───────────────────────────────
  int    _score     = 0;
  int    _coins     = 0;
  int    _lives     = 3;
  int    _level_num = 1;
  bool   _isPlaying = true;
  bool   _levelComplete = false;

  // ── Effects ──────────────────────────────────
  final List<Particle>    _particles    = [];
  final List<FloatingText> _floatingTexts = [];

  // ── Misc ─────────────────────────────────────
  final Random _rng = Random();
  double _timeElapsed = 0;
  double _runSpeed = kRunSpeed;
  String _playerEmoji = '🐒';

  @override
  void initState() {
    super.initState();
    _level_num = widget.level.clamp(1, kMaxLevel);
    final difficulty = (_level_num - 1) / (kMaxLevel - 1);
    _runSpeed = kRunSpeed + (difficulty * 120.0);
    _level = buildLevel(_level_num);
    _loadSelectedCharacter();
    _ticker = createTicker(_tick)..start();
  }

  Future<void> _loadSelectedCharacter() async {
    final prefs = await SharedPreferences.getInstance();
    final usingName = prefs.getString(_usingCharacterKey) ?? 'Monkey';
    final emoji = _characterEmojiMap[usingName] ?? '🐒';
    if (!mounted) return;
    setState(() => _playerEmoji = emoji);
  }

  @override
  void dispose() {
    _ticker.dispose();
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

    setState(() {
      _timeElapsed += dt;

      // Update charge ratio
      if (_isCharging && _pressStart != null) {
        final ms = DateTime.now().difference(_pressStart!).inMilliseconds;
        _chargeRatio = (ms / _maxChargeMs).clamp(0.0, 1.0);
      } else {
        _chargeRatio = 0.0;
      }

      _updatePlayer(dt);
      _updateEnemies(dt);
      _updateCollectibles(dt);
      _updateCamera();
      _updateEffects(dt);
      _checkLevelComplete();

      if (_invincible) {
        _invincibleTimer -= dt;
        if (_invincibleTimer <= 0) _invincible = false;
      }
    });
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
          if (_pvx > 0) nx = p.bounds.x - _pW;
          else          nx = p.bounds.x + p.bounds.w;
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
    _floatingTexts.add(FloatingText(
      p.bounds.x + p.bounds.w / 2,
      p.bounds.y,
      '+10',
      const Color(0xFFF5E642),
    ));
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
          e.y  += e.vy * dt;
        }
        continue;
      }

      // Fly enemies bob up and down
      if (e.type == EnemyType.fly) {
        e.y = (_level.platforms.isNotEmpty
            ? kWorldH - kTile * 5
            : kWorldH - kTile * 4) +
            sin(_timeElapsed * 2.5 + e.x * 0.01) * kTile;
      } else {
        // Gravity
        e.vy += kGravity * dt;
        e.y  += e.vy * dt;
        // Horizontal walk
        e.x += e.vx * dt;

        // Ground collision
        for (final p in _level.platforms) {
          if (p.broken) continue;
          final er = Rect2(e.x + 4, e.y + 4, kTile * 0.75 - 8, kTile * 0.75 - 8);
          if (er.overlaps(p.bounds)) {
            if (e.vy > 0) {
              e.y  = p.bounds.y - kTile * 0.75;
              e.vy = 0;
            }
            // Bounce off walls horizontally
            final hE = Rect2(e.x + e.vx * dt * 2, e.y + 4, kTile * 0.75 - 8, kTile * 0.75 - 8);
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
        final enemyTop     = e.y;
        final stomping     = _pvy > 0 && playerBottom < enemyTop + kTile * 0.3;

        if (stomping) {
          // Stomp! Kill enemy
          e.alive = false;
          e.deathTimer = 0.5;
          e.vy = -400;
          _pvy = -500; // small bounce
          final pts = e.type == EnemyType.turtle ? 200 : 100;
          _score += pts;
          _floatingTexts.add(FloatingText(
            e.x + kTile * 0.4, e.y - 20, '+$pts',
            const Color(0xFFF5E642),
          ));
          _spawnParticles(e.x + kTile * 0.4, e.y + kTile * 0.4,
              count: 6, color: const Color(0xFFE84040));
        } else {
          _onHit();
        }
      }
    }
  }

  // ─────────────────────────────────────────────
  //  Collectibles
  // ─────────────────────────────────────────────

  void _updateCollectibles(double dt) {
    final pb = Rect2(_px + 6, _py + 6, _pW - 12, _pH - 12);
    for (final c in _level.collectibles) {
      if (c.collected) continue;
      c.floatPhase += dt * 3.0;
      if (pb.overlaps(c.bounds)) {
        c.collected = true;
        if (c.type == PowerUpType.coin) {
          _coins++;
          _score += 50;
          _floatingTexts.add(FloatingText(c.x, c.y, '+50', const Color(0xFFFFD840)));
          _spawnParticles(c.x + 16, c.y + 16, count: 4, color: const Color(0xFFFFD840));
        } else if (c.type == PowerUpType.star) {
          _score += 500;
          _floatingTexts.add(FloatingText(c.x, c.y, '⭐ +500', const Color(0xFFF5E642)));
          _spawnParticles(c.x + 16, c.y + 16, count: 12, color: const Color(0xFFF5E642));
        }
        if (_coins >= 100) {
          _coins = 0;
          _lives++;
        }
      }
    }
  }

  // ─────────────────────────────────────────────
  //  Camera
  // ─────────────────────────────────────────────

  void _updateCamera() {
    final size = context.size;
    if (size == null) return;
    final scale  = size.height / kWorldH;
    final screenW = size.width;
    // Keep player at ~25% from left
    final targetCam = _px - (screenW / scale) * 0.25;
    // Smooth follow
    _camX += (targetCam - _camX) * 0.15;
    _camX = _camX.clamp(0, _level.worldWidth - screenW / scale);
  }

  // ─────────────────────────────────────────────
  //  Effects
  // ─────────────────────────────────────────────

  void _spawnParticles(double x, double y,
      {int count = 6, Color color = Colors.white}) {
    for (int i = 0; i < count; i++) {
      _particles.add(Particle(
        x, y,
        (_rng.nextDouble() - 0.5) * 300,
        -(_rng.nextDouble() * 400 + 100),
        0.6 + _rng.nextDouble() * 0.4,
        color,
        3 + _rng.nextDouble() * 5,
      ));
    }
  }

  void _updateEffects(double dt) {
    _particles.removeWhere((p) => p.life <= 0);
    for (final p in _particles) {
      p.x    += p.vx * dt;
      p.y    += p.vy * dt;
      p.vy   += 800 * dt;
      p.life -= dt;
    }

    _floatingTexts.removeWhere((t) => t.life <= 0);
    for (final t in _floatingTexts) {
      t.y    += t.vy * dt;
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
          CoinHistoryService.addCoinsForLevel(_level_num, _coins);
          LevelProgressService.unlockNextAfter(_level_num);
          await _showLevelCompleteDialogWithVideo();
        }
      });
    }
  }

  Future<void> _showLevelCompleteDialogWithVideo() async {
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
              child: _LevelCompleteDialog(
                level: _level_num,
                score: _score,
                coins: _coins,
                onNext: () {
                  Navigator.pop(context);
                  final nextLevel = min(_level_num + 1, kMaxLevel);
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                        builder: (_) => GameScreen(level: nextLevel)),
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
      _spawnParticles(_px + _pW / 2, _py + _pH / 2,
          count: 8, color: Colors.red);
    }

    if (_lives <= 0) {
      _isPlaying = false;
      _ticker.stop();
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          CoinHistoryService.addCoinsForLevel(_level_num, _coins);
          Navigator.of(context).pushReplacement(MaterialPageRoute(
            builder: (_) => GameOverScreen(
              score: _score,
              bestScore: 9999,
              level: _level_num,
            ),
          ));
        }
      });
    }
  }

  // ─────────────────────────────────────────────
  //  Input — Listener (zero delay)
  // ─────────────────────────────────────────────

  void _onPointerDown(PointerDownEvent _) {
    if (!_isPlaying) return;
    setState(() {
      _isCharging  = true;
      _pressStart  = DateTime.now();
      _chargeRatio = 0.0;

      // Instant jump on press.
      if (_onGround) {
        _pvy = -kJumpVel;
        _onGround = false;
        _doubleJumpUsed = false;
      } else if (!_doubleJumpUsed) {
        // Instant double jump while in air.
        _pvy = -(kJumpVel * 0.85);
        _doubleJumpUsed = true;
      }
    });
  }

  void _onPointerUp(PointerUpEvent _) {
    if (!_isPlaying) return;
    setState(() {
      _isCharging = false;
      _pressStart = null;
      _chargeRatio = 0.0;
    });
  }

  void _onPointerCancel(PointerCancelEvent _) {
    if (!_isPlaying) return;
    setState(() {
      _isCharging = false;
      _pressStart = null;
      _chargeRatio = 0.0;
    });
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
    if (result == 'resume') {
      _lastElapsed = Duration.zero;
      setState(() => _isPlaying = true);
      _ticker.start();
    } else if (result == 'restart') {
      Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => GameScreen(level: _level_num)));
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
        onPointerDown:  _onPointerDown,
        onPointerUp:    _onPointerUp,
        onPointerCancel: _onPointerCancel,
        behavior: HitTestBehavior.opaque,
        child: LayoutBuilder(builder: (ctx, constraints) {
          final w     = constraints.maxWidth;
          final h     = constraints.maxHeight;
          final scale = h / kWorldH;
          return Stack(
            children: [
              // ── Sky background (parallax layers) ──────
              _buildBackground(w, h),

              // ── Game world (all entities) ──────────────
              CustomPaint(
                size: Size(w, h),
                painter: _WorldPainter(
                  level:        _level,
                  camX:         _camX,
                  scale:        scale,
                  px:           _px,
                  py:           _py,
                  pW:           _pW,
                  pH:           _pH,
                  facingRight:  _facingRight,
                  invincible:   _invincible,
                  invTimer:     _invincibleTimer,
                  enemies:      _level.enemies,
                  collectibles: _level.collectibles,
                  particles:    _particles,
                  floatTexts:   _floatingTexts,
                  goalX:        _level.goalX,
                  timeElapsed:  _timeElapsed,
                  playerEmoji:  _playerEmoji,
                ),
              ),

              // ── HUD ───────────────────────────────────
              _buildHUD(h),

              // ── Charge bar ────────────────────────────
              if (_isCharging)
                Positioned(
                  left: w * 0.25 - 4,
                  bottom: h - (((_py - _camX * 0) + _pH) * scale),
                  child: _ChargeBar(ratio: _chargeRatio, width: _pW * scale + 8),
                ),
            ],
          );
        }),
      ),
    );
  }

  // ─────────────────────────────────────────────
  //  Background
  // ─────────────────────────────────────────────

  Widget _buildBackground(double w, double h) {
    return Stack(children: [
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
          width: 64, height: 64,
          decoration: BoxDecoration(
            color: const Color(0xFFFFE040),
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(
              color: const Color(0xFFFFE040).withOpacity(0.5),
              blurRadius: 24, spreadRadius: 8,
            )],
          ),
        ),
      ),
      // Clouds (slow parallax using camX)
      ..._buildClouds(w, h),
      // Far mountains
      CustomPaint(
        size: Size(w, h),
        painter: _MountainsPainter(camX: _camX * 0.15),
      ),
      // Mid tree layer
      CustomPaint(
        size: Size(w, h),
        painter: _TreeLayerPainter(camX: _camX * 0.4),
      ),
    ]);
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
        child: _CloudWidget(width: cloudW, height: cloudH),
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
      top: 0, left: 0, right: 0,
      child: Container(
        color: Colors.black.withOpacity(0.30),
      padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top + 6,
          left: 16, right: 16, bottom: 10,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
        children: [
            Row(
              children: [
                // Lives
                Row(children: List.generate(3, (i) => Padding(
                  padding: const EdgeInsets.only(right: 2),
                  child: Opacity(
                    opacity: i < _lives ? 1.0 : 0.22,
                    child: const Text('❤️', style: TextStyle(fontSize: 16)),
                  ),
                ))),
                const SizedBox(width: 10),
                // Coins
                const Text('🪙', style: TextStyle(fontSize: 14)),
                const SizedBox(width: 4),
                Text('$_coins',
                    style: const TextStyle(
                        fontFamily: 'FredokaOne', fontSize: 15, color: JColors.yellow)),
                const Spacer(),
          // Score
                Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('SCORE',
                        style: TextStyle(
                            fontFamily: 'Nunito', fontSize: 9,
                            color: Colors.white.withOpacity(0.6),
                            fontWeight: FontWeight.w700, letterSpacing: 1)),
                    Text('$_score',
            style: const TextStyle(
                            fontFamily: 'FredokaOne', fontSize: 18,
                            color: JColors.yellow)),
                  ],
          ),
          const Spacer(),
                // Level
                Text('LVL $_level_num',
                    style: TextStyle(
                        fontFamily: 'FredokaOne', fontSize: 14,
                        color: Colors.white.withOpacity(0.8))),
          const SizedBox(width: 12),
                // Pause
          GestureDetector(
            onTap: _openPause,
            child: Container(
                    width: 34, height: 34,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white.withOpacity(0.3)),
              ),
                    child: const Center(child: Text('⏸', style: TextStyle(fontSize: 15))),
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
                          child: const Text('🐒', style: TextStyle(fontSize: 10)),
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

// ═══════════════════════════════════════════════════════════════════════════
//  World Painter — renders all game entities
// ═══════════════════════════════════════════════════════════════════════════

class _WorldPainter extends CustomPainter {
  final LevelData       level;
  final double          camX, scale, px, py, pW, pH;
  final bool            facingRight, invincible;
  final double          invTimer, goalX, timeElapsed;
  final String          playerEmoji;
  final List<Enemy>     enemies;
  final List<Collectible> collectibles;
  final List<Particle>  particles;
  final List<FloatingText> floatTexts;

  const _WorldPainter({
    required this.level,
    required this.camX,
    required this.scale,
    required this.px, required this.py,
    required this.pW, required this.pH,
    required this.facingRight,
    required this.invincible,
    required this.invTimer,
    required this.enemies,
    required this.collectibles,
    required this.particles,
    required this.floatTexts,
    required this.goalX,
    required this.timeElapsed,
    required this.playerEmoji,
  });

  // World → screen
  Offset ws(double wx, double wy) =>
      Offset((wx - camX) * scale, wy * scale);
  Rect wr(double wx, double wy, double ww, double wh) =>
      Rect.fromLTWH((wx - camX) * scale, wy * scale, ww * scale, wh * scale);

  @override
  void paint(Canvas canvas, Size size) {
    _drawPlatforms(canvas, size);
    _drawGoal(canvas, size);
    _drawCollectibles(canvas, size);
    _drawEnemies(canvas, size);
    _drawPlayer(canvas, size);
    _drawParticles(canvas, size);
    _drawFloatingTexts(canvas, size);
  }

  // ── Platforms ──────────────────────────────────────────────────────────

  void _drawPlatforms(Canvas canvas, Size size) {
    for (final p in level.platforms) {
      if (p.broken) continue;
      final sx = (p.bounds.x - camX) * scale;
      final sy = p.bounds.y * scale;
      final sw = p.bounds.w * scale;
      final sh = p.bounds.h * scale;

      // Skip if off-screen
      if (sx + sw < 0 || sx > size.width) continue;
      if (sy + sh < 0 || sy > size.height) continue;

      final r = Rect.fromLTWH(sx, sy, sw, sh);
      switch (p.type) {
        case TileType.ground:
          _drawGroundTile(canvas, r);
          break;
        case TileType.platform:
          _drawPlatformTile(canvas, r);
          break;
        case TileType.brick:
          _drawBrickTile(canvas, r);
          break;
        case TileType.breakable:
          _drawBreakableTile(canvas, r);
          break;
        case TileType.pipe:
          _drawPipeTile(canvas, r, p.bounds);
          break;
        case TileType.water:
          _drawWaterTile(canvas, r);
          break;
      }
    }
  }

  void _drawGroundTile(Canvas canvas, Rect r) {
    // Top grass strip
    canvas.drawRect(Rect.fromLTWH(r.left, r.top, r.width, r.height * 0.28),
        Paint()..color = const Color(0xFF4DBF2A));
    // Mid green
    canvas.drawRect(Rect.fromLTWH(r.left, r.top + r.height * 0.28,
        r.width, r.height * 0.15),
        Paint()..color = const Color(0xFF3AA020));
    // Dirt
    canvas.drawRect(Rect.fromLTWH(r.left, r.top + r.height * 0.43,
        r.width, r.height * 0.57),
        Paint()..color = const Color(0xFF8B5E2A));
    // Border
    canvas.drawRect(r, Paint()
      ..color = const Color(0xFF2A8A10)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5);
    // Grass blades
    if (r.height > 4) {
      final gp = Paint()
        ..color = const Color(0xFF62D040)
        ..strokeWidth = 1.2
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;
      for (double x = r.left + 3; x < r.right - 2; x += 6) {
        canvas.drawLine(Offset(x, r.top), Offset(x - 1, r.top - 4), gp);
        canvas.drawLine(Offset(x + 3, r.top), Offset(x + 4, r.top - 5), gp);
      }
    }
  }

  void _drawPlatformTile(Canvas canvas, Rect r) {
    canvas.drawRect(r, Paint()..color = const Color(0xFF7EC850));
    canvas.drawRect(Rect.fromLTWH(r.left + 1, r.top + 1, r.width - 2, r.height * 0.35),
        Paint()..color = const Color(0xFF9AE060));
    canvas.drawRect(r, Paint()
      ..color = const Color(0xFF4A8A20)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8);
  }

  void _drawBrickTile(Canvas canvas, Rect r) {
    canvas.drawRect(r, Paint()..color = const Color(0xFFC44820));
    // Brick pattern
    final lines = Paint()
      ..color = const Color(0xFFA03010)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(r.left, r.top + r.height / 2), Offset(r.right, r.top + r.height / 2), lines);
    canvas.drawLine(Offset(r.left + r.width * 0.5, r.top), Offset(r.left + r.width * 0.5, r.top + r.height / 2), lines);
    canvas.drawLine(Offset(r.left + r.width * 0.25, r.top + r.height / 2), Offset(r.left + r.width * 0.25, r.bottom), lines);
    canvas.drawLine(Offset(r.left + r.width * 0.75, r.top + r.height / 2), Offset(r.left + r.width * 0.75, r.bottom), lines);
    // Top highlight
    canvas.drawRect(Rect.fromLTWH(r.left + 1, r.top + 1, r.width - 2, 2),
        Paint()..color = const Color(0xFFE06030).withOpacity(0.5));
  }

  void _drawBreakableTile(Canvas canvas, Rect r) {
    // Gold/question block
    canvas.drawRRect(RRect.fromRectAndRadius(r, const Radius.circular(3)),
        Paint()..color = const Color(0xFFE8A020));
    canvas.drawRRect(RRect.fromRectAndRadius(r.deflate(1.5), const Radius.circular(2)),
        Paint()..color = const Color(0xFFF5C040));
    // ? mark
    final tp = TextPainter(
      text: TextSpan(
        text: '?',
              style: TextStyle(
          color: const Color(0xFFAA6000),
          fontSize: r.height * 0.7,
          fontWeight: FontWeight.w900,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(r.left + (r.width - tp.width) / 2,
        r.top + (r.height - tp.height) / 2));
    // Border
    canvas.drawRRect(RRect.fromRectAndRadius(r, const Radius.circular(3)),
        Paint()
          ..color = const Color(0xFFA07000)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0);
  }

  void _drawPipeTile(Canvas canvas, Rect r, Rect2 bounds) {
    // Green pipe
    canvas.drawRect(r, Paint()..color = const Color(0xFF2A8A18));
    // Highlight left strip
    canvas.drawRect(Rect.fromLTWH(r.left + 2, r.top, r.width * 0.25, r.height),
        Paint()..color = const Color(0xFF4AB830).withOpacity(0.6));
    // Dark right edge
    canvas.drawRect(Rect.fromLTWH(r.right - 3, r.top, 3, r.height),
        Paint()..color = const Color(0xFF1A6010));
    canvas.drawRect(r, Paint()
      ..color = const Color(0xFF1A6010)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8);
  }

  void _drawWaterTile(Canvas canvas, Rect r) {
    canvas.drawRect(r, Paint()..color = const Color(0xFF2060E0).withOpacity(0.7));
  }

  // ── Goal flag ───────────────────────────────────────────────────────────

  void _drawGoal(Canvas canvas, Size size) {
    final sx = (goalX - camX) * scale;
    if (sx < -50 || sx > size.width + 50) return;
    final groundY = (kWorldH - kTile) * scale;
    final distanceToGoal = (goalX - px).clamp(0.0, kTile * 20);
    final nearFactor = 1.0 - (distanceToGoal / (kTile * 20));
    final pulse = (sin(timeElapsed * 10) * 0.5 + 0.5);

    // Highlight "finish line" so player knows where to reach.
    final glowRect = Rect.fromLTWH(
      sx - 6 * scale,
      groundY - kTile * 8.2 * scale,
      12 * scale,
      kTile * 8.5 * scale,
    );
    canvas.drawRect(
      glowRect,
      Paint()
        ..color = const Color(0x80FFF176)
            .withOpacity(0.25 + nearFactor * 0.35 + pulse * 0.1),
    );

    // Stronger pulse ring around flag when player gets near.
    if (nearFactor > 0) {
      canvas.drawCircle(
        Offset(sx, groundY - kTile * 7.5 * scale),
        (18 + pulse * 10 + nearFactor * 20) * scale,
        Paint()
          ..color = const Color(0xFFFFF176).withOpacity(0.12 + nearFactor * 0.18)
          ..style = PaintingStyle.stroke
          ..strokeWidth = (1.2 + nearFactor * 1.8) * scale,
      );
    }

    // Pole
    final polePaint = Paint()
      ..color = const Color(0xFF888888)
      ..strokeWidth = 3 * scale;
    canvas.drawLine(Offset(sx, groundY - kTile * 8 * scale),
        Offset(sx, groundY), polePaint);

    // Flag wave
    final flagPath = Path()
      ..moveTo(sx, groundY - kTile * 8 * scale)
      ..quadraticBezierTo(
          sx + 30 * scale + sin(timeElapsed * 3) * 8 * scale,
          groundY - kTile * 7.5 * scale,
          sx + 24 * scale,
          groundY - kTile * 7 * scale)
      ..quadraticBezierTo(
          sx + 30 * scale + sin(timeElapsed * 3) * 6 * scale,
          groundY - kTile * 7.5 * scale,
          sx, groundY - kTile * 7 * scale);
    canvas.drawPath(flagPath, Paint()..color = const Color(0xFFE84040));
    canvas.drawPath(flagPath, Paint()
      ..color = const Color(0xFFC03030)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8);

    final finishPainter = TextPainter(
      text: TextSpan(
        text: 'FINISH',
        style: TextStyle(
          color: const Color(0xFFFFF176),
          fontSize: 10 * scale,
          fontWeight: FontWeight.w800,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    finishPainter.paint(
      canvas,
      Offset(
        sx - finishPainter.width / 2,
        groundY - kTile * 8.8 * scale,
      ),
    );
  }

  // ── Collectibles ────────────────────────────────────────────────────────

  void _drawCollectibles(Canvas canvas, Size size) {
    for (final c in collectibles) {
      if (c.collected) continue;
      final sx = (c.x - camX) * scale;
      if (sx < -30 || sx > size.width + 30) continue;

      final bob = sin(c.floatPhase) * 3 * scale;
      final sy = c.y * scale + bob;
      final sz = (kTile - 16) * scale;
      final r  = Rect.fromLTWH(sx, sy, sz, sz);

      if (c.type == PowerUpType.coin) {
        _drawCoin(canvas, r);
      } else if (c.type == PowerUpType.star) {
        _drawStar(canvas, Offset(sx + sz / 2, sy + sz / 2), sz * 0.5);
      }
    }
  }

  void _drawCoin(Canvas canvas, Rect r) {
    canvas.drawOval(r.inflate(1), Paint()..color = const Color(0xFFC47800));
    canvas.drawOval(r, Paint()..color = const Color(0xFFE8A020));
    canvas.drawOval(r.deflate(r.width * 0.1), Paint()..color = const Color(0xFFFFD840));
    // Shine
    canvas.drawOval(
        Rect.fromLTWH(r.left + r.width * 0.2, r.top + r.height * 0.15,
            r.width * 0.25, r.height * 0.2),
        Paint()..color = Colors.white.withOpacity(0.4));
  }

  void _drawStar(Canvas canvas, Offset center, double radius) {
    final path = Path();
    for (int i = 0; i < 10; i++) {
      final angle = (i * pi / 5) - pi / 2;
      final r = i.isEven ? radius : radius * 0.45;
      final pt = Offset(center.dx + cos(angle) * r, center.dy + sin(angle) * r);
      if (i == 0) path.moveTo(pt.dx, pt.dy); else path.lineTo(pt.dx, pt.dy);
    }
    path.close();
    canvas.drawPath(path, Paint()..color = const Color(0xFFFFD820));
    canvas.drawPath(path, Paint()
      ..color = const Color(0xFFE8B800)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5);
  }

  // ── Enemies ─────────────────────────────────────────────────────────────

  void _drawEnemies(Canvas canvas, Size size) {
    for (final e in enemies) {
      final sx = (e.x - camX) * scale;
      if (sx < -60 || sx > size.width + 60) continue;

      if (!e.alive) {
        if (e.deathTimer > 0) {
          // Dead mushroom squish
          final r = Rect.fromLTWH(sx, e.y * scale,
              kTile * 0.75 * scale, kTile * 0.3 * scale);
          canvas.drawOval(r, Paint()
            ..color = const Color(0xFFA04020).withOpacity(0.6));
        }
        continue;
      }

      final sy = e.y * scale;
      final ew = kTile * 0.75 * scale;
      final eh = kTile * 0.75 * scale;

      switch (e.type) {
        case EnemyType.mushroom: _drawMushroom(canvas, sx, sy, ew, eh, e.facingLeft); break;
        case EnemyType.turtle:   _drawTurtle(canvas, sx, sy, ew, eh, e.facingLeft);   break;
        case EnemyType.fly:      _drawFly(canvas, sx, sy, ew, eh, e.facingLeft);      break;
      }
    }
  }

  void _drawMushroom(Canvas canvas, double sx, double sy,
      double ew, double eh, bool fl) {
    // Body
    canvas.drawOval(Rect.fromLTWH(sx + ew*0.1, sy + eh*0.4, ew*0.8, eh*0.55),
        Paint()..color = const Color(0xFFC8481A));
    // Cap
    final capPath = Path()
      ..moveTo(sx, sy + eh * 0.45)
      ..quadraticBezierTo(sx + ew*0.5, sy - eh*0.1, sx + ew, sy + eh*0.45)
      ..close();
    canvas.drawPath(capPath, Paint()..color = const Color(0xFFE84820));
    // White spots on cap
    canvas.drawCircle(Offset(sx + ew*0.3, sy + eh*0.22), ew*0.10,
        Paint()..color = Colors.white);
    canvas.drawCircle(Offset(sx + ew*0.65, sy + eh*0.20), ew*0.08,
        Paint()..color = Colors.white);
    // Eyes
    final ex = fl ? sx + ew*0.62 : sx + ew*0.28;
    canvas.drawCircle(Offset(ex, sy + eh*0.50), ew*0.08, Paint()..color = Colors.white);
    canvas.drawCircle(Offset(ex + (fl ? -1:1)*ew*0.02, sy + eh*0.51),
        ew*0.05, Paint()..color = Colors.black);
    // Feet
    canvas.drawOval(Rect.fromLTWH(sx + ew*0.05, sy + eh*0.88, ew*0.35, eh*0.12),
        Paint()..color = const Color(0xFF8B3010));
    canvas.drawOval(Rect.fromLTWH(sx + ew*0.60, sy + eh*0.88, ew*0.35, eh*0.12),
        Paint()..color = const Color(0xFF8B3010));
  }

  void _drawTurtle(Canvas canvas, double sx, double sy,
      double ew, double eh, bool fl) {
    // Shell
    canvas.drawOval(Rect.fromLTWH(sx + ew*0.1, sy + eh*0.2, ew*0.8, eh*0.7),
        Paint()..color = const Color(0xFF2A8A18));
    canvas.drawOval(Rect.fromLTWH(sx + ew*0.18, sy + eh*0.26, ew*0.64, eh*0.56),
        Paint()..color = const Color(0xFF3AA820));
    // Shell pattern
    final sp = Paint()
      ..color = const Color(0xFF1A6A10)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(sx + ew*0.5, sy + eh*0.26),
        Offset(sx + ew*0.5, sy + eh*0.82), sp);
    canvas.drawLine(Offset(sx + ew*0.18, sy + eh*0.54),
        Offset(sx + ew*0.82, sy + eh*0.54), sp);
    // Head
    final hx = fl ? sx + ew*0.05 : sx + ew*0.65;
    canvas.drawOval(Rect.fromLTWH(hx, sy + eh*0.28, ew*0.28, eh*0.28),
        Paint()..color = const Color(0xFF5AC830));
    canvas.drawCircle(Offset(hx + (fl ? ew*0.08 : ew*0.20), sy + eh*0.35),
        ew*0.05, Paint()..color = Colors.black);
    // Feet
    for (final fx in [0.12, 0.60]) {
      canvas.drawOval(Rect.fromLTWH(sx + ew*fx, sy + eh*0.88, ew*0.26, eh*0.12),
          Paint()..color = const Color(0xFF3A9820));
    }
  }

  void _drawFly(Canvas canvas, double sx, double sy,
      double ew, double eh, bool fl) {
    // Wings (animated by time)
    final wingY = sy + eh*0.3 + sin(DateTime.now().millisecondsSinceEpoch * 0.01) * 4;
    final wingPaint = Paint()
      ..color = Colors.lightBlue.withOpacity(0.7);
    canvas.drawOval(Rect.fromLTWH(sx - ew*0.25, wingY, ew*0.4, eh*0.3), wingPaint);
    canvas.drawOval(Rect.fromLTWH(sx + ew*0.85, wingY, ew*0.4, eh*0.3), wingPaint);
    // Body
    canvas.drawOval(Rect.fromLTWH(sx + ew*0.15, sy + eh*0.2, ew*0.7, eh*0.65),
        Paint()..color = const Color(0xFF2A1A40));
    canvas.drawOval(Rect.fromLTWH(sx + ew*0.22, sy + eh*0.25, ew*0.56, eh*0.5),
        Paint()..color = const Color(0xFF4A3060));
    // Red eyes
    canvas.drawCircle(Offset(sx + ew*(fl ? 0.68 : 0.28), sy + eh*0.32),
        ew*0.09, Paint()..color = const Color(0xFFFF2020));
    // Stinger
    final stx = fl ? sx - ew*0.05 : sx + ew*1.05;
    canvas.drawLine(Offset(sx + ew*0.5, sy + eh*0.85), Offset(stx, sy + eh*1.0),
        Paint()
          ..color = const Color(0xFFE8A020)
          ..strokeWidth = 2
          ..strokeCap = StrokeCap.round);
  }

  // ── Player ──────────────────────────────────────────────────────────────

  void _drawPlayer(Canvas canvas, Size size) {
    if (playerEmoji != '🐒') {
      _drawEmojiPlayer(canvas);
      return;
    }

    final sx = (px - camX) * scale;
    final sy = py * scale;
    final sw = pW * scale;
    final sh = pH * scale;

    // Blink when invincible
    if (invincible && ((invTimer * 10).toInt() % 2 == 0)) return;

    canvas.save();
    if (!facingRight) {
      canvas.scale(-1, 1);
      canvas.translate(-(2 * sx + sw), 0);
    }

    final b  = Paint()..color = const Color(0xFF8B5E3C);  // brown
    final lb = Paint()..color = const Color(0xFFC4956A);  // light brown
    final wh = Paint()..color = Colors.white;
    final dk = Paint()..color = const Color(0xFF1A1A1A);
    final gn = Paint()..color = const Color(0xFF2D7A22);  // hat green
    final yl = Paint()..color = const Color(0xFFF5E642);  // yellow

    // Shadow
    canvas.drawOval(
        Rect.fromCenter(center: Offset(sx + sw*0.5, sy + sh + 2),
            width: sw * 0.8, height: 4),
        Paint()..color = Colors.black.withOpacity(0.25));

    // Legs (running animation based on x position)
    final legPhase = (px / 20).remainder(2 * pi);
    final leg1Y = sin(legPhase) * sh * 0.1;
    final leg2Y = sin(legPhase + pi) * sh * 0.1;
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(sx + sw*0.22, sy + sh*0.72 + leg1Y, sw*0.22, sh*0.28),
            const Radius.circular(4)),
        b);
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(sx + sw*0.55, sy + sh*0.72 + leg2Y, sw*0.22, sh*0.28),
            const Radius.circular(4)),
        b);

    // Body
    canvas.drawOval(Rect.fromCenter(
        center: Offset(sx + sw*0.50, sy + sh*0.63),
        width: sw*0.62, height: sh*0.50), b);
    canvas.drawOval(Rect.fromCenter(
        center: Offset(sx + sw*0.50, sy + sh*0.66),
        width: sw*0.36, height: sh*0.36), lb);

    // Arms
    final armPhase = legPhase + pi;
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(sx - sw*0.08, sy + sh*0.38 + sin(armPhase)*sh*0.08,
                sw*0.22, sh*0.30),
            const Radius.circular(4)),
        b);
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(sx + sw*0.86, sy + sh*0.38 + sin(legPhase)*sh*0.08,
                sw*0.22, sh*0.30),
            const Radius.circular(4)),
        b);

    // Head
    canvas.drawOval(Rect.fromCenter(
        center: Offset(sx + sw*0.50, sy + sh*0.27),
        width: sw*0.62, height: sh*0.44), b);
    canvas.drawOval(Rect.fromCenter(
        center: Offset(sx + sw*0.50, sy + sh*0.32),
        width: sw*0.42, height: sh*0.29), lb);

    // Ears
    canvas.drawCircle(Offset(sx + sw*0.14, sy + sh*0.21), sw*0.13, b);
    canvas.drawCircle(Offset(sx + sw*0.14, sy + sh*0.21), sw*0.07, lb);
    canvas.drawCircle(Offset(sx + sw*0.86, sy + sh*0.21), sw*0.13, b);
    canvas.drawCircle(Offset(sx + sw*0.86, sy + sh*0.21), sw*0.07, lb);

    // Eyes
    canvas.drawCircle(Offset(sx + sw*0.37, sy + sh*0.21), sw*0.10, wh);
    canvas.drawCircle(Offset(sx + sw*0.63, sy + sh*0.21), sw*0.10, wh);
    canvas.drawCircle(Offset(sx + sw*0.38, sy + sh*0.22), sw*0.06, dk);
    canvas.drawCircle(Offset(sx + sw*0.64, sy + sh*0.22), sw*0.06, dk);
    canvas.drawCircle(Offset(sx + sw*0.39, sy + sh*0.20), sw*0.025, wh);
    canvas.drawCircle(Offset(sx + sw*0.65, sy + sh*0.20), sw*0.025, wh);

    // Hat brim
    canvas.drawOval(Rect.fromCenter(
        center: Offset(sx + sw*0.50, sy + sh*0.088),
        width: sw*0.72, height: sh*0.095), gn);
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(sx + sw*0.22, sy, sw*0.56, sh*0.10),
            const Radius.circular(3)),
        gn);
    // Hat band
    canvas.drawRect(
        Rect.fromLTWH(sx + sw*0.20, sy + sh*0.082, sw*0.60, sh*0.026),
        Paint()..color = const Color(0xFF1A5A14));
    // Hat flower
    canvas.drawCircle(Offset(sx + sw*0.74, sy + sh*0.038), sw*0.072, yl);
    canvas.drawCircle(Offset(sx + sw*0.74, sy + sh*0.038), sw*0.032,
        Paint()..color = const Color(0xFFE8A020));

    canvas.restore();
  }

  void _drawEmojiPlayer(Canvas canvas) {
    final sx = (px - camX) * scale;
    final sy = py * scale;
    final sw = pW * scale;
    final sh = pH * scale;

    if (invincible && ((invTimer * 10).toInt() % 2 == 0)) return;

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(sx + sw * 0.5, sy + sh + 2),
        width: sw * 0.8,
        height: 4,
      ),
      Paint()..color = Colors.black.withOpacity(0.25),
    );

    final tp = TextPainter(
      text: TextSpan(
        text: playerEmoji,
        style: TextStyle(fontSize: max(sw, sh) * 0.95),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(
      canvas,
      Offset(
        sx + (sw - tp.width) / 2,
        sy + (sh - tp.height) / 2,
      ),
    );
  }

  // ── Particles ───────────────────────────────────────────────────────────

  void _drawParticles(Canvas canvas, Size size) {
    for (final p in particles) {
      final alpha = (p.life / p.maxLife).clamp(0.0, 1.0);
      final sx = (p.x - camX) * scale;
      final sy = p.y * scale;
      canvas.drawCircle(
        Offset(sx, sy),
        p.size * scale * alpha,
        Paint()..color = p.color.withOpacity(alpha),
      );
    }
  }

  // ── Floating texts ──────────────────────────────────────────────────────

  void _drawFloatingTexts(Canvas canvas, Size size) {
    for (final t in floatTexts) {
      final alpha = t.life.clamp(0.0, 1.0);
      final sx = (t.x - camX) * scale;
      final sy = t.y * scale;
      final tp = TextPainter(
        text: TextSpan(
          text: t.text,
          style: TextStyle(
            color: t.color.withOpacity(alpha),
            fontSize: 14 * scale,
            fontWeight: FontWeight.w900,
            shadows: [Shadow(color: Colors.black.withOpacity(alpha * 0.6),
                blurRadius: 3)],
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(sx - tp.width / 2, sy - tp.height / 2));
    }
  }

  @override
  bool shouldRepaint(_WorldPainter old) => true;
}

// ═══════════════════════════════════════════════════════════════════════════
//  Background Painters
// ═══════════════════════════════════════════════════════════════════════════

class _MountainsPainter extends CustomPainter {
  final double camX;
  const _MountainsPainter({required this.camX});

  @override
  void paint(Canvas canvas, Size s) {
    final p = Paint()..color = const Color(0xFF5A9A48).withOpacity(0.55);
    final offset = camX % (s.width * 2);
    void mtn(double cx, double baseY, double hw, double h) {
      final path = Path()
        ..moveTo(cx - offset, baseY)
        ..lineTo(cx - hw - offset, s.height)
        ..lineTo(cx + hw - offset, s.height)
        ..close();
      canvas.drawPath(path, p);
    }
    for (int i = -1; i <= 3; i++) {
      mtn(s.width * (i * 0.7 + 0.1), s.height * 0.55, s.width * 0.18, s.height * 0.45);
      mtn(s.width * (i * 0.7 + 0.4), s.height * 0.60, s.width * 0.14, s.height * 0.40);
    }
  }

  @override
  bool shouldRepaint(_MountainsPainter old) => old.camX != camX;
}

class _TreeLayerPainter extends CustomPainter {
  final double camX;
  const _TreeLayerPainter({required this.camX});

  @override
  void paint(Canvas canvas, Size s) {
    final trunk = Paint()..color = const Color(0xFF5C3D1E).withOpacity(0.7);
    final crown = Paint()..color = const Color(0xFF2A6A15).withOpacity(0.65);
    final offset = camX % (s.width * 1.5);

    void tree(double x, double baseY, double h) {
      final tx = x - offset;
      canvas.drawRect(
          Rect.fromLTWH(tx - 4, baseY - h * 0.3, 8, h * 0.3), trunk);
      canvas.drawOval(
          Rect.fromCenter(center: Offset(tx, baseY - h * 0.5),
              width: h * 0.45, height: h * 0.6), crown);
      canvas.drawOval(
          Rect.fromCenter(center: Offset(tx, baseY - h * 0.7),
              width: h * 0.32, height: h * 0.42),
          Paint()..color = const Color(0xFF358A1A).withOpacity(0.6));
    }

    final baseY = s.height * 0.88;
    for (int i = -1; i <= 4; i++) {
      tree(s.width * (i * 0.28 + 0.05), baseY, s.height * 0.32);
      tree(s.width * (i * 0.28 + 0.18), baseY, s.height * 0.24);
    }
  }

  @override
  bool shouldRepaint(_TreeLayerPainter old) => old.camX != camX;
}

// ═══════════════════════════════════════════════════════════════════════════
//  Reusable small widgets
// ═══════════════════════════════════════════════════════════════════════════

class _CloudWidget extends StatelessWidget {
  final double width, height;
  const _CloudWidget({required this.width, required this.height});

  @override
  Widget build(BuildContext context) {
    return Stack(clipBehavior: Clip.none, children: [
              Container(
        width: width, height: height,
                decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.88),
                  borderRadius: BorderRadius.circular(height / 2),
                ),
              ),
        Positioned(
        top: -(height * 0.4), left: width * 0.22,
                child: Container(
          width: width * 0.45, height: height * 0.82,
                  decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.88),
            borderRadius: BorderRadius.circular(height * 0.45),
              ),
            ),
          ),
    ]);
  }
}

class _ChargeBar extends StatelessWidget {
  final double ratio, width;
  const _ChargeBar({required this.ratio, required this.width});

  @override
  Widget build(BuildContext context) {
    final color = Color.lerp(
        const Color(0xFFF5E642), const Color(0xFFFF3300), ratio)!;
    return Column(mainAxisSize: MainAxisSize.min, children: [
      if (ratio > 0.88)
        Container(
          margin: const EdgeInsets.only(bottom: 2),
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
          decoration: BoxDecoration(
            color: const Color(0xFFFF3300).withOpacity(0.9),
            borderRadius: BorderRadius.circular(4),
          ),
          child: const Text('MAX!',
              style: TextStyle(fontFamily: 'FredokaOne', fontSize: 9,
                  color: Colors.white)),
        ),
      Container(
        width: width, height: 5,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.28),
          borderRadius: BorderRadius.circular(3),
        ),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Container(
            width: width * ratio, height: 5,
            decoration: BoxDecoration(
              color: color, borderRadius: BorderRadius.circular(3),
            ),
          ),
        ),
      ),
    ]);
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  Level Complete Dialog
// ═══════════════════════════════════════════════════════════════════════════

class _LevelCompleteDialog extends StatelessWidget {
  final int level;
  final int score, coins;
  final VoidCallback onNext, onHome;
  const _LevelCompleteDialog(
      {required this.level, required this.score, required this.coins,
       required this.onNext, required this.onHome});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
          child: Stack(
            children: [
            Positioned.fill(
              child: Container(
                color: const Color(0xCC1A3A10),
              ),
            ),
            Positioned.fill(
              child: Image.asset(
                'assets/images/firework.gif',
                fit: BoxFit.cover,
              ),
            ),
              Container(
              padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: JColors.yellow.withOpacity(0.5), width: 2),
              ),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                 Image.asset(
                'assets/images/Trophy.gif',
                height: 100,
                // fit: BoxFit.cover,
              ),
                const SizedBox(height: 8),
                const Text('Level Complete!',
                    style: TextStyle(fontFamily: 'FredokaOne',
                        fontSize: 28, color: JColors.yellow)),
                const SizedBox(height: 4),
                Text(
                  'Level $level Completed',
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: Colors.white.withOpacity(0.85),
                  ),
                ),
                const SizedBox(height: 16),
                _statRow('Score', '$score'),
                _statRow('Coins', '$coins 🪙'),
                const SizedBox(height: 20),
                Row(children: [
                  Expanded(child: _btn('Next Level', JColors.yellow,
                      const Color(0xFF1A2A10), onNext)),
                  const SizedBox(width: 10),
                  Expanded(child: _btn('Home', Colors.white.withOpacity(0.15),
                      Colors.white, onHome)),
                ]),
              ]),
              ),
            ],
          ),
        ),
      );
  }

  Widget _statRow(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: TextStyle(fontFamily: 'Nunito', fontSize: 14,
          color: Colors.white.withOpacity(0.6), fontWeight: FontWeight.w600)),
      Text(value, style: const TextStyle(fontFamily: 'FredokaOne',
          fontSize: 16, color: JColors.yellow)),
    ]),
  );

  Widget _btn(String label, Color bg, Color fg, VoidCallback onTap) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(color: bg,
              borderRadius: BorderRadius.circular(12)),
          child: Center(child: Text(label,
              style: TextStyle(fontFamily: 'FredokaOne',
                  fontSize: 16, color: fg))),
        ),
      );
}
