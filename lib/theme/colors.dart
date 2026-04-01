import 'package:flutter/material.dart';

class JungleColors {
  // Greens
  static const Color darkJungle   = Color(0xFF0A1F08);
  static const Color deepJungle   = Color(0xFF1A2A10);
  static const Color jungleGreen  = Color(0xFF1A5212);
  static const Color midGreen     = Color(0xFF2D7E1A);
  static const Color lightGreen   = Color(0xFF5A9E3A);
  static const Color leafGreen    = Color(0xFFA8D86E);
  static const Color darkLeaf     = Color(0xFF2A6E15);
  static const Color deepLeaf     = Color(0xFF3D7225);

  // Yellows / Gold
  static const Color goldenYellow = Color(0xFFF5E642);
  static const Color amber        = Color(0xFFE8B800);
  static const Color coinGold     = Color(0xFFF5C842);

  // Browns
  static const Color trunkBrown   = Color(0xFF5C3D1E);

  // Sky
  static const Color skyBlue      = Color(0xFF87CEEB);
  static const Color lightSky     = Color(0xFFB8E4F0);

  // Danger
  static const Color danger       = Color(0xFFFF6060);
  static const Color dangerDark   = Color(0xFF2A0808);
  static const Color dangerDeep   = Color(0xFF120808);

  // Utility (ARGB literals so these are compile-time const for defaults, etc.)
  static const Color glassWhite        = Color(0x1AFFFFFF); // ~10% white
  static const Color glassBorder       = Color(0x26FFFFFF); // ~15% white
  static const Color glassBorderStrong = Color(0x33FFFFFF); // ~20% white
}

class JungleGradients {
  static const playButton = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFF5E642), Color(0xFFE8B800)],
  );
}
