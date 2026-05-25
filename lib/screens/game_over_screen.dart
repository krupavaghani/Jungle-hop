import 'dart:async';
import 'dart:math';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/game_sound_service.dart';
import 'game_screen.dart';
import 'home_screen.dart';

class GameOverScreen extends StatefulWidget {
  final int score;
  final int level;

  const GameOverScreen({
    super.key,
    required this.score,
    this.level = 1,
  });

  @override
  State<GameOverScreen> createState() => _GameOverScreenState();
}

class _GameOverScreenState extends State<GameOverScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _shakeController;
  late Animation<double> _shakeAnim;
  AudioPlayer? _gameOverPlayer;

  @override
  void initState() {
    super.initState();
    _playGameOverSound();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _shakeAnim = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -6.0), weight: 25),
      TweenSequenceItem(tween: Tween(begin: -6.0, end: 6.0), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 6.0, end: 0.0), weight: 25),
    ]).animate(_shakeController);

    var repeatCount = 0;
    _shakeController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        repeatCount++;
        if (repeatCount < 2) {
          _shakeController.reset();
          _shakeController.forward();
        }
      }
    });
    _shakeController.forward();
  }

  Future<void> _playGameOverSound() async {
    final prefs = await SharedPreferences.getInstance();
    if (!(prefs.getBool(GameSoundService.kSfxPrefsKey) ?? true)) return;
    if (!mounted) return;
    final p = AudioPlayer();
    _gameOverPlayer = p;
    await p.setReleaseMode(ReleaseMode.release);
    try {
      await p.play(AssetSource('audio/gameOver.mp3'));
    } catch (_) {}
  }

  @override
  void dispose() {
    _gameOverPlayer?.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final contentWidth = min(size.width * 0.9, 380.0);

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/images/splash-bg.png',
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.15),
                  Colors.black.withValues(alpha: 0.45),
                ],
              ),
            ),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedBuilder(
                      animation: _shakeAnim,
                      builder: (_, child) => Transform.translate(
                        offset: Offset(_shakeAnim.value, 0),
                        child: child,
                      ),
                      child: Image.asset(
                        'assets/images/gameOver.png',
                        width: contentWidth,
                        fit: BoxFit.contain,
                      ),
                    ),
                    SizedBox(height: size.height * 0.02),
                    _GameOverScorePanel(
                      width: contentWidth * 0.8,
                      score: widget.score,
                    ),
                    SizedBox(height: size.height * 0.028),
                    _GameOverActionButton(
                      width: contentWidth * 0.92,
                      label: 'PLAY AGAIN',
                      icon: Icons.play_arrow_rounded,
                      iconBoxColor: const Color(0xFF5C3D1E),
                      gradient: const LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color(0xFFFFE566),
                          Color(0xFFFFB82B),
                          Color(0xFFE87800),
                        ],
                      ),
                      borderColor: const Color(0xFF7A4A08),
                      textColor: const Color(0xFF3D2814),
                      onTap: () => Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder: (_) => GameScreen(level: widget.level),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _GameOverActionButton(
                      width: contentWidth * 0.92,
                      label: 'BACK TO HOME',
                      icon: Icons.home_rounded,
                      iconBoxColor: const Color(0xFF1B4A10),
                      gradient: const LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color(0xFF7AE85A),
                          Color(0xFF3D9E28),
                          Color(0xFF2A6E18),
                        ],
                      ),
                      borderColor: const Color(0xFF1B4A10),
                      textColor: Colors.white,
                      onTap: () => Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (_) => const HomeScreen()),
                        (r) => false,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GameOverScorePanel extends StatelessWidget {
  final double width;
  final int score;

  const _GameOverScorePanel({
    required this.width,
    required this.score,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Image.asset(
            'assets/images/popUp-bg.png',
            width: width,
            fit: BoxFit.fill,
          ),
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: width * 0.12,
              vertical: width * 0.1,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'FINAL SCORE',
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                    letterSpacing: 1.4,
                    color: Color(0xFF4A3219),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '$score',
                  style: const TextStyle(
                    fontFamily: 'FredokaOne',
                    fontSize: 52,
                    height: 1,
                    color: Color(0xFF3D2814),
                    shadows: [
                      Shadow(
                        color: Color(0x33000000),
                        offset: Offset(0, 2),
                        blurRadius: 2,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GameOverActionButton extends StatelessWidget {
  final double width;
  final String label;
  final IconData icon;
  final Color iconBoxColor;
  final Gradient gradient;
  final Color borderColor;
  final Color textColor;
  final VoidCallback onTap;

  const _GameOverActionButton({
    required this.width,
    required this.label,
    required this.icon,
    required this.iconBoxColor,
    required this.gradient,
    required this.borderColor,
    required this.textColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(32),
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF8B5E34), Color(0xFF4A3219)],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.35),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: borderColor, width: 2.5),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: iconBoxColor,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: Colors.black.withValues(alpha: 0.2),
                    width: 1.5,
                  ),
                ),
                child: Icon(icon, color: Colors.white, size: 26),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'FredokaOne',
                    fontSize: 16,
                    letterSpacing: 0.5,
                    color: textColor,
                    shadows: [
                      if (textColor == Colors.white)
                        Shadow(
                          color: Colors.black.withValues(alpha: 0.35),
                          blurRadius: 2,
                          offset: const Offset(0, 1),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 52),
            ],
          ),
        ),
      ),
    );
  }
}
