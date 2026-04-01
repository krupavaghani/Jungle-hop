import 'package:flutter/material.dart';
import 'colors.dart';

class JungleTextStyles {
  // Fredoka One — display/game headings (bundled in pubspec.yaml)
  static TextStyle fredoka({
    double size = 24,
    Color color = JungleColors.goldenYellow,
    double? letterSpacing,
  }) =>
      TextStyle(
        fontFamily: 'FredokaOne',
        fontSize: size,
        color: color,
        letterSpacing: letterSpacing,
      );

  // Nunito — body / UI text (bundled in pubspec.yaml)
  static TextStyle nunito({
    double size = 14,
    Color color = Colors.white,
    FontWeight weight = FontWeight.w600,
  }) =>
      TextStyle(
        fontFamily: 'Nunito',
        fontSize: size,
        color: color,
        fontWeight: weight,
      );

  // Convenience shorthands
  static TextStyle get logoLarge => fredoka(size: 34);
  static TextStyle get screenTitle => fredoka(size: 24);
  static TextStyle get sectionTitle => fredoka(size: 20);
  static TextStyle get buttonLabel => fredoka(size: 16, color: const Color(0xFF1A2A10));
  static TextStyle get buttonLabelLight => fredoka(size: 16);
  static TextStyle get scoreText => fredoka(size: 18);
  static TextStyle get bigScore => fredoka(size: 42);
  static TextStyle get bodyText => nunito(size: 14);
  static TextStyle get caption => nunito(size: 12, color: Colors.white60, weight: FontWeight.w400);
  static TextStyle get itemName => fredoka(size: 14, color: Colors.white);
}
