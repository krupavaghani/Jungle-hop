import 'dart:math';

import 'package:flutter/material.dart';

import 'game_constants.dart';
import 'game_models.dart';

/// Renders the scrolling game world. Repaints via [repaint] without rebuilding widgets.
class WorldPainter extends CustomPainter {
  WorldPainter(this.snapshot, {required Listenable repaint})
      : super(repaint: repaint);

  final GameWorldSnapshot snapshot;

  LevelData get level => snapshot.level!;
  double get camX => snapshot.camX;
  double get scale => snapshot.scale;
  double get px => snapshot.px;
  double get py => snapshot.py;
  double get pW => snapshot.pW;
  double get pH => snapshot.pH;
  bool get facingRight => true;
  bool get invincible => snapshot.invincible;
  double get invTimer => snapshot.invTimer;
  double get goalX => snapshot.goalX;
  double get timeElapsed => snapshot.timeElapsed;
  String get playerEmoji => snapshot.playerEmoji;
  List<Enemy> get enemies => level.enemies;
  List<Collectible> get collectibles => level.collectibles;
  List<Particle> get particles => snapshot.particles;
  List<FloatingText> get floatTexts => snapshot.floatTexts;

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
    canvas.drawRect(
      Rect.fromLTWH(r.left, r.top, r.width, r.height * 0.28),
      Paint()..color = const Color(0xFF4DBF2A),
    );
    // Mid green
    canvas.drawRect(
      Rect.fromLTWH(r.left, r.top + r.height * 0.28, r.width, r.height * 0.15),
      Paint()..color = const Color(0xFF3AA020),
    );
    // Dirt
    canvas.drawRect(
      Rect.fromLTWH(r.left, r.top + r.height * 0.43, r.width, r.height * 0.57),
      Paint()..color = const Color(0xFF8B5E2A),
    );
    // Border
    canvas.drawRect(
      r,
      Paint()
        ..color = const Color(0xFF2A8A10)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.5,
    );
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
    canvas.drawRect(
      Rect.fromLTWH(r.left + 1, r.top + 1, r.width - 2, r.height * 0.35),
      Paint()..color = const Color(0xFF9AE060),
    );
    canvas.drawRect(
      r,
      Paint()
        ..color = const Color(0xFF4A8A20)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8,
    );
  }

  void _drawBrickTile(Canvas canvas, Rect r) {
    canvas.drawRect(r, Paint()..color = const Color(0xFFC44820));
    // Brick pattern
    final lines = Paint()
      ..color = const Color(0xFFA03010)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;
    canvas.drawLine(
      Offset(r.left, r.top + r.height / 2),
      Offset(r.right, r.top + r.height / 2),
      lines,
    );
    canvas.drawLine(
      Offset(r.left + r.width * 0.5, r.top),
      Offset(r.left + r.width * 0.5, r.top + r.height / 2),
      lines,
    );
    canvas.drawLine(
      Offset(r.left + r.width * 0.25, r.top + r.height / 2),
      Offset(r.left + r.width * 0.25, r.bottom),
      lines,
    );
    canvas.drawLine(
      Offset(r.left + r.width * 0.75, r.top + r.height / 2),
      Offset(r.left + r.width * 0.75, r.bottom),
      lines,
    );
    // Top highlight
    canvas.drawRect(
      Rect.fromLTWH(r.left + 1, r.top + 1, r.width - 2, 2),
      Paint()..color = const Color(0xFFE06030).withOpacity(0.5),
    );
  }

  void _drawBreakableTile(Canvas canvas, Rect r) {
    // Gold/question block
    canvas.drawRRect(
      RRect.fromRectAndRadius(r, const Radius.circular(3)),
      Paint()..color = const Color(0xFFE8A020),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(r.deflate(1.5), const Radius.circular(2)),
      Paint()..color = const Color(0xFFF5C040),
    );
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
    tp.paint(
      canvas,
      Offset(
        r.left + (r.width - tp.width) / 2,
        r.top + (r.height - tp.height) / 2,
      ),
    );
    // Border
    canvas.drawRRect(
      RRect.fromRectAndRadius(r, const Radius.circular(3)),
      Paint()
        ..color = const Color(0xFFA07000)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0,
    );
  }

  void _drawPipeTile(Canvas canvas, Rect r, Rect2 bounds) {
    // Green pipe
    canvas.drawRect(r, Paint()..color = const Color(0xFF2A8A18));
    // Highlight left strip
    canvas.drawRect(
      Rect.fromLTWH(r.left + 2, r.top, r.width * 0.25, r.height),
      Paint()..color = const Color(0xFF4AB830).withOpacity(0.6),
    );
    // Dark right edge
    canvas.drawRect(
      Rect.fromLTWH(r.right - 3, r.top, 3, r.height),
      Paint()..color = const Color(0xFF1A6010),
    );
    canvas.drawRect(
      r,
      Paint()
        ..color = const Color(0xFF1A6010)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8,
    );
  }

  void _drawWaterTile(Canvas canvas, Rect r) {
    canvas.drawRect(
      r,
      Paint()..color = const Color(0xFF2060E0).withOpacity(0.7),
    );
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
        ..color = const Color(
          0x80FFF176,
        ).withOpacity(0.25 + nearFactor * 0.35 + pulse * 0.1),
    );

    // Stronger pulse ring around flag when player gets near.
    if (nearFactor > 0) {
      canvas.drawCircle(
        Offset(sx, groundY - kTile * 7.5 * scale),
        (18 + pulse * 10 + nearFactor * 20) * scale,
        Paint()
          ..color = const Color(
            0xFFFFF176,
          ).withOpacity(0.12 + nearFactor * 0.18)
          ..style = PaintingStyle.stroke
          ..strokeWidth = (1.2 + nearFactor * 1.8) * scale,
      );
    }

    // Pole
    final polePaint = Paint()
      ..color = const Color(0xFF888888)
      ..strokeWidth = 3 * scale;
    canvas.drawLine(
      Offset(sx, groundY - kTile * 8 * scale),
      Offset(sx, groundY),
      polePaint,
    );

    // Flag wave
    final flagPath = Path()
      ..moveTo(sx, groundY - kTile * 8 * scale)
      ..quadraticBezierTo(
        sx + 30 * scale + sin(timeElapsed * 3) * 8 * scale,
        groundY - kTile * 7.5 * scale,
        sx + 24 * scale,
        groundY - kTile * 7 * scale,
      )
      ..quadraticBezierTo(
        sx + 30 * scale + sin(timeElapsed * 3) * 6 * scale,
        groundY - kTile * 7.5 * scale,
        sx,
        groundY - kTile * 7 * scale,
      );
    canvas.drawPath(flagPath, Paint()..color = const Color(0xFFE84040));
    canvas.drawPath(
      flagPath,
      Paint()
        ..color = const Color(0xFFC03030)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8,
    );

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
      Offset(sx - finishPainter.width / 2, groundY - kTile * 8.8 * scale),
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
      final r = Rect.fromLTWH(sx, sy, sz, sz);

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
    canvas.drawOval(
      r.deflate(r.width * 0.1),
      Paint()..color = const Color(0xFFFFD840),
    );
    // Shine
    canvas.drawOval(
      Rect.fromLTWH(
        r.left + r.width * 0.2,
        r.top + r.height * 0.15,
        r.width * 0.25,
        r.height * 0.2,
      ),
      Paint()..color = Colors.white.withOpacity(0.4),
    );
  }

  void _drawStar(Canvas canvas, Offset center, double radius) {
    final path = Path();
    for (int i = 0; i < 10; i++) {
      final angle = (i * pi / 5) - pi / 2;
      final r = i.isEven ? radius : radius * 0.45;
      final pt = Offset(center.dx + cos(angle) * r, center.dy + sin(angle) * r);
      if (i == 0)
        path.moveTo(pt.dx, pt.dy);
      else
        path.lineTo(pt.dx, pt.dy);
    }
    path.close();
    canvas.drawPath(path, Paint()..color = const Color(0xFFFFD820));
    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0xFFE8B800)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
  }

  // ── Enemies ─────────────────────────────────────────────────────────────

  void _drawEnemies(Canvas canvas, Size size) {
    for (final e in enemies) {
      final sx = (e.x - camX) * scale;
      if (sx < -60 || sx > size.width + 60) continue;

      if (!e.alive) {
        if (e.deathTimer > 0) {
          // Dead mushroom squish
          final r = Rect.fromLTWH(
            sx,
            e.y * scale,
            kTile * 0.75 * scale,
            kTile * 0.3 * scale,
          );
          canvas.drawOval(
            r,
            Paint()..color = const Color(0xFFA04020).withOpacity(0.6),
          );
        }
        continue;
      }

      final sy = e.y * scale;
      final ew = kTile * 0.75 * scale;
      final eh = kTile * 0.75 * scale;

      switch (e.type) {
        case EnemyType.mushroom:
          _drawMushroom(canvas, sx, sy, ew, eh, e.facingLeft);
          break;
        case EnemyType.turtle:
          _drawTurtle(canvas, sx, sy, ew, eh, e.facingLeft);
          break;
        case EnemyType.fly:
          _drawFly(canvas, sx, sy, ew, eh, e.facingLeft);
          break;
      }
    }
  }

  void _drawMushroom(
    Canvas canvas,
    double sx,
    double sy,
    double ew,
    double eh,
    bool fl,
  ) {
    // Body
    canvas.drawOval(
      Rect.fromLTWH(sx + ew * 0.1, sy + eh * 0.4, ew * 0.8, eh * 0.55),
      Paint()..color = const Color(0xFFC8481A),
    );
    // Cap
    final capPath = Path()
      ..moveTo(sx, sy + eh * 0.45)
      ..quadraticBezierTo(sx + ew * 0.5, sy - eh * 0.1, sx + ew, sy + eh * 0.45)
      ..close();
    canvas.drawPath(capPath, Paint()..color = const Color(0xFFE84820));
    // White spots on cap
    canvas.drawCircle(
      Offset(sx + ew * 0.3, sy + eh * 0.22),
      ew * 0.10,
      Paint()..color = Colors.white,
    );
    canvas.drawCircle(
      Offset(sx + ew * 0.65, sy + eh * 0.20),
      ew * 0.08,
      Paint()..color = Colors.white,
    );
    // Eyes
    final ex = fl ? sx + ew * 0.62 : sx + ew * 0.28;
    canvas.drawCircle(
      Offset(ex, sy + eh * 0.50),
      ew * 0.08,
      Paint()..color = Colors.white,
    );
    canvas.drawCircle(
      Offset(ex + (fl ? -1 : 1) * ew * 0.02, sy + eh * 0.51),
      ew * 0.05,
      Paint()..color = Colors.black,
    );
    // Feet
    canvas.drawOval(
      Rect.fromLTWH(sx + ew * 0.05, sy + eh * 0.88, ew * 0.35, eh * 0.12),
      Paint()..color = const Color(0xFF8B3010),
    );
    canvas.drawOval(
      Rect.fromLTWH(sx + ew * 0.60, sy + eh * 0.88, ew * 0.35, eh * 0.12),
      Paint()..color = const Color(0xFF8B3010),
    );
  }

  void _drawTurtle(
    Canvas canvas,
    double sx,
    double sy,
    double ew,
    double eh,
    bool fl,
  ) {
    // Shell
    canvas.drawOval(
      Rect.fromLTWH(sx + ew * 0.1, sy + eh * 0.2, ew * 0.8, eh * 0.7),
      Paint()..color = const Color(0xFF2A8A18),
    );
    canvas.drawOval(
      Rect.fromLTWH(sx + ew * 0.18, sy + eh * 0.26, ew * 0.64, eh * 0.56),
      Paint()..color = const Color(0xFF3AA820),
    );
    // Shell pattern
    final sp = Paint()
      ..color = const Color(0xFF1A6A10)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;
    canvas.drawLine(
      Offset(sx + ew * 0.5, sy + eh * 0.26),
      Offset(sx + ew * 0.5, sy + eh * 0.82),
      sp,
    );
    canvas.drawLine(
      Offset(sx + ew * 0.18, sy + eh * 0.54),
      Offset(sx + ew * 0.82, sy + eh * 0.54),
      sp,
    );
    // Head
    final hx = fl ? sx + ew * 0.05 : sx + ew * 0.65;
    canvas.drawOval(
      Rect.fromLTWH(hx, sy + eh * 0.28, ew * 0.28, eh * 0.28),
      Paint()..color = const Color(0xFF5AC830),
    );
    canvas.drawCircle(
      Offset(hx + (fl ? ew * 0.08 : ew * 0.20), sy + eh * 0.35),
      ew * 0.05,
      Paint()..color = Colors.black,
    );
    // Feet
    for (final fx in [0.12, 0.60]) {
      canvas.drawOval(
        Rect.fromLTWH(sx + ew * fx, sy + eh * 0.88, ew * 0.26, eh * 0.12),
        Paint()..color = const Color(0xFF3A9820),
      );
    }
  }

  void _drawFly(
    Canvas canvas,
    double sx,
    double sy,
    double ew,
    double eh,
    bool fl,
  ) {
    // Wings (animated by time)
    final wingY =
        sy + eh * 0.3 + sin(DateTime.now().millisecondsSinceEpoch * 0.01) * 4;
    final wingPaint = Paint()..color = Colors.lightBlue.withOpacity(0.7);
    canvas.drawOval(
      Rect.fromLTWH(sx - ew * 0.25, wingY, ew * 0.4, eh * 0.3),
      wingPaint,
    );
    canvas.drawOval(
      Rect.fromLTWH(sx + ew * 0.85, wingY, ew * 0.4, eh * 0.3),
      wingPaint,
    );
    // Body
    canvas.drawOval(
      Rect.fromLTWH(sx + ew * 0.15, sy + eh * 0.2, ew * 0.7, eh * 0.65),
      Paint()..color = const Color(0xFF2A1A40),
    );
    canvas.drawOval(
      Rect.fromLTWH(sx + ew * 0.22, sy + eh * 0.25, ew * 0.56, eh * 0.5),
      Paint()..color = const Color(0xFF4A3060),
    );
    // Red eyes
    canvas.drawCircle(
      Offset(sx + ew * (fl ? 0.68 : 0.28), sy + eh * 0.32),
      ew * 0.09,
      Paint()..color = const Color(0xFFFF2020),
    );
    // Stinger
    final stx = fl ? sx - ew * 0.05 : sx + ew * 1.05;
    canvas.drawLine(
      Offset(sx + ew * 0.5, sy + eh * 0.85),
      Offset(stx, sy + eh * 1.0),
      Paint()
        ..color = const Color(0xFFE8A020)
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round,
    );
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

    final b = Paint()..color = const Color(0xFF8B5E3C); // brown
    final lb = Paint()..color = const Color(0xFFC4956A); // light brown
    final wh = Paint()..color = Colors.white;
    final dk = Paint()..color = const Color(0xFF1A1A1A);
    final gn = Paint()..color = const Color(0xFF2D7A22); // hat green
    final yl = Paint()..color = const Color(0xFFF5E642); // yellow

    // Shadow
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(sx + sw * 0.5, sy + sh + 2),
        width: sw * 0.8,
        height: 4,
      ),
      Paint()..color = Colors.black.withOpacity(0.25),
    );

    // Legs (running animation based on x position)
    final legPhase = (px / 20).remainder(2 * pi);
    final leg1Y = sin(legPhase) * sh * 0.1;
    final leg2Y = sin(legPhase + pi) * sh * 0.1;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          sx + sw * 0.22,
          sy + sh * 0.72 + leg1Y,
          sw * 0.22,
          sh * 0.28,
        ),
        const Radius.circular(4),
      ),
      b,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          sx + sw * 0.55,
          sy + sh * 0.72 + leg2Y,
          sw * 0.22,
          sh * 0.28,
        ),
        const Radius.circular(4),
      ),
      b,
    );

    // Body
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(sx + sw * 0.50, sy + sh * 0.63),
        width: sw * 0.62,
        height: sh * 0.50,
      ),
      b,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(sx + sw * 0.50, sy + sh * 0.66),
        width: sw * 0.36,
        height: sh * 0.36,
      ),
      lb,
    );

    // Arms
    final armPhase = legPhase + pi;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          sx - sw * 0.08,
          sy + sh * 0.38 + sin(armPhase) * sh * 0.08,
          sw * 0.22,
          sh * 0.30,
        ),
        const Radius.circular(4),
      ),
      b,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          sx + sw * 0.86,
          sy + sh * 0.38 + sin(legPhase) * sh * 0.08,
          sw * 0.22,
          sh * 0.30,
        ),
        const Radius.circular(4),
      ),
      b,
    );

    // Head
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(sx + sw * 0.50, sy + sh * 0.27),
        width: sw * 0.62,
        height: sh * 0.44,
      ),
      b,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(sx + sw * 0.50, sy + sh * 0.32),
        width: sw * 0.42,
        height: sh * 0.29,
      ),
      lb,
    );

    // Ears
    canvas.drawCircle(Offset(sx + sw * 0.14, sy + sh * 0.21), sw * 0.13, b);
    canvas.drawCircle(Offset(sx + sw * 0.14, sy + sh * 0.21), sw * 0.07, lb);
    canvas.drawCircle(Offset(sx + sw * 0.86, sy + sh * 0.21), sw * 0.13, b);
    canvas.drawCircle(Offset(sx + sw * 0.86, sy + sh * 0.21), sw * 0.07, lb);

    // Eyes
    canvas.drawCircle(Offset(sx + sw * 0.37, sy + sh * 0.21), sw * 0.10, wh);
    canvas.drawCircle(Offset(sx + sw * 0.63, sy + sh * 0.21), sw * 0.10, wh);
    canvas.drawCircle(Offset(sx + sw * 0.38, sy + sh * 0.22), sw * 0.06, dk);
    canvas.drawCircle(Offset(sx + sw * 0.64, sy + sh * 0.22), sw * 0.06, dk);
    canvas.drawCircle(Offset(sx + sw * 0.39, sy + sh * 0.20), sw * 0.025, wh);
    canvas.drawCircle(Offset(sx + sw * 0.65, sy + sh * 0.20), sw * 0.025, wh);

    // Hat brim
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(sx + sw * 0.50, sy + sh * 0.088),
        width: sw * 0.72,
        height: sh * 0.095,
      ),
      gn,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(sx + sw * 0.22, sy, sw * 0.56, sh * 0.10),
        const Radius.circular(3),
      ),
      gn,
    );
    // Hat band
    canvas.drawRect(
      Rect.fromLTWH(sx + sw * 0.20, sy + sh * 0.082, sw * 0.60, sh * 0.026),
      Paint()..color = const Color(0xFF1A5A14),
    );
    // Hat flower
    canvas.drawCircle(Offset(sx + sw * 0.74, sy + sh * 0.038), sw * 0.072, yl);
    canvas.drawCircle(
      Offset(sx + sw * 0.74, sy + sh * 0.038),
      sw * 0.032,
      Paint()..color = const Color(0xFFE8A020),
    );

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
      Offset(sx + (sw - tp.width) / 2, sy + (sh - tp.height) / 2),
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
            shadows: [
              Shadow(
                color: Colors.black.withOpacity(alpha * 0.6),
                blurRadius: 3,
              ),
            ],
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(sx - tp.width / 2, sy - tp.height / 2));
    }
  }

  @override
  bool shouldRepaint(covariant WorldPainter old) => false;
}
