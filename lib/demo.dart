import 'dart:math';
import 'package:flutter/material.dart';

// ═══════════════════════════════════════════════════════════════════════════
//  LEVEL MAP SCREEN  –  Jungle Jumpers
//  Vertical-scrolling level select with stone platforms on a lush jungle bg.
// ═══════════════════════════════════════════════════════════════════════════

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const LevelMapScreen(),
      theme: ThemeData(fontFamily: 'Georgia'),
    );
  }
}

// ── Level model ──────────────────────────────────────────────────────────────
enum LevelState { completed, unlocked, locked }

class LevelData {
  final int number;
  final LevelState state;
  final int stars;
  const LevelData(this.number, this.state, {this.stars = 0});
}

const _levels = [
  LevelData(1,  LevelState.completed, stars: 3),
  LevelData(2,  LevelState.completed, stars: 2),
  LevelData(3,  LevelState.completed, stars: 3),
  LevelData(4,  LevelState.completed, stars: 1),
  LevelData(5,  LevelState.completed, stars: 3),
  LevelData(6,  LevelState.unlocked),
  LevelData(7,  LevelState.locked),
  LevelData(8,  LevelState.locked),
  LevelData(9,  LevelState.locked),
  LevelData(10, LevelState.locked),
  LevelData(11, LevelState.locked),
  LevelData(12, LevelState.locked),
  LevelData(13, LevelState.locked),
  LevelData(14, LevelState.locked),
  LevelData(15, LevelState.locked),
];

const _colPattern = [0, 2, 1, 0, 2, 1, 0, 2, 1, 0, 2, 1, 0, 2, 1];

// ═══════════════════════════════════════════════════════════════════════════
//  LevelMapScreen
// ═══════════════════════════════════════════════════════════════════════════
class LevelMapScreen extends StatefulWidget {
  const LevelMapScreen({super.key});
  @override
  State<LevelMapScreen> createState() => _LevelMapScreenState();
}

class _LevelMapScreenState extends State<LevelMapScreen>
    with TickerProviderStateMixin {
  late final ScrollController _scroll;
  late final AnimationController _pulseCtrl;
  late final AnimationController _floatCtrl;
  late final AnimationController _godRayCtrl;
  late final Animation<double> _pulse;
  late final Animation<double> _float;
  late final Animation<double> _godRay;
  int? _selected;

  static const double _rowH    = 170.0;
  static const double _canvasW = 420.0;
  static const double _stoneW  = 130.0;
  static const double _stoneH  = 70.0;

  static double _xFor(int col) {
    switch (col) {
      case 0: return 40.0;
      case 1: return (_canvasW - _stoneW) / 2;
      case 2: return _canvasW - _stoneW - 40.0;
      default: return _canvasW / 2;
    }
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
        vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat(reverse: true);
    _pulse = Tween<double>(begin: 0.94, end: 1.06)
        .animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));

    _floatCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1600))
      ..repeat(reverse: true);
    _float = Tween<double>(begin: -5.0, end: 5.0)
        .animate(CurvedAnimation(parent: _floatCtrl, curve: Curves.easeInOut));

    _godRayCtrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 4))
      ..repeat(reverse: true);
    _godRay = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _godRayCtrl, curve: Curves.easeInOut));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final idx = _levels.indexWhere((l) => l.state == LevelState.unlocked);
      if (idx > 0) {
        final scale = MediaQuery.of(context).size.width / _canvasW;
        _scroll.animateTo(
          (idx * _rowH - 200.0).clamp(0.0, double.infinity) * scale,
          duration: const Duration(milliseconds: 700),
          curve: Curves.easeOut,
        );
      }
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

  @override
  Widget build(BuildContext context) {
    final screenW = MediaQuery.of(context).size.width;
    final scale   = screenW / _canvasW;
    final canvasH = _totalCanvasH;

    return Scaffold(
      backgroundColor: const Color(0xFF051505),
      body: Stack(children: [

        // ── 1. Fixed jungle background (never scrolls) ────────────────────
        Positioned.fill(
          child: AnimatedBuilder(
            animation: _godRay,
            builder: (_, __) => CustomPaint(
              painter: _JungleBgPainter(godRayT: _godRay.value),
            ),
          ),
        ),

        // ── 2. Scrollable map (path + stones) ─────────────────────────────
        SingleChildScrollView(
          controller: _scroll,
          physics: const BouncingScrollPhysics(),
          child: SizedBox(
            width: screenW,
            height: canvasH * scale,
            child: AnimatedBuilder(
              animation: Listenable.merge([_pulse, _float]),
              builder: (_, __) => CustomPaint(
                size: Size(screenW, canvasH * scale),
                painter: _PathPainter(
                  levels: _levels,
                  scale: scale,
                  stoneCenter: _stoneCenter,
                ),
                child: Stack(
                  children: List.generate(_levels.length, (i) =>
                      _buildStoneWidget(_levels[i], i, scale)),
                ),
              ),
            ),
          ),
        ),

        // ── 3. Foreground jungle leaves (fixed overlay, non-interactive) ──
        Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(painter: _ForegroundLeavesPainter()),
          ),
        ),

        // ── 4. Top HUD ────────────────────────────────────────────────────
        _buildTopBar(context),

        // ── 5. Bottom popup ───────────────────────────────────────────────
        if (_selected != null) _buildPopup(context),
      ]),
    );
  }

  // ── Stone node ─────────────────────────────────────────────────────────────
  Widget _buildStoneWidget(LevelData lvl, int idx, double scale) {
    final center = _stoneCenter(idx);
    final sw = _stoneW * scale;
    final sh = _stoneH * scale;
    final isUnlocked = lvl.state == LevelState.unlocked;

    return Positioned(
      left:  (center.dx - _stoneW / 2) * scale,
      top:   (center.dy - _stoneH / 2) * scale,
      width: sw, height: sh,
      child: GestureDetector(
        onTap: () {
          if (lvl.state != LevelState.locked) {
            setState(() => _selected = _selected == idx ? null : idx);
          }
        },
        child: AnimatedBuilder(
          animation: Listenable.merge([_pulse, _float]),
          builder: (_, __) {
            double dy = 0, sc = 1.0;
            if (isUnlocked) { dy = _float.value; sc = _pulse.value; }
            if (_selected == idx) sc *= 1.08;
            return Transform.translate(
              offset: Offset(0, dy),
              child: Transform.scale(
                scale: sc,
                child: _StoneNodeWidget(level: lvl, isSelected: _selected == idx),
              ),
            );
          },
        ),
      ),
    );
  }

  // ── Top bar ─────────────────────────────────────────────────────────────────
  Widget _buildTopBar(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    return Positioned(
      top: 0, left: 0, right: 0,
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
        child: Row(children: [
          _iconBtn('←'),
          const Spacer(),
          Column(children: [
            const Text('WORLD 1',
                style: TextStyle(
                    fontFamily: 'Georgia', fontSize: 22,
                    fontWeight: FontWeight.w900, color: Colors.white,
                    letterSpacing: 3.5,
                    shadows: [
                      Shadow(blurRadius: 16, color: Color(0xFF44FF44), offset: Offset(0, 0)),
                      Shadow(blurRadius: 4,  color: Colors.black,      offset: Offset(0, 2)),
                    ])),
            const SizedBox(height: 2),
            Text('5 / 15 complete',
                style: TextStyle(
                    fontSize: 12, color: Colors.white.withOpacity(0.7),
                    fontWeight: FontWeight.w600, letterSpacing: 0.5)),
          ]),
          const Spacer(),
          _iconBtn('⚙'),
        ]),
      ),
    );
  }

  Widget _iconBtn(String icon) => Container(
    width: 40, height: 40,
    decoration: BoxDecoration(
      color: Colors.black.withOpacity(0.45),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Colors.white.withOpacity(0.2), width: 1.5),
    ),
    child: Center(child: Text(icon,
        style: const TextStyle(fontSize: 17, color: Colors.white,
            fontWeight: FontWeight.bold))),
  );

  // ── Bottom popup ────────────────────────────────────────────────────────────
  Widget _buildPopup(BuildContext context) {
    final lvl    = _levels[_selected!];
    final bottom = MediaQuery.of(context).padding.bottom;
    return GestureDetector(
      onTap: () => setState(() => _selected = null),
      behavior: HitTestBehavior.opaque,
      child: Align(
        alignment: Alignment.bottomCenter,
        child: GestureDetector(
          onTap: () {},
          child: Container(
            margin: EdgeInsets.fromLTRB(16, 0, 16, bottom + 16),
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
            decoration: BoxDecoration(
              color: const Color(0xFF071507).withOpacity(0.97),
              borderRadius: BorderRadius.circular(26),
              border: Border.all(
                  color: const Color(0xFF4CAF50).withOpacity(0.45), width: 2),
              boxShadow: [
                BoxShadow(color: const Color(0xFF00CC44).withOpacity(0.12),
                    blurRadius: 24, spreadRadius: 2),
                BoxShadow(color: Colors.black.withOpacity(0.65),
                    blurRadius: 28, offset: const Offset(0, 8)),
              ],
            ),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              // Handle pill
              Container(width: 36, height: 4,
                  decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 16),
              Row(children: [
                // Red level badge
                Container(
                  width: 62, height: 62,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const RadialGradient(
                        colors: [Color(0xFFFF6B6B), Color(0xFFCC0000)]),
                    boxShadow: [BoxShadow(
                        color: const Color(0xFFFF2020).withOpacity(0.5),
                        blurRadius: 16, spreadRadius: 2)],
                  ),
                  child: Center(child: Text('${lvl.number}',
                      style: const TextStyle(fontSize: 26,
                          fontWeight: FontWeight.w900, color: Colors.white,
                          shadows: [Shadow(blurRadius: 4, color: Colors.black54)]))),
                ),
                const SizedBox(width: 14),
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Level ${lvl.number}',
                        style: const TextStyle(color: Colors.white,
                            fontSize: 19, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 3),
                    Text(lvl.state == LevelState.completed
                        ? 'Best: ${lvl.stars} ⭐  –  Replay?'
                        : 'New challenge awaits!',
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.55), fontSize: 12)),
                    const SizedBox(height: 7),
                    Row(children: List.generate(3, (i) => Padding(
                      padding: const EdgeInsets.only(right: 3),
                      child: Text('⭐', style: TextStyle(fontSize: 20,
                          color: i < lvl.stars
                              ? Colors.amber
                              : Colors.white.withOpacity(0.13))),
                    ))),
                  ],
                )),
              ]),
              const SizedBox(height: 16),
              // Yellow PLAY button matching reference
              GestureDetector(
                onTap: () {},
                child: Container(
                  width: double.infinity, height: 52,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                        colors: [Color(0xFFFFE033), Color(0xFFF5A800)],
                        begin: Alignment.topLeft, end: Alignment.bottomRight),
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(color: const Color(0xFFFFE033).withOpacity(0.4),
                          blurRadius: 16, offset: const Offset(0, 4)),
                      BoxShadow(color: Colors.black.withOpacity(0.35),
                          blurRadius: 8, offset: const Offset(0, 3)),
                    ],
                    border: Border.all(
                        color: const Color(0xFFFFFFAA).withOpacity(0.35), width: 1.5),
                  ),
                  child: const Center(child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('PLAY', style: TextStyle(
                          color: Color(0xFF3A1A00), fontSize: 20,
                          fontWeight: FontWeight.w900, letterSpacing: 3)),
                      SizedBox(width: 8),
                      Icon(Icons.play_arrow_rounded,
                          color: Color(0xFF3A1A00), size: 26),
                    ],
                  )),
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  Jungle Background Painter
//  Layers: deep sky → far tree silhouettes → god rays → mid foliage →
//          atmosphere haze → dark vignette edges
// ═══════════════════════════════════════════════════════════════════════════
class _JungleBgPainter extends CustomPainter {
  final double godRayT;
  const _JungleBgPainter({required this.godRayT});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // ── Layer 1: Deep gradient sky/canopy ─────────────────────────────────
    canvas.drawRect(Offset.zero & size, Paint()
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
      ).createShader(Rect.fromLTWH(0, 0, w, h)));

    // ── Layer 2: Far background tree silhouettes ──────────────────────────
    _drawFarTrees(canvas, w, h);

    // ── Layer 3: Animated god rays ────────────────────────────────────────
    _drawGodRays(canvas, w, h);

    // ── Layer 4: Mid-ground leaf clusters ────────────────────────────────
    _drawMidLeaves(canvas, w, h);

    // ── Layer 5: Atmospheric glow ─────────────────────────────────────────
    _drawAtmosphere(canvas, w, h);

    // ── Layer 6: Dark vignette frame ──────────────────────────────────────
    _drawVignette(canvas, w, h);
  }

  // ── Far tree silhouettes ──────────────────────────────────────────────────
  void _drawFarTrees(Canvas canvas, double w, double h) {
    final rng = Random(42);
    final layerDefs = [
      (color: const Color(0xFF081408), yBase: 0.72, cnt: 9,  maxH: 0.48, wf: 0.17),
      (color: const Color(0xFF0C1E0C), yBase: 0.78, cnt: 11, maxH: 0.40, wf: 0.21),
      (color: const Color(0xFF112611), yBase: 0.84, cnt: 13, maxH: 0.33, wf: 0.25),
    ];

    for (final layer in layerDefs) {
      final paint = Paint()..color = layer.color;
      for (int i = 0; i < layer.cnt; i++) {
        final x     = rng.nextDouble() * w;
        final treeH = (0.25 + rng.nextDouble() * 0.75) * layer.maxH * h;
        final treeW = (0.5  + rng.nextDouble() * 0.5)  * layer.wf   * w;
        final baseY = layer.yBase * h;

        // Trunk
        canvas.drawRect(
          Rect.fromLTWH(x - treeW * 0.06, baseY - treeH * 0.32,
              treeW * 0.12, treeH * 0.34),
          paint,
        );
        // Layered canopy ovals
        for (int t = 0; t < 3; t++) {
          canvas.drawOval(
            Rect.fromCenter(
              center: Offset(x, baseY - treeH * (0.32 + t * 0.26)),
              width:  treeW * (1.0 - t * 0.15),
              height: treeW * (0.6 - t * 0.05),
            ),
            paint,
          );
        }
      }
    }
  }

  // ── Animated god rays ─────────────────────────────────────────────────────
  void _drawGodRays(Canvas canvas, double w, double h) {
    final rays = [
      (xf: 0.22, ang: 10.0,  wf: 0.13),
      (xf: 0.50, ang: -7.0,  wf: 0.20),
      (xf: 0.78, ang: 14.0,  wf: 0.11),
    ];

    for (int ri = 0; ri < rays.length; ri++) {
      final r = rays[ri];
      final phase   = (godRayT + ri * 0.34) % 1.0;
      final opacity = 0.035 + phase * 0.045;
      final startX  = r.xf * w;
      final endX    = startX + h * tan(r.ang * pi / 180.0);
      final rw      = r.wf * w;

      final path = Path()
        ..moveTo(startX - rw * 0.5, 0)
        ..lineTo(startX + rw * 0.5, 0)
        ..lineTo(endX   + rw * 1.6, h)
        ..lineTo(endX   - rw * 0.4, h)
        ..close();

      canvas.drawPath(path, Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter, end: Alignment.bottomCenter,
          colors: [
            const Color(0xFFAAFF66).withOpacity(opacity),
            const Color(0xFF66FF22).withOpacity(opacity * 0.35),
            Colors.transparent,
          ],
          stops: const [0.0, 0.38, 1.0],
        ).createShader(Rect.fromLTWH(0, 0, w, h)));
    }
  }

  // ── Mid-ground leaf clusters ──────────────────────────────────────────────
  void _drawMidLeaves(Canvas canvas, double w, double h) {
    final rng = Random(77);
    final colors = [
      const Color(0xFF143A14), const Color(0xFF1A4A18),
      const Color(0xFF1E5220), const Color(0xFF122E12),
    ];

    for (int i = 0; i < 22; i++) {
      final lx  = rng.nextDouble() * w;
      final ly  = (0.08 + rng.nextDouble() * 0.88) * h;
      final lr  = (18.0 + rng.nextDouble() * 52.0) * (w / 420.0);
      final col = colors[rng.nextInt(colors.length)];
      final op  = 0.55 + rng.nextDouble() * 0.45;

      canvas.save();
      canvas.translate(lx, ly);
      canvas.rotate((rng.nextDouble() - 0.5) * pi);

      // Elongated tropical leaf ellipse
      canvas.drawOval(
        Rect.fromCenter(center: Offset.zero, width: lr * 3.8, height: lr * 0.75),
        Paint()..color = col.withOpacity(op),
      );
      // Mid-rib
      canvas.drawLine(Offset(-lr * 1.8, 0), Offset(lr * 1.8, 0),
          Paint()..color = const Color(0xFF2E7D32).withOpacity(0.3)
            ..strokeWidth = 1.4);
      canvas.restore();
    }

    // Side hanging leaves
    _drawSideLeaves(canvas, w, h, rng);
  }

  void _drawSideLeaves(Canvas canvas, double w, double h, Random rng) {
    // Left side
    for (int i = 0; i < 7; i++) {
      _leaf(canvas,
        ox: -w * 0.04, oy: (0.04 + i * 0.155) * h,
        len: w * (0.26 + rng.nextDouble() * 0.16),
        angle: -0.25 + rng.nextDouble() * 0.75,
        color: const Color(0xFF1B5E20),
        op: 0.72 + rng.nextDouble() * 0.28,
      );
    }
    // Right side
    for (int i = 0; i < 7; i++) {
      _leaf(canvas,
        ox: w * 1.04, oy: (0.07 + i * 0.145) * h,
        len: w * (0.24 + rng.nextDouble() * 0.18),
        angle: pi + 0.25 - rng.nextDouble() * 0.75,
        color: const Color(0xFF2E7D32),
        op: 0.70 + rng.nextDouble() * 0.30,
      );
    }
  }

  void _leaf(Canvas canvas, {
    required double ox, required double oy,
    required double len, required double angle,
    required Color color, required double op,
  }) {
    canvas.save();
    canvas.translate(ox, oy);
    canvas.rotate(angle);

    final wid = len * 0.28;
    final path = Path()
      ..moveTo(0, 0)
      ..quadraticBezierTo(len * 0.32, -wid / 2, len, 0)
      ..quadraticBezierTo(len * 0.32,  wid / 2, 0, 0)
      ..close();

    canvas.drawPath(path, Paint()
      ..shader = LinearGradient(
        colors: [
          color.withOpacity(op),
          color.withOpacity(op * 0.62),
          Color.lerp(color, const Color(0xFF4CAF50), 0.28)!.withOpacity(op * 0.5),
        ],
        stops: const [0.0, 0.55, 1.0],
      ).createShader(Rect.fromLTWH(0, -wid / 2, len, wid)));

    // Mid rib
    canvas.drawLine(Offset.zero, Offset(len, 0),
        Paint()..color = const Color(0xFF388E3C).withOpacity(0.28)
          ..strokeWidth = 1.6);
    // Side veins
    for (int v = 1; v <= 4; v++) {
      final vx = len * v / 5.5;
      canvas.drawLine(Offset(vx, 0),
          Offset(vx + len * 0.07, -len * 0.10 * sin(v * pi / 5)),
          Paint()..color = const Color(0xFF4CAF50).withOpacity(0.18)
            ..strokeWidth = 0.9);
    }
    canvas.restore();
  }

  // ── Atmosphere ────────────────────────────────────────────────────────────
  void _drawAtmosphere(Canvas canvas, double w, double h) {
    // Soft green ambient glow — upper centre (sun through canopy)
    canvas.drawOval(
      Rect.fromCenter(center: Offset(w * 0.5, h * 0.12),
          width: w * 1.2, height: h * 0.38),
      Paint()..shader = RadialGradient(
        colors: [
          const Color(0xFF88FF44).withOpacity(0.055),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCenter(
          center: Offset(w * 0.5, h * 0.12), width: w * 1.2, height: h * 0.38)),
    );

    // Cool teal mist mid-ground
    canvas.drawRect(Rect.fromLTWH(0, h * 0.38, w, h * 0.28),
      Paint()..shader = LinearGradient(
        colors: [Colors.transparent,
          const Color(0xFF003322).withOpacity(0.10), Colors.transparent],
        stops: const [0, 0.5, 1],
      ).createShader(Rect.fromLTWH(0, h * 0.38, w, h * 0.28)));
  }

  // ── Dark vignette frame ───────────────────────────────────────────────────
  void _drawVignette(Canvas canvas, double w, double h) {
    // Left
    canvas.drawRect(Rect.fromLTWH(0, 0, w * 0.32, h),
        Paint()..shader = LinearGradient(
          begin: Alignment.centerLeft, end: Alignment.centerRight,
          colors: [Colors.black.withOpacity(0.78), Colors.transparent],
        ).createShader(Rect.fromLTWH(0, 0, w * 0.32, h)));
    // Right
    canvas.drawRect(Rect.fromLTWH(w * 0.68, 0, w * 0.32, h),
        Paint()..shader = LinearGradient(
          begin: Alignment.centerRight, end: Alignment.centerLeft,
          colors: [Colors.black.withOpacity(0.78), Colors.transparent],
        ).createShader(Rect.fromLTWH(w * 0.68, 0, w * 0.32, h)));
    // Top
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h * 0.22),
        Paint()..shader = LinearGradient(
          begin: Alignment.topCenter, end: Alignment.bottomCenter,
          colors: [Colors.black.withOpacity(0.80), Colors.transparent],
        ).createShader(Rect.fromLTWH(0, 0, w, h * 0.22)));
    // Bottom
    canvas.drawRect(Rect.fromLTWH(0, h * 0.78, w, h * 0.22),
        Paint()..shader = LinearGradient(
          begin: Alignment.bottomCenter, end: Alignment.topCenter,
          colors: [Colors.black.withOpacity(0.65), Colors.transparent],
        ).createShader(Rect.fromLTWH(0, h * 0.78, w, h * 0.22)));
  }

  @override
  bool shouldRepaint(_JungleBgPainter old) => old.godRayT != godRayT;
}

// ═══════════════════════════════════════════════════════════════════════════
//  Foreground large leaves  — fixed overlay framing all 4 corners
// ═══════════════════════════════════════════════════════════════════════════
class _ForegroundLeavesPainter extends CustomPainter {
  const _ForegroundLeavesPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final rng = Random(55);

    final corners = [
      (ox: 0.0,  oy: 0.0,  flip: false, flipY: false),
      (ox: w,    oy: 0.0,  flip: true,  flipY: false),
      (ox: 0.0,  oy: h,    flip: false, flipY: true),
      (ox: w,    oy: h,    flip: true,  flipY: true),
    ];

    for (final c in corners) {
      _corner(canvas, c.ox, c.oy, w, rng, flipX: c.flip, flipY: c.flipY);
    }
  }

  void _corner(Canvas canvas, double ox, double oy, double w, Random rng,
      {required bool flipX, required bool flipY}) {
    final colors = [
      const Color(0xFF1B5E20), const Color(0xFF2E7D32),
      const Color(0xFF33691E), const Color(0xFF1A4A10),
    ];
    for (int i = 0; i < 5; i++) {
      double ang = 0.1 + rng.nextDouble() * 0.85;
      if (flipX) ang = pi - ang;
      if (flipY) ang = -ang;

      final len = w * (0.28 + rng.nextDouble() * 0.24);
      final wid = len * (0.20 + rng.nextDouble() * 0.14);
      final col = colors[rng.nextInt(colors.length)];
      final op  = 0.82 + rng.nextDouble() * 0.18;

      canvas.save();
      canvas.translate(ox, oy);
      canvas.rotate(ang);

      final path = Path()
        ..moveTo(0, 0)
        ..quadraticBezierTo(len * 0.33, -wid / 2, len, 0)
        ..quadraticBezierTo(len * 0.33,  wid / 2, 0, 0)
        ..close();

      canvas.drawPath(path, Paint()
        ..shader = LinearGradient(
          colors: [col.withOpacity(op), col.withOpacity(op * 0.55),
            Color.lerp(col, const Color(0xFF4CAF50), 0.3)!.withOpacity(op * 0.4)],
          stops: const [0.0, 0.6, 1.0],
        ).createShader(Rect.fromLTWH(0, -wid / 2, len, wid)));

      canvas.drawLine(Offset.zero, Offset(len, 0),
          Paint()..color = const Color(0xFF4CAF50).withOpacity(0.25)
            ..strokeWidth = 1.5);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ForegroundLeavesPainter old) => false;
}

// ═══════════════════════════════════════════════════════════════════════════
//  Path Painter — dirt winding path + grass tufts + pebbles
// ═══════════════════════════════════════════════════════════════════════════
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
    _drawGrassTufts(canvas, size);
    _drawPath(canvas);
    _drawPebbles(canvas, size);
  }

  void _drawGrassTufts(Canvas canvas, Size size) {
    final rng = Random(13);
    final p = Paint()
      ..strokeWidth = scale * 1.7
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    for (int i = 0; i < 60; i++) {
      final cx = rng.nextDouble() * size.width;
      final cy = rng.nextDouble() * size.height;
      final bh = (7 + rng.nextDouble() * 5) * scale;
      p.color = (rng.nextBool()
          ? const Color(0xFF2E7D32) : const Color(0xFF1B5E20)).withOpacity(0.5);
      for (int b = -1; b <= 1; b++) {
        canvas.drawLine(
          Offset(cx + b * scale * 3, cy),
          Offset(cx + b * scale * 4.5, cy - bh), p);
      }
    }
  }

  void _drawPebbles(Canvas canvas, Size size) {
    final rng = Random(99);
    for (int i = 0; i < 22; i++) {
      final rx = rng.nextDouble() * size.width;
      final ry = rng.nextDouble() * size.height;
      final rr = (3 + rng.nextDouble() * 4.5) * scale;
      canvas.drawOval(
        Rect.fromCenter(center: Offset(rx, ry), width: rr * 2, height: rr * 1.3),
        Paint()..color = const Color(0xFF78909C).withOpacity(0.55),
      );
      canvas.drawOval(
        Rect.fromCenter(center: Offset(rx - rr * 0.2, ry - rr * 0.22),
            width: rr * 0.75, height: rr * 0.45),
        Paint()..color = Colors.white.withOpacity(0.2),
      );
    }
  }

  void _drawPath(Canvas canvas) {
    if (levels.length < 2) return;
    final pts = List.generate(levels.length, (i) => stoneCenter(i) * scale);
    _stroke(canvas, pts, Colors.black.withOpacity(0.38), 50 * scale);
    _stroke(canvas, pts, const Color(0xFF3E2723), 42 * scale);
    _stroke(canvas, pts, const Color(0xFF6D4C41), 32 * scale);
    _stroke(canvas, pts, const Color(0xFF8D6E63), 18 * scale);
    _tracks(canvas, pts);
  }

  void _stroke(Canvas canvas, List<Offset> pts, Color color, double width) {
    canvas.drawPath(_curve(pts), Paint()
      ..color = color ..strokeWidth = width
      ..strokeCap = StrokeCap.round ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke);
  }

  void _tracks(Canvas canvas, List<Offset> pts) {
    final p = Paint()
      ..color = const Color(0xFF4E342E).withOpacity(0.4)
      ..strokeWidth = scale * 1.3 ..strokeCap = StrokeCap.butt
      ..style = PaintingStyle.stroke;
    final metrics = _curve(pts).computeMetrics().toList();
    for (final off in [-7.0 * scale, 7.0 * scale]) {
      for (final m in metrics) {
        double d = 0; bool draw = true;
        while (d < m.length) {
          const seg = 10.0;
          if (draw) {
            final t1 = m.getTangentForOffset(d);
            final t2 = m.getTangentForOffset((d + seg * scale).clamp(0, m.length));
            if (t1 != null && t2 != null) {
              final perp = Offset(-t1.vector.dy, t1.vector.dx);
              canvas.drawLine(t1.position + perp * off, t2.position + perp * off, p);
            }
          }
          d += seg * scale * (draw ? 1 : 0.5); draw = !draw;
        }
      }
    }
  }

  Path _curve(List<Offset> pts) {
    final path = Path()..moveTo(pts[0].dx, pts[0].dy);
    for (int i = 0; i < pts.length - 1; i++) {
      final bow = (i.isEven ? 1 : -1) * 28.0 * scale;
      final cp  = Offset((pts[i].dx + pts[i+1].dx) / 2 + bow,
                         (pts[i].dy + pts[i+1].dy) / 2);
      path.quadraticBezierTo(cp.dx, cp.dy, pts[i+1].dx, pts[i+1].dy);
    }
    return path;
  }

  @override
  bool shouldRepaint(_PathPainter old) => false;
}

// ═══════════════════════════════════════════════════════════════════════════
//  Stone Node
// ═══════════════════════════════════════════════════════════════════════════
class _StoneNodeWidget extends StatelessWidget {
  final LevelData level;
  final bool isSelected;
  const _StoneNodeWidget({required this.level, required this.isSelected});

  @override
  Widget build(BuildContext context) => CustomPaint(
    painter: _StonePainter(level: level, isSelected: isSelected),
  );
}

class _StonePainter extends CustomPainter {
  final LevelData level;
  final bool isSelected;
  const _StonePainter({required this.level, required this.isSelected});

  @override
  void paint(Canvas canvas, Size size) {
    _stone(canvas, size);
    _overlay(canvas, size);
  }

  void _stone(Canvas canvas, Size size) {
    final cx = size.width / 2, cy = size.height / 2;
    final rx = size.width / 2, ry = size.height / 2;
    final rect = Rect.fromCenter(center: Offset(cx, cy), width: rx*2, height: ry*2);

    // Drop shadow
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx+3, cy+7), width: rx*2, height: ry*1.4),
      Paint()..color = Colors.black.withOpacity(0.5));

    canvas.drawOval(rect, Paint()..color = const Color(0xFF37474F));
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx-1, cy-2), width: rx*1.88, height: ry*1.80),
      Paint()..color = const Color(0xFF546E7A));
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx-2, cy-4), width: rx*1.70, height: ry*1.50),
      Paint()..color = const Color(0xFF607D8B));
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx - rx*0.28, cy - ry*0.36), width: rx*0.82, height: ry*0.52),
      Paint()..color = Colors.white.withOpacity(0.16));

    final ck = Paint()..color = const Color(0xFF263238).withOpacity(0.5)
      ..strokeWidth = 1.1 ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(cx-rx*0.3, cy-ry*0.1), Offset(cx+rx*0.1, cy+ry*0.25), ck);
    canvas.drawLine(Offset(cx+rx*0.15, cy-ry*0.3), Offset(cx+rx*0.35, cy+ry*0.05), ck);

    canvas.drawOval(rect, Paint()
      ..color = const Color(0xFF1C313A) ..style = PaintingStyle.stroke ..strokeWidth = 1.5);

    _moss(canvas, size);

    if (isSelected) {
      canvas.drawOval(
        Rect.fromCenter(center: Offset(cx, cy), width: rx*2.14, height: ry*2.14),
        Paint()..color = const Color(0xFFFFE033)
          ..style = PaintingStyle.stroke ..strokeWidth = 3);
    }
  }

  void _moss(Canvas canvas, Size size) {
    final rng = Random(level.number * 7);
    final p = Paint()..color = const Color(0xFF4CAF50).withOpacity(0.55);
    for (int i = 0; i < 5; i++) {
      final a = rng.nextDouble() * pi * 2;
      final d = size.width / 2 * (0.70 + rng.nextDouble() * 0.14);
      canvas.drawCircle(
        Offset(size.width/2 + cos(a)*d, size.height/2 + sin(a)*d*0.52),
        3 + rng.nextDouble()*3.5, p);
    }
    final bp = Paint()..color = const Color(0xFF66BB6A)
      ..strokeWidth = 1.7 ..strokeCap = StrokeCap.round ..style = PaintingStyle.stroke;
    for (int i = 0; i < 6; i++) {
      final bx = size.width*(0.2 + i*0.13);
      final by = size.height*0.84;
      canvas.drawLine(Offset(bx,by), Offset(bx+(i.isEven?-2:2), by-7), bp);
    }
  }

  void _overlay(Canvas canvas, Size size) {
    final cx = size.width/2, cy = size.height/2 - 4;
    switch (level.state) {
      case LevelState.completed:
        _num(canvas, Offset(cx, cy-14), size);
        _stars(canvas, Offset(cx, cy+13), size);
        break;
      case LevelState.unlocked:
        _num(canvas, Offset(cx, cy), size);
        break;
      case LevelState.locked:
        _lock(canvas, Offset(cx, cy), size);
        break;
    }
  }

  // 3D red number
  void _num(Canvas canvas, Offset c, Size size) {
    final fs = size.height * 0.52;
    _t(canvas, '${level.number}', c + const Offset(2.5, 3.5), fs, const Color(0xFF7B0000));
    _t(canvas, '${level.number}', c + const Offset(1.0, 1.5), fs, const Color(0xFFB71C1C));
    _t(canvas, '${level.number}', c,                           fs, const Color(0xFFEF3A3A));
    _t(canvas, '${level.number}', c - const Offset(1, 1),     fs, const Color(0xFFFF8A80).withOpacity(0.48));
  }

  void _t(Canvas canvas, String s, Offset c, double fs, Color col) {
    final tp = TextPainter(
      text: TextSpan(text: s, style: TextStyle(
          fontSize: fs, color: col, fontWeight: FontWeight.w900, fontFamily: 'Georgia')),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(c.dx - tp.width/2, c.dy - tp.height/2));
  }

  void _stars(Canvas canvas, Offset c, Size size) {
    final r = size.width * 0.085;
    final sp = r * 2.5;
    for (int i = 0; i < 3; i++) {
      _starShape(canvas, Offset(c.dx - sp + i*sp, c.dy), r, i < level.stars);
    }
  }

  void _starShape(Canvas canvas, Offset c, double r, bool filled) {
    final path = Path();
    for (int i = 0; i < 10; i++) {
      final a = (i * pi / 5) - pi / 2;
      final rad = i.isEven ? r : r*0.42;
      final pt = Offset(c.dx + cos(a)*rad, c.dy + sin(a)*rad);
      if (i==0) path.moveTo(pt.dx, pt.dy); else path.lineTo(pt.dx, pt.dy);
    }
    path.close();
    if (filled) {
      canvas.drawPath(path.shift(const Offset(1.2, 1.2)),
          Paint()..color = Colors.black.withOpacity(0.28));
      canvas.drawPath(path, Paint()
        ..shader = RadialGradient(colors: const [
          Color(0xFFFFF176), Color(0xFFFFD700), Color(0xFFF57F00)])
            .createShader(Rect.fromCircle(center: c, radius: r)));
      canvas.drawPath(path, Paint()
        ..color = const Color(0xFFF57F00) ..style = PaintingStyle.stroke
        ..strokeWidth = r*0.18);
    } else {
      canvas.drawPath(path, Paint()..color = const Color(0xFF546E7A).withOpacity(0.35));
    }
  }

  // Blue padlock
  void _lock(Canvas canvas, Offset c, Size size) {
    final s = size.height * 0.072;
    final br = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(c.dx, c.dy + s*0.8), width: s*3.2, height: s*2.6),
      Radius.circular(s*0.5));
    canvas.drawRRect(RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(c.dx+2, c.dy+s*0.9+3), width: s*3.2, height: s*2.6),
        Radius.circular(s*0.5)),
        Paint()..color = Colors.black.withOpacity(0.4));
    canvas.drawRRect(br, Paint()
      ..shader = LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: const [Color(0xFF64B5F6), Color(0xFF1565C0), Color(0xFF0D47A1)])
          .createShader(br.outerRect));
    canvas.drawRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(br.left+s*0.3, br.top+s*0.25, s*1.0, s*0.55),
        Radius.circular(s*0.25)),
        Paint()..color = Colors.white.withOpacity(0.24));
    canvas.drawCircle(Offset(c.dx, c.dy+s*0.6), s*0.5,
        Paint()..color = Colors.black.withOpacity(0.5));
    canvas.drawRect(
        Rect.fromCenter(center: Offset(c.dx, c.dy+s*0.95), width: s*0.28, height: s*0.55),
        Paint()..color = Colors.black.withOpacity(0.5));

    final shBase = Paint()..strokeWidth = s*0.7
      ..style = PaintingStyle.stroke ..strokeCap = StrokeCap.round;
    canvas.drawArc(Rect.fromCenter(center: Offset(c.dx+1.5, c.dy-s*1.1+2),
        width: s*2.4, height: s*2.4), pi, pi, false,
        shBase..color = Colors.black.withOpacity(0.35));
    canvas.drawArc(Rect.fromCenter(center: Offset(c.dx, c.dy-s*1.1),
        width: s*2.4, height: s*2.4), pi, pi, false,
        shBase..color = const Color(0xFF1565C0));
    canvas.drawArc(Rect.fromCenter(center: Offset(c.dx-s*0.15, c.dy-s*1.1),
        width: s*2.0, height: s*2.0), pi, pi*0.5, false,
        Paint()..color = const Color(0xFF90CAF9).withOpacity(0.5)
          ..strokeWidth = s*0.22 ..style = PaintingStyle.stroke ..strokeCap = StrokeCap.round);
  }

  @override
  bool shouldRepaint(_StonePainter o) => o.isSelected != isSelected;
}