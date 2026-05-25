import 'dart:math';

import 'game_constants.dart';
import 'game_models.dart';

LevelData buildLevel(int levelNum) {
  final level = levelNum.clamp(1, kMaxLevel);
  final difficulty = (level - 1) / (kMaxLevel - 1);
  const double ground = kWorldH - kTile;

  final plats = <Platform>[];
  final enemies = <Enemy>[];
  final coins = <Collectible>[];
  final rng = Random(level);

  void gRow(double startX, double endX) {
    for (double x = startX; x < endX; x += kTile) {
      plats.add(Platform(x, ground, kTile, kTile, TileType.ground));
      plats.add(
        Platform(x, ground + kTile, kTile, kTile * 20, TileType.ground),
      );
    }
  }

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

  void fPlat(double x, double y, int cols, TileType t) {
    for (int i = 0; i < cols; i++) {
      plats.add(Platform(x + i * kTile, y, kTile, kTile * 0.5, t));
    }
  }

  for (double x = kTile * 8; x < kTile * 90; x += kTile * 7.5) {
    final y =
        ground - kTile * (2.8 + rng.nextDouble() * (2.2 + difficulty * 2));
    final cols = (2 + rng.nextInt(3)) - (difficulty > 0.65 ? 1 : 0);
    fPlat(
      x,
      y,
      cols.clamp(1, 4),
      rng.nextBool() ? TileType.platform : TileType.brick,
    );
  }

  void breakBlock(double x, double y) {
    plats.add(Platform(x, y, kTile, kTile * 0.6, TileType.breakable));
    coins.add(Collectible(x + kTile * 0.5 - 16, y - kTile, PowerUpType.coin));
  }

  for (double x = kTile * 7; x < kTile * 90; x += kTile * 11) {
    if (rng.nextDouble() > 0.25 + difficulty * 0.2) {
      breakBlock(x, ground - kTile * (3 + rng.nextInt(2)));
    }
  }

  void pipe(double x) {
    plats.add(
      Platform(
        x,
        ground - kTile * 2.5,
        kTile * 1.5,
        kTile * 0.5,
        TileType.pipe,
      ),
    );
    plats.add(
      Platform(
        x + kTile * 0.15,
        ground - kTile * 2,
        kTile * 1.2,
        kTile * 2,
        TileType.pipe,
      ),
    );
  }

  final pipeStep = mix(18, 11);
  for (double x = kTile * 18; x < kTile * 92; x += kTile * pipeStep) {
    if (rng.nextDouble() < (0.45 + difficulty * 0.35)) {
      pipe(x);
    }
  }

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

  void coinRow(double startX, double y, int count) {
    for (int i = 0; i < count; i++) {
      coins.add(
        Collectible(
          startX + i * kTile * 0.8,
          y - kTile * 0.8,
          PowerUpType.coin,
        ),
      );
    }
  }

  for (double x = kTile * 5; x < kTile * 88; x += kTile * 10) {
    final y =
        ground - kTile * (rng.nextDouble() < 0.6 ? 0 : (3 + rng.nextInt(4)));
    coinRow(x, y, (2 + rng.nextInt(4)).clamp(2, 5));
  }

  final starCount = max(1, 3 - (difficulty * 2).round());
  for (int i = 0; i < starCount; i++) {
    final sx = (12 + i * 24 + rng.nextInt(10)) * kTile;
    final sy = ground - (3 + rng.nextInt(5)) * kTile;
    coins.add(Collectible(sx, sy, PowerUpType.star));
  }

  return LevelData(
    platforms: plats,
    enemies: enemies,
    collectibles: coins,
    worldWidth: kTile * 96.0,
    goalX: kTile * 93,
  );
}
