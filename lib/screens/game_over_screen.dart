import 'package:flutter/material.dart';
import '../utils/colors.dart';
import 'game_screen.dart';
import 'home_screen.dart';

class GameOverScreen extends StatefulWidget {
  final int score;
  final int bestScore;
  final int level;

  const GameOverScreen({
    super.key,
    required this.score,
    required this.bestScore,
    this.level = 1,
  });

  @override
  State<GameOverScreen> createState() => _GameOverScreenState();
}

class _GameOverScreenState extends State<GameOverScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _shakeController;
  late Animation<double> _shakeAnim;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _shakeAnim = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -8.0), weight: 25),
      TweenSequenceItem(tween: Tween(begin: -8.0, end: 8.0), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 8.0, end: 0.0), weight: 25),
    ]).animate(_shakeController);

    int repeatCount = 0;
    _shakeController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        repeatCount++;
        if (repeatCount < 3) {
          _shakeController.reset();
          _shakeController.forward();
        }
      }
    });
    _shakeController.forward();
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: JColors.gameOverGradient),
        child: Stack(
          children: [
            // Red glow in center
            Center(
              child: Container(
                width: 280,
                height: 280,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      Color(0x1FFF3C3C),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),

            // Main content
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Skull emoji with shake
                    AnimatedBuilder(
                      animation: _shakeAnim,
                      builder: (_, __) => Transform.translate(
                        offset: Offset(_shakeAnim.value, 0),
                        child: const Text('💀',
                            style: TextStyle(fontSize: 64)),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Game Over title
                    const Text(
                      'Game Over!',
                      style: TextStyle(
                        fontFamily: 'FredokaOne',
                        fontSize: 38,
                        color: JColors.danger,
                        shadows: [
                          Shadow(
                            color: Color(0x7FFF6060),
                            blurRadius: 20,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Score display
                    Text(
                      'Final Score',
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withOpacity(0.5),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${widget.score}',
                      style: const TextStyle(
                        fontFamily: 'FredokaOne',
                        fontSize: 56,
                        color: JColors.yellow,
                      ),
                    ),
                    Text(
                      'Best Score: ${widget.bestScore}',
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 13,
                        color: Colors.white.withOpacity(0.3),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Buttons
                    _GoButton(
                      label: '🔄  Play Again',
                      isPrimary: true,
                      onTap: () => Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                            builder: (_) => GameScreen(level: widget.level)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _GoButton(
                      label: '🏠  Back to Home',
                      isPrimary: false,
                      onTap: () => Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(
                            builder: (_) => const HomeScreen()),
                        (r) => false,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Share & Rate
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        GestureDetector(
                          child: const Text('📤',
                              style: TextStyle(fontSize: 28)),
                        ),
                        const SizedBox(width: 20),
                        GestureDetector(
                          child: const Text('⭐',
                              style: TextStyle(fontSize: 28)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GoButton extends StatelessWidget {
  final String label;
  final bool isPrimary;
  final VoidCallback onTap;

  const _GoButton({
    required this.label,
    required this.isPrimary,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          gradient: isPrimary
              ? const LinearGradient(
                  colors: [JColors.yellow, JColors.yellowDark],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isPrimary ? null : Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(16),
          border: isPrimary
              ? null
              : Border.all(color: Colors.white.withOpacity(0.12)),
          boxShadow: isPrimary
              ? [
                  BoxShadow(
                    color: JColors.yellow.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  )
                ]
              : null,
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontFamily: 'FredokaOne',
              fontSize: 20,
              color: isPrimary
                  ? const Color(0xFF1A2A10)
                  : Colors.white.withOpacity(0.6),
            ),
          ),
        ),
      ),
    );
  }
}
