import 'dart:ui';

import 'game_constants.dart';

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
  double deathTimer;
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
  double floatPhase;
  Collectible(this.x, this.y, this.type) : collected = false, floatPhase = 0;
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
  FloatingText(this.x, this.y, this.text, this.color) : vy = -120, life = 1.0;
}

class LevelData {
  final List<Platform> platforms;
  final List<Enemy> enemies;
  final List<Collectible> collectibles;
  final double worldWidth;
  final double goalX;

  const LevelData({
    required this.platforms,
    required this.enemies,
    required this.collectibles,
    required this.worldWidth,
    required this.goalX,
  });
}

/// Mutable view state read by [WorldPainter] each frame (no widget rebuild).
class GameWorldSnapshot {
  LevelData? level;
  double camX = 0;
  double scale = 1;
  double px = 0;
  double py = 0;
  double pW = kTile * 0.72;
  double pH = kTile * 0.88;
  bool invincible = false;
  double invTimer = 0;
  double goalX = 0;
  double timeElapsed = 0;
  String playerEmoji = '🐒';
  final List<Particle> particles = [];
  final List<FloatingText> floatTexts = [];
}
