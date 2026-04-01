import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../theme/text_styles.dart';

// ─── Glass Card ───────────────────────────────────────────────────────────────
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final Color borderColor;
  final double borderRadius;

  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.borderColor = JungleColors.glassBorder,
    this.borderRadius = 16,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: JungleColors.glassWhite,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: child,
    );
  }
}

// ─── Primary Gradient Button ──────────────────────────────────────────────────
class JungleButton extends StatefulWidget {
  final String label;
  final String? icon;
  final VoidCallback onTap;
  final bool isPrimary;
  final bool isDanger;
  final double fontSize;

  const JungleButton({
    super.key,
    required this.label,
    required this.onTap,
    this.icon,
    this.isPrimary = false,
    this.isDanger = false,
    this.fontSize = 15,
  });

  @override
  State<JungleButton> createState() => _JungleButtonState();
}

class _JungleButtonState extends State<JungleButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 100));
    _scale = Tween(begin: 1.0, end: 0.95).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) {
        _ctrl.reverse();
        widget.onTap();
      },
      onTapCancel: () => _ctrl.reverse(),
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 13),
          decoration: BoxDecoration(
            gradient: widget.isPrimary ? JungleGradients.playButton : null,
            color: widget.isPrimary
                ? null
                : widget.isDanger
                    ? const Color(0x26FF6060)
                    : const Color(0x1AFFFFFF),
            borderRadius: BorderRadius.circular(14),
            border: widget.isPrimary
                ? null
                : Border.all(
                    color: widget.isDanger
                        ? const Color(0x40FF6060)
                        : JungleColors.glassBorderStrong,
                    width: 1,
                  ),
            boxShadow: widget.isPrimary
                ? [
                    BoxShadow(
                      color: JungleColors.goldenYellow.withAlpha(80),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    )
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.icon != null) ...[
                Text(widget.icon!, style: const TextStyle(fontSize: 18)),
                const SizedBox(width: 8),
              ],
              Text(
                widget.label,
                style: widget.isPrimary
                    ? JungleTextStyles.fredoka(
                        size: widget.fontSize, color: const Color(0xFF1A2A10))
                    : JungleTextStyles.fredoka(
                        size: widget.fontSize,
                        color: widget.isDanger
                            ? JungleColors.danger
                            : Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Jungle Tree Painter ──────────────────────────────────────────────────────
class JungleTreePainter extends CustomPainter {
  final double opacity;
  JungleTreePainter({this.opacity = 1.0});

  void _drawTree(Canvas canvas, double x, double groundY, double scale,
      Color crownColor, Color trunkColor) {
    final trunkPaint = Paint()..color = trunkColor.withAlpha((opacity * 255).toInt());
    final crownPaint = Paint()..color = crownColor.withAlpha((opacity * 255).toInt());
    final crown2Paint = Paint()
      ..color = crownColor
          .withGreen((crownColor.g * 1.15).clamp(0, 255).toInt())
          .withAlpha((opacity * 200).toInt());

    // Trunk
    final trunkRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
          center: Offset(x, groundY - 12 * scale),
          width: 7 * scale,
          height: 24 * scale),
      const Radius.circular(3),
    );
    canvas.drawRRect(trunkRect, trunkPaint);

    // Main crown
    final crownPath = Path()
      ..addOval(Rect.fromCenter(
          center: Offset(x, groundY - 44 * scale),
          width: 32 * scale,
          height: 38 * scale));
    canvas.drawPath(crownPath, crownPaint);

    // Upper crown highlight
    final crown2Path = Path()
      ..addOval(Rect.fromCenter(
          center: Offset(x, groundY - 54 * scale),
          width: 22 * scale,
          height: 26 * scale));
    canvas.drawPath(crown2Path, crown2Paint);
  }

  @override
  void paint(Canvas canvas, Size size) {
    _drawTree(canvas, size.width * 0.12, size.height, 1.1,
        const Color(0xFF2A6E15), JungleColors.trunkBrown);
    _drawTree(canvas, size.width * 0.35, size.height, 0.75,
        const Color(0xFF2A5E10), JungleColors.trunkBrown);
    _drawTree(canvas, size.width * 0.65, size.height, 0.9,
        const Color(0xFF358A1A), JungleColors.trunkBrown);
    _drawTree(canvas, size.width * 0.88, size.height, 0.7,
        const Color(0xFF2A5E10), JungleColors.trunkBrown);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─── Bouncing Emoji Widget ────────────────────────────────────────────────────
class BouncingEmoji extends StatefulWidget {
  final String emoji;
  final double size;
  final Duration duration;

  const BouncingEmoji({
    super.key,
    required this.emoji,
    this.size = 48,
    this.duration = const Duration(milliseconds: 1200),
  });

  @override
  State<BouncingEmoji> createState() => _BouncingEmojiState();
}

class _BouncingEmojiState extends State<BouncingEmoji>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: widget.duration)
      ..repeat(reverse: true);
    _anim = Tween(begin: 0.0, end: -10.0).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Transform.translate(
        offset: Offset(0, _anim.value),
        child: Text(widget.emoji,
            style: TextStyle(fontSize: widget.size)),
      ),
    );
  }
}

// ─── Coin Display Badge ───────────────────────────────────────────────────────
class CoinBadge extends StatelessWidget {
  final int amount;
  const CoinBadge({super.key, required this.amount});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: JungleColors.goldenYellow.withAlpha(30),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: JungleColors.goldenYellow.withAlpha(60), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🪙', style: TextStyle(fontSize: 14)),
          const SizedBox(width: 4),
          Text('$amount',
              style: JungleTextStyles.fredoka(size: 14, color: JungleColors.goldenYellow)),
        ],
      ),
    );
  }
}

// ─── Star Rating ──────────────────────────────────────────────────────────────
class StarRating extends StatelessWidget {
  final int count;
  final int max;
  const StarRating({super.key, required this.count, this.max = 5});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(
        max,
        (i) => Text(
          i < count ? '⭐' : '☆',
          style: TextStyle(
              fontSize: 11,
              color: i < count ? JungleColors.coinGold : Colors.white24),
        ),
      ),
    );
  }
}
