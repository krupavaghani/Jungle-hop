import 'package:flutter/material.dart';
import '../utils/colors.dart';

class PauseScreen extends StatelessWidget {
  final int score;

  const PauseScreen({super.key, required this.score});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black.withOpacity(0.85),
      body: Stack(
        children: [
          // Subtle jungle hint at bottom
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Opacity(
              opacity: 0.15,
              child: Container(
                height: MediaQuery.of(context).size.height * 0.5,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFF1A5212), Color(0xFF2D7E1A)],
                  ),
                ),
              ),
            ),
          ),

          // Content
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Title
                  const Text(
                    '⏸  Paused',
                    style: TextStyle(
                      fontFamily: 'FredokaOne',
                      fontSize: 36,
                      color: JColors.yellow,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Score display
                  RichText(
                    text: TextSpan(
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.5),
                        fontWeight: FontWeight.w600,
                      ),
                      children: [
                        const TextSpan(text: 'Current Score  '),
                        TextSpan(
                          text: '$score',
                          style: const TextStyle(
                            fontFamily: 'FredokaOne',
                            fontSize: 22,
                            color: JColors.yellow,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Button card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.07),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.12),
                      ),
                    ),
                    child: Column(
                      children: [
                        _PauseButton(
                          label: '▶  Resume',
                          style: _PauseButtonStyle.resume,
                          onTap: () =>
                              Navigator.pop(context, 'resume'),
                        ),
                        const SizedBox(height: 12),
                        _PauseButton(
                          label: '🔄  Restart',
                          style: _PauseButtonStyle.restart,
                          onTap: () =>
                              Navigator.pop(context, 'restart'),
                        ),
                        const SizedBox(height: 12),
                        _PauseButton(
                          label: '🏠  Exit to Home',
                          style: _PauseButtonStyle.exit,
                          onTap: () =>
                              Navigator.pop(context, 'home'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  Text(
                    'Tap resume to continue',
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.2),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

enum _PauseButtonStyle { resume, restart, exit }

class _PauseButton extends StatelessWidget {
  final String label;
  final _PauseButtonStyle style;
  final VoidCallback onTap;

  const _PauseButton({
    required this.label,
    required this.style,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Widget child = GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          gradient: style == _PauseButtonStyle.resume
              ? const LinearGradient(
                  colors: [JColors.yellow, JColors.yellowDark],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: style == _PauseButtonStyle.resume
              ? null
              : (style == _PauseButtonStyle.restart
                  ? JColors.lightGreen.withOpacity(0.2)
                  : Colors.red.withOpacity(0.15)),
          borderRadius: BorderRadius.circular(14),
          border: style != _PauseButtonStyle.resume
              ? Border.all(
                  color: style == _PauseButtonStyle.restart
                      ? JColors.lightGreen.withOpacity(0.3)
                      : Colors.red.withOpacity(0.3),
                )
              : null,
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontFamily: 'FredokaOne',
              fontSize: 18,
              color: style == _PauseButtonStyle.resume
                  ? const Color(0xFF1A2A10)
                  : (style == _PauseButtonStyle.restart
                      ? JColors.lightGreen
                      : const Color(0xFFFF8080)),
            ),
          ),
        ),
      ),
    );
    return child;
  }
}
