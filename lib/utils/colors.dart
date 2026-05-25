import 'package:flutter/material.dart';

class JColors {
  // Greens
  static const darkBg = Color(0xFF0A2208);
  static const midGreen = Color(0xFF1A5212);
  static const brightGreen = Color(0xFF2D7E1A);
  static const lightGreen = Color(0xFFA8D86E);
  static const treeGreen = Color(0xFF2A6E15);
  static const treeLightGreen = Color(0xFF358A1A);

  // Yellows
  static const yellow = Color(0xFFF5E642);
  static const yellowDark = Color(0xFFE8B800);
  static const coin = Color(0xFFF5C842);

  // Sky
  static const skyBlue = Color(0xFF87CEEB);
  static const skyLight = Color(0xFFB8E4F0);

  // Ground
  static const groundTop = Color(0xFF5A9E3A);
  static const groundMid = Color(0xFF3D7225);
  static const groundDark = Color(0xFF2D5C1A);

  // Trunk
  static const trunk = Color(0xFF5C3D1E);

  // UI overlays
  static const glassWhite = Color(0x1AFFFFFF);
  static const glassBorder = Color(0x26FFFFFF);
   static const Color glassBorderStrong = Color(0x33FFFFFF);

  // Red
  static const danger = Color(0xFFFF6060);
  static const dangerGlow = Color(0x1FFF3C3C);

  static const playButtonGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFF5E642), Color(0xFFE8B800)],
  );
}
