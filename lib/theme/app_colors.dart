import 'package:flutter/material.dart';

class AppColors {
  const AppColors._();

  static const primary = Color(0xFFC9A84C);
  static const goldLight = Color(0xFFE8C96A);
  static const goldDark = Color(0xFF8A6520);
  static const petroleum = Color(0xFF111111);
  static const waveBlue = Color(0xFF1E7AC5);
  static const background = Color(0xFF0A0A0A);
  static const surface = Color(0xFF1A1A1A);
  static const surfaceAlt = Color(0xFF242424);
  static const textPrimary = Color(0xFFF0EAD6);
  static const textSecondary = Color(0xFFB8AA8A);
  static const border = Color(0xFF3A3A3A);
  static const warning = Color(0xFFF59E0B);
  static const danger = Color(0xFFDC2626);
  static const success = Color(0xFF16A34A);

  static const goldGradient = LinearGradient(
    colors: [goldLight, primary, goldDark, goldLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
