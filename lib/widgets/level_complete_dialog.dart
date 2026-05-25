import 'dart:math';

import 'package:flutter/material.dart';

class LevelCompleteDialog extends StatelessWidget {
  final int level;
  final int score, coins;
  final VoidCallback onNext, onHome;
  const LevelCompleteDialog({
    required this.level,
    required this.score,
    required this.coins,
    required this.onNext,
    required this.onHome,
  });

  @override
  Widget build(BuildContext context) {
    final panelWidth = min(MediaQuery.sizeOf(context).width * 0.88, 360.0);
    final trophyHeight = panelWidth * 0.38;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
      child: SizedBox(
        width: panelWidth,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Transform.translate(
              offset: Offset(0, -trophyHeight * 0.22),
              child: Container(
                width: panelWidth,
                decoration: const BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage('assets/images/level-completed-bg.png'),
                    fit: BoxFit.fill,
                  ),
                ),
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    panelWidth * 0.09,
                    panelWidth * 0.10,
                    panelWidth * 0.09,
                    panelWidth * 0.1,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset(
                        'assets/images/level-complete-trophy.png',
                        height: trophyHeight,
                        fit: BoxFit.cover,
                      ),
                      SizedBox(height: panelWidth * 0.03),
                      Image.asset(
                        'assets/images/levelCompleted-title.png',
                        width: panelWidth * 0.88,
                        fit: BoxFit.contain,
                      ),
                      SizedBox(height: panelWidth * 0.03),
                      LevelCompleteBanner(level: level),
                      SizedBox(height: panelWidth * 0.05),
                      LevelCompleteStatsBoard(
                        width: panelWidth * 0.82,
                        score: score,
                        coins: coins,
                      ),
                      SizedBox(height: panelWidth * 0.06),
                      Row(
                        children: [
                          Expanded(
                            child: LevelCompleteActionButton(
                              label: 'NEXT LEVEL',
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
                              onTap: onNext,
                            ),
                          ),
                          SizedBox(width: panelWidth * 0.04),
                          Expanded(
                            child: LevelCompleteActionButton(
                              label: 'HOME',
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
                              onTap: onHome,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class LevelCompleteBanner extends StatelessWidget {
  final int level;

  const LevelCompleteBanner({required this.level});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF6BCB3A), Color(0xFF3A8A22), Color(0xFF2A6018)],
        ),
        border: Border.all(color: Color(0xFF1A4010), width: 2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x55000000),
            offset: Offset(0, 3),
            blurRadius: 5,
          ),
        ],
      ),
      child: Text(
        'Level $level Completed',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontFamily: 'Nunito',
          fontWeight: FontWeight.w800,
          fontSize: 15,
          color: Colors.white,
          letterSpacing: 0.4,
          shadows: [
            Shadow(
              color: Colors.black.withValues(alpha: 0.45),
              offset: const Offset(0, 1),
              blurRadius: 2,
            ),
          ],
        ),
      ),
    );
  }
}

class LevelCompleteStatsBoard extends StatelessWidget {
  final double width;
  final int score;
  final int coins;

  const LevelCompleteStatsBoard({
    required this.width,
    required this.score,
    required this.coins,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Image.asset(
            'assets/images/level-complete-score-bg.png',
            width: width,
            fit: BoxFit.fill,
          ),
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: width * 0.1,
              vertical: width * 0.08,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                LevelCompleteStatRow(
                  iconAsset: 'assets/images/reward-Icon.png',
                  label: 'Score',
                  value: '$score',
                ),
                SizedBox(height: width * 0.04),
                LevelCompleteStatRow(
                  iconAsset: 'assets/images/coin.png',
                  label: 'Coins',
                  value: '$coins',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class LevelCompleteStatRow extends StatelessWidget {
  final String iconAsset;
  final String label;
  final String value;

  const LevelCompleteStatRow({
    required this.iconAsset,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Image.asset(iconAsset, width: 26, height: 26, fit: BoxFit.contain),
        const SizedBox(width: 10),
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Nunito',
            fontWeight: FontWeight.w700,
            fontSize: 15,
            color: Colors.white,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(
            fontFamily: 'FredokaOne',
            fontSize: 20,
            color: Color(0xFFFFE566),
            shadows: [
              Shadow(
                color: Color(0x99000000),
                offset: Offset(0, 1),
                blurRadius: 2,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class LevelCompleteActionButton extends StatelessWidget {
  final String label;
  final Gradient gradient;
  final Color borderColor;
  final VoidCallback onTap;

  const LevelCompleteActionButton({
    required this.label,
    required this.gradient,
    required this.borderColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: borderColor, width: 2.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.32),
              blurRadius: 6,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: Text(
            label,
            style: const TextStyle(
              fontFamily: 'FredokaOne',
              fontSize: 14,
              color: Colors.white,
              letterSpacing: 0.6,
              shadows: [
                Shadow(
                  color: Color(0x88000000),
                  blurRadius: 3,
                  offset: Offset(0, 1),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
