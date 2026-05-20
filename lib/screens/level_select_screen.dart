import 'dart:math';
import 'package:flutter/material.dart';

import '../services/level_progress_service.dart';
import 'game_screen.dart';

enum LevelState { completed, unlocked, locked }

class LevelData {
  final int number;
  final LevelState state;
  final int stars;
  const LevelData(this.number, this.state, {this.stars = 0});
}

class LevelSelectScreen extends StatefulWidget {
  const LevelSelectScreen({super.key});

  @override
  State<LevelSelectScreen> createState() => _LevelSelectScreenState();
}

class _LevelSelectScreenState extends State<LevelSelectScreen>
    with TickerProviderStateMixin {
  int _unlockedLevel = 1;
  bool _loading = true;

  late final ScrollController _scroll;
  late final AnimationController _pulseCtrl;
  late final AnimationController _floatCtrl;
  late final AnimationController _godRayCtrl;
  late final Animation<double> _pulse;
  late final Animation<double> _float;
  late final Animation<double> _godRay;

  static const List<int> _colPattern = [0, 2, 1];
  static const double _rowH = 170.0;
  static const double _canvasW = 420.0;
  static const double _stoneW = 130.0;
  static const double _stoneH = 70.0;

  static double _xFor(int col) {
    switch (col) {
      case 0:
        return 40.0;
      case 1:
        return (_canvasW - _stoneW) / 2;
      case 2:
        return _canvasW - _stoneW - 40.0;
      default:
        return _canvasW / 2;
    }
  }

  List<LevelData> get _levels {
    return List.generate(LevelProgressService.maxLevel, (index) {
      final level = index + 1;
      if (level < _unlockedLevel) {
        return LevelData(level, LevelState.completed, stars: 3);
      }
      if (level == _unlockedLevel) {
        return LevelData(level, LevelState.unlocked);
      }
      return LevelData(level, LevelState.locked);
    });
  }

  Offset _stoneCenter(int idx) {
    final col = _colPattern[idx % _colPattern.length];
    final x = _xFor(col) + _stoneW / 2;
    final y = 80.0 + idx * _rowH + _stoneH / 2;
    return Offset(x, y);
  }

  double get _totalCanvasH => 80.0 + _levels.length * _rowH + 100.0;

  @override
  void initState() {
    super.initState();
    _scroll = ScrollController();

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _pulse = Tween<double>(
      begin: 0.94,
      end: 1.06,
    ).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));

    _floatCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
    _float = Tween<double>(
      begin: -5.0,
      end: 5.0,
    ).animate(CurvedAnimation(parent: _floatCtrl, curve: Curves.easeInOut));

    _godRayCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
    _godRay = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _godRayCtrl, curve: Curves.easeInOut));

    _loadProgress();
  }

  Future<void> _loadProgress() async {
    final unlocked = await LevelProgressService.getHighestUnlockedLevel();
    if (!mounted) return;
    setState(() {
      _unlockedLevel = unlocked;
      _loading = false;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scroll.hasClients) return;
      final idx = (_unlockedLevel - 1).clamp(0, _levels.length - 1);
      final scale = MediaQuery.of(context).size.width / _canvasW;
      _scroll.animateTo(
        ((idx * _rowH) - 200.0).clamp(0.0, double.infinity) * scale,
        duration: const Duration(milliseconds: 700),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    _pulseCtrl.dispose();
    _floatCtrl.dispose();
    _godRayCtrl.dispose();
    super.dispose();
  }

  void _openLevel(int level) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => GameScreen(level: level)),
    ).then((_) => _loadProgress());
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final levels = _levels;
    final screenW = MediaQuery.of(context).size.width;
    final scale = screenW / _canvasW;
    final canvasH = _totalCanvasH;

    return Scaffold(
      backgroundColor: const Color(0xFF051505),
      body: Stack(
        children: [
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _godRay,
              builder: (_, __) => CustomPaint(
                painter: _JungleBgPainter(godRayT: _godRay.value),
              ),
            ),
          ),
          SingleChildScrollView(
            controller: _scroll,
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.only(top: 20),
              child: SizedBox(
                width: screenW,
                height: canvasH * scale,
                child: AnimatedBuilder(
                  animation: Listenable.merge([_pulse, _float]),
                  builder: (_, __) => CustomPaint(
                    size: Size(screenW, canvasH * scale),
                    painter: _PathPainter(
                      levels: levels,
                      scale: scale,
                      stoneCenter: _stoneCenter,
                    ),
                    child: Stack(
                      children: List.generate(
                        levels.length,
                        (i) => _buildStoneWidget(levels[i], i, scale),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(painter: _ForegroundLeavesPainter()),
            ),
          ),
          _buildTopBar(context),
        ],
      ),
    );
  }

  Widget _buildStoneWidget(LevelData lvl, int idx, double scale) {
    final center = _stoneCenter(idx);
    final sw = _stoneW * scale;
    final sh = _stoneH * scale;
    final isUnlocked = lvl.state == LevelState.unlocked;

    return Positioned(
      left: (center.dx - _stoneW / 2) * scale,
      top: (center.dy - _stoneH / 2) * scale,
      width: sw,
      height: sh,
      child: GestureDetector(
        onTap: () {
          if (lvl.state == LevelState.locked) {
            return;
          }
          _openLevel(lvl.number);
        },
        child: AnimatedBuilder(
          animation: Listenable.merge([_pulse, _float]),
          builder: (_, __) {
            double dy = 0;
            double sc = 1.0;
            if (isUnlocked) {
              dy = _float.value;
              sc = _pulse.value;
            }
            return Transform.translate(
              offset: Offset(0, dy),
              child: Transform.scale(
                scale: sc,
                child: _StoneNodeWidget(level: lvl, isSelected: false),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    final completed = (_unlockedLevel - 1).clamp(0, _levels.length);
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: EdgeInsets.only(top: top + 8, left: 16, right: 16, bottom: 20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF020D02).withOpacity(0.97),
              Colors.transparent,
            ],
          ),
        ),
        child: Row(
          children: [
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.12),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withOpacity(0.2)),
                ),
                child: const Icon(
                  Icons.arrow_back_ios_new,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ),
            const Spacer(),
            Column(
              children: [
                const Text(
                  'Levels',
                  style: TextStyle(
                    fontFamily: 'Georgia',
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 3.5,
                    shadows: [
                      Shadow(
                        blurRadius: 16,
                        color: Color(0xFF44FF44),
                        offset: Offset(0, 0),
                      ),
                      Shadow(
                        blurRadius: 4,
                        color: Colors.black,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$completed / ${_levels.length} complete',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.7),
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }
}

class _JungleBgPainter extends CustomPainter {
  final double godRayT;
  const _JungleBgPainter({required this.godRayT});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF030E03),
            Color(0xFF071A07),
            Color(0xFF0D2E0A),
            Color(0xFF0A2208),
            Color(0xFF040C04),
          ],
          stops: [0.0, 0.2, 0.5, 0.78, 1.0],
        ).createShader(Rect.fromLTWH(0, 0, w, h)),
    );

    _drawFarTrees(canvas, w, h);
    _drawGodRays(canvas, w, h);
    _drawMidLeaves(canvas, w, h);
    _drawAtmosphere(canvas, w, h);
    _drawVignette(canvas, w, h);
  }

  void _drawFarTrees(Canvas canvas, double w, double h) {
    final rng = Random(42);
    final layerDefs = [
      (
        color: const Color(0xFF081408),
        yBase: 0.72,
        cnt: 9,
        maxH: 0.48,
        wf: 0.17,
      ),
      (
        color: const Color(0xFF0C1E0C),
        yBase: 0.78,
        cnt: 11,
        maxH: 0.40,
        wf: 0.21,
      ),
      (
        color: const Color(0xFF112611),
        yBase: 0.84,
        cnt: 13,
        maxH: 0.33,
        wf: 0.25,
      ),
    ];

    for (final layer in layerDefs) {
      final paint = Paint()..color = layer.color;
      for (int i = 0; i < layer.cnt; i++) {
        final x = rng.nextDouble() * w;
        final treeH = (0.25 + rng.nextDouble() * 0.75) * layer.maxH * h;
        final treeW = (0.5 + rng.nextDouble() * 0.5) * layer.wf * w;
        final baseY = layer.yBase * h;

        canvas.drawRect(
          Rect.fromLTWH(
            x - treeW * 0.06,
            baseY - treeH * 0.32,
            treeW * 0.12,
            treeH * 0.34,
          ),
          paint,
        );
        for (int t = 0; t < 3; t++) {
          canvas.drawOval(
            Rect.fromCenter(
              center: Offset(x, baseY - treeH * (0.32 + t * 0.26)),
              width: treeW * (1.0 - t * 0.15),
              height: treeW * (0.6 - t * 0.05),
            ),
            paint,
          );
        }
      }
    }
  }

  void _drawGodRays(Canvas canvas, double w, double h) {
    final rays = [
      (xf: 0.22, ang: 10.0, wf: 0.13),
      (xf: 0.50, ang: -7.0, wf: 0.20),
      (xf: 0.78, ang: 14.0, wf: 0.11),
    ];

    for (int ri = 0; ri < rays.length; ri++) {
      final r = rays[ri];
      final phase = (godRayT + ri * 0.34) % 1.0;
      final opacity = 0.035 + phase * 0.045;
      final startX = r.xf * w;
      final endX = startX + h * tan(r.ang * pi / 180.0);
      final rw = r.wf * w;

      final path = Path()
        ..moveTo(startX - rw * 0.5, 0)
        ..lineTo(startX + rw * 0.5, 0)
        ..lineTo(endX + rw * 1.6, h)
        ..lineTo(endX - rw * 0.4, h)
        ..close();

      canvas.drawPath(
        path,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFFAAFF66).withOpacity(opacity),
              const Color(0xFF66FF22).withOpacity(opacity * 0.35),
              Colors.transparent,
            ],
            stops: const [0.0, 0.38, 1.0],
          ).createShader(Rect.fromLTWH(0, 0, w, h)),
      );
    }
  }

  void _drawMidLeaves(Canvas canvas, double w, double h) {
    final rng = Random(77);
    final colors = [
      const Color(0xFF143A14),
      const Color(0xFF1A4A18),
      const Color(0xFF1E5220),
      const Color(0xFF122E12),
    ];

    for (int i = 0; i < 22; i++) {
      final lx = rng.nextDouble() * w;
      final ly = (0.08 + rng.nextDouble() * 0.88) * h;
      final lr = (18.0 + rng.nextDouble() * 52.0) * (w / 420.0);
      final col = colors[rng.nextInt(colors.length)];
      final op = 0.55 + rng.nextDouble() * 0.45;

      canvas.save();
      canvas.translate(lx, ly);
      canvas.rotate((rng.nextDouble() - 0.5) * pi);
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset.zero,
          width: lr * 3.8,
          height: lr * 0.75,
        ),
        Paint()..color = col.withOpacity(op),
      );
      canvas.drawLine(
        Offset(-lr * 1.8, 0),
        Offset(lr * 1.8, 0),
        Paint()
          ..color = const Color(0xFF2E7D32).withOpacity(0.3)
          ..strokeWidth = 1.4,
      );
      canvas.restore();
    }
  }

  void _drawAtmosphere(Canvas canvas, double w, double h) {
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * 0.5, h * 0.12),
        width: w * 1.2,
        height: h * 0.38,
      ),
      Paint()
        ..shader =
            RadialGradient(
              colors: [
                const Color(0xFF88FF44).withOpacity(0.055),
                Colors.transparent,
              ],
            ).createShader(
              Rect.fromCenter(
                center: Offset(w * 0.5, h * 0.12),
                width: w * 1.2,
                height: h * 0.38,
              ),
            ),
    );
  }

  void _drawVignette(Canvas canvas, double w, double h) {
    canvas.drawRect(
      Rect.fromLTWH(0, 0, w * 0.32, h),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [Colors.black.withOpacity(0.78), Colors.transparent],
        ).createShader(Rect.fromLTWH(0, 0, w * 0.32, h)),
    );
    canvas.drawRect(
      Rect.fromLTWH(w * 0.68, 0, w * 0.32, h),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.centerRight,
          end: Alignment.centerLeft,
          colors: [Colors.black.withOpacity(0.78), Colors.transparent],
        ).createShader(Rect.fromLTWH(w * 0.68, 0, w * 0.32, h)),
    );
  }

  @override
  bool shouldRepaint(_JungleBgPainter old) => old.godRayT != godRayT;
}

class _ForegroundLeavesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final rng = Random(55);
    final corners = [
      (ox: 0.0, oy: 0.0, flip: false, flipY: false),
      (ox: w, oy: 0.0, flip: true, flipY: false),
      (ox: 0.0, oy: h, flip: false, flipY: true),
      (ox: w, oy: h, flip: true, flipY: true),
    ];
    for (final c in corners) {
      _corner(canvas, c.ox, c.oy, w, rng, flipX: c.flip, flipY: c.flipY);
    }
  }

  void _corner(
    Canvas canvas,
    double ox,
    double oy,
    double w,
    Random rng, {
    required bool flipX,
    required bool flipY,
  }) {
    final colors = [
      const Color(0xFF1B5E20),
      const Color(0xFF2E7D32),
      const Color(0xFF33691E),
      const Color(0xFF1A4A10),
    ];
    for (int i = 0; i < 5; i++) {
      double ang = 0.1 + rng.nextDouble() * 0.85;
      if (flipX) ang = pi - ang;
      if (flipY) ang = -ang;

      final len = w * (0.28 + rng.nextDouble() * 0.24);
      final wid = len * (0.20 + rng.nextDouble() * 0.14);
      final col = colors[rng.nextInt(colors.length)];
      final op = 0.82 + rng.nextDouble() * 0.18;

      canvas.save();
      canvas.translate(ox, oy);
      canvas.rotate(ang);
      final path = Path()
        ..moveTo(0, 0)
        ..quadraticBezierTo(len * 0.33, -wid / 2, len, 0)
        ..quadraticBezierTo(len * 0.33, wid / 2, 0, 0)
        ..close();
      canvas.drawPath(
        path,
        Paint()
          ..shader = LinearGradient(
            colors: [
              col.withOpacity(op),
              col.withOpacity(op * 0.55),
              Color.lerp(
                col,
                const Color(0xFF4CAF50),
                0.3,
              )!.withOpacity(op * 0.4),
            ],
            stops: const [0.0, 0.6, 1.0],
          ).createShader(Rect.fromLTWH(0, -wid / 2, len, wid)),
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ForegroundLeavesPainter oldDelegate) => false;
}

class _PathPainter extends CustomPainter {
  final List<LevelData> levels;
  final double scale;
  final Offset Function(int) stoneCenter;

  const _PathPainter({
    required this.levels,
    required this.scale,
    required this.stoneCenter,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (levels.length < 2) return;
    final pts = List.generate(levels.length, (i) => stoneCenter(i) * scale);
    _stroke(canvas, pts, Colors.black.withOpacity(0.38), 50 * scale);
    _stroke(canvas, pts, const Color(0xFF3E2723), 42 * scale);
    _stroke(canvas, pts, const Color(0xFF6D4C41), 32 * scale);
    _stroke(canvas, pts, const Color(0xFF8D6E63), 18 * scale);
  }

  void _stroke(Canvas canvas, List<Offset> pts, Color color, double width) {
    canvas.drawPath(
      _curve(pts),
      Paint()
        ..color = color
        ..strokeWidth = width
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke,
    );
  }

  Path _curve(List<Offset> pts) {
    final path = Path()..moveTo(pts[0].dx, pts[0].dy);
    for (int i = 0; i < pts.length - 1; i++) {
      final bow = (i.isEven ? 1 : -1) * 28.0 * scale;
      final cp = Offset(
        (pts[i].dx + pts[i + 1].dx) / 2 + bow,
        (pts[i].dy + pts[i + 1].dy) / 2,
      );
      path.quadraticBezierTo(cp.dx, cp.dy, pts[i + 1].dx, pts[i + 1].dy);
    }
    return path;
  }

  @override
  bool shouldRepaint(_PathPainter oldDelegate) => false;
}

class _StoneNodeWidget extends StatelessWidget {
  final LevelData level;
  final bool isSelected;
  const _StoneNodeWidget({required this.level, required this.isSelected});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _StonePainter(level: level, isSelected: isSelected),
    );
  }
}

class _StonePainter extends CustomPainter {
  final LevelData level;
  final bool isSelected;
  const _StonePainter({required this.level, required this.isSelected});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final rx = size.width / 2;
    final ry = size.height / 2;
    final rect = Rect.fromCenter(
      center: Offset(cx, cy),
      width: rx * 2,
      height: ry * 2,
    );

    canvas.drawOval(rect, Paint()..color = const Color(0xFF37474F));
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx - 1, cy - 2),
        width: rx * 1.88,
        height: ry * 1.80,
      ),
      Paint()..color = const Color(0xFF546E7A),
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx - 2, cy - 4),
        width: rx * 1.70,
        height: ry * 1.50,
      ),
      Paint()..color = const Color(0xFF607D8B),
    );

    if (isSelected) {
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(cx, cy),
          width: rx * 2.14,
          height: ry * 2.14,
        ),
        Paint()
          ..color = const Color(0xFFFFE033)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3,
      );
    }

    final center = Offset(size.width / 2, size.height / 2 - 4);
    switch (level.state) {
      case LevelState.completed:
        _drawNumber(canvas, '${level.number}', center, size.height * 0.52);
        _drawStars(canvas, center.translate(0, 16), level.stars);
        break;
      case LevelState.unlocked:
        _drawNumber(canvas, '${level.number}', center, size.height * 0.52);
        break;
      case LevelState.locked:
        _drawDisabledNumber(
          canvas,
          '${level.number}',
          center,
          size.height * 0.46,
          size,
        );
        break;
    }
  }

  void _drawNumber(Canvas canvas, String text, Offset center, double fontSize) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontSize: fontSize,
          color: const Color.fromARGB(255, 11, 69, 26),
          fontWeight: FontWeight.w900,
          fontFamily: 'Georgia',
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(
      canvas,
      Offset(center.dx - tp.width / 2, center.dy - tp.height / 2),
    );
  }

  void _drawStars(Canvas canvas, Offset center, int stars) {
    final r = 8.0;
    for (int i = 0; i < 3; i++) {
      final c = Offset(center.dx - 20 + i * 20, center.dy);
      final path = Path();
      for (int p = 0; p < 10; p++) {
        final angle = (p * pi / 5) - (pi / 2);
        final radius = p.isEven ? r : r * 0.45;
        final point = Offset(
          c.dx + cos(angle) * radius,
          c.dy + sin(angle) * radius,
        );
        if (p == 0) {
          path.moveTo(point.dx, point.dy);
        } else {
          path.lineTo(point.dx, point.dy);
        }
      }
      path.close();

      if (i < stars) {
        canvas.drawPath(
          path,
          Paint()
            ..shader = RadialGradient(
              colors: const [
                Color(0xFFFFF59D),
                Color(0xFFFFD54F),
                Color(0xFFFFA000),
              ],
            ).createShader(Rect.fromCircle(center: c, radius: r)),
        );
        canvas.drawPath(
          path,
          Paint()
            ..color = const Color(0xFFE65100)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 0.8,
        );
      } else {
        canvas.drawPath(path, Paint()..color = Colors.white24);
      }
    }
  }

  void _drawDisabledNumber(
    Canvas canvas,
    String text,
    Offset center,
    double fontSize,
    Size size,
  ) {
    final blurPaint = Paint()
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.2);

    final shadow = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontSize: fontSize,
          color: Colors.black.withOpacity(0.35),
          fontWeight: FontWeight.w900,
          fontFamily: 'Georgia',
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    canvas.saveLayer(Rect.fromLTWH(0, 0, size.width, size.height), Paint());
    shadow.paint(
      canvas,
      Offset(
        center.dx - shadow.width / 2 + 1.2,
        center.dy - shadow.height / 2 + 1.8,
      ),
    );
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      blurPaint..blendMode = BlendMode.srcATop,
    );
    canvas.restore();

    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontSize: fontSize,
          color: const Color(0xFFB0BEC5).withOpacity(0.55),
          fontWeight: FontWeight.w900,
          fontFamily: 'Georgia',
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(
      canvas,
      Offset(center.dx - tp.width / 2, center.dy - tp.height / 2),
    );
  }

  @override
  bool shouldRepaint(_StonePainter oldDelegate) =>
      oldDelegate.isSelected != isSelected;
}
