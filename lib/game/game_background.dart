import 'package:flutter/material.dart';

import 'game_constants.dart';

class GameMountainsPainter extends CustomPainter {
  final double camX;
  const GameMountainsPainter({required this.camX});

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
      mtn(
        s.width * (i * 0.7 + 0.1),
        s.height * 0.55,
        s.width * 0.18,
        s.height * 0.45,
      );
      mtn(
        s.width * (i * 0.7 + 0.4),
        s.height * 0.60,
        s.width * 0.14,
        s.height * 0.40,
      );
    }
  }

  @override
  bool shouldRepaint(GameMountainsPainter old) => old.camX != camX;
}

class GameTreeLayerPainter extends CustomPainter {
  final double camX;
  const GameTreeLayerPainter({required this.camX});

  @override
  void paint(Canvas canvas, Size s) {
    final trunk = Paint()..color = const Color(0xFF5C3D1E).withOpacity(0.7);
    final crown = Paint()..color = const Color(0xFF2A6A15).withOpacity(0.65);
    final offset = camX % (s.width * 1.5);

    void tree(double x, double baseY, double h) {
      final tx = x - offset;
      canvas.drawRect(
        Rect.fromLTWH(tx - 4, baseY - h * 0.3, 8, h * 0.3),
        trunk,
      );
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(tx, baseY - h * 0.5),
          width: h * 0.45,
          height: h * 0.6,
        ),
        crown,
      );
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(tx, baseY - h * 0.7),
          width: h * 0.32,
          height: h * 0.42,
        ),
        Paint()..color = const Color(0xFF358A1A).withOpacity(0.6),
      );
    }

    final baseY = s.height * 0.88;
    for (int i = -1; i <= 4; i++) {
      tree(s.width * (i * 0.28 + 0.05), baseY, s.height * 0.32);
      tree(s.width * (i * 0.28 + 0.18), baseY, s.height * 0.24);
    }
  }

  @override
  bool shouldRepaint(GameTreeLayerPainter old) => old.camX != camX;
}

class GameCloudWidget extends StatelessWidget {
  final double width, height;
  const GameCloudWidget({required this.width, required this.height});

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.88),
            borderRadius: BorderRadius.circular(height / 2),
          ),
        ),
        Positioned(
          top: -(height * 0.4),
          left: width * 0.22,
          child: Container(
            width: width * 0.45,
            height: height * 0.82,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.88),
              borderRadius: BorderRadius.circular(height * 0.45),
            ),
          ),
        ),
      ],
    );
  }
}

List<Widget> buildParallaxClouds({
  required double width,
  required double height,
  required double camX,
}) {
  const clouds = [
    [0.05, 0.08, 110.0, 44.0],
    [0.30, 0.13, 80.0, 32.0],
    [0.55, 0.06, 130.0, 50.0],
    [0.75, 0.15, 90.0, 36.0],
  ];
  return clouds.map((c) {
    final cloudW = c[2];
    final cloudH = c[3];
    final baseX = c[0] * width * 4;
    final screenX =
        baseX - (camX * 0.25 * (width / (kWorldH * 1.6))) % (width * 4);
    return Positioned(
      top: height * c[1],
      left: screenX % (width + cloudW) - cloudW,
      child: GameCloudWidget(width: cloudW, height: cloudH),
    );
  }).toList();
}
