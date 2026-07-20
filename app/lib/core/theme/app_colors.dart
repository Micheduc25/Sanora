import 'package:flutter/material.dart';

/// Bodi palette — calm, organic, premium.
abstract final class AppColors {
  // Brand
  static const vital = Color(0xFF10A56D);
  static const vitalDark = Color(0xFF0B7A50);
  static const vitalLight = Color(0xFF5CD6A6);
  static const mint = Color(0xFFE3F6EE);

  // Accents
  static const sun = Color(0xFFF6B73C);
  static const coral = Color(0xFFF0655A);
  static const ocean = Color(0xFF3D7BF4);
  static const lavender = Color(0xFF8B6FF0);
  static const rose = Color(0xFFEB6BA5);

  // Neutrals — light
  static const canvas = Color(0xFFF7F8F6);
  static const surface = Color(0xFFFFFFFF);
  static const ink = Color(0xFF17211C);
  static const inkMuted = Color(0xFF5C6B63);
  static const line = Color(0xFFE6EAE7);

  // Neutrals — dark
  static const canvasDark = Color(0xFF0E1512);
  static const surfaceDark = Color(0xFF18211C);
  static const surfaceDarkRaised = Color(0xFF1F2A24);
  static const inkDark = Color(0xFFECF2EE);
  static const inkMutedDark = Color(0xFF93A399);
  static const lineDark = Color(0xFF2A362F);

  // Semantic
  static const success = vital;
  static const warning = sun;
  static const danger = coral;

  /// Nutrient / metric identity colors used across charts and tiles.
  static const protein = ocean;
  static const carbs = sun;
  static const fat = lavender;
  static const water = Color(0xFF3FB6E8);
  static const steps = vital;
  static const sleep = lavender;
  static const heart = coral;
  static const calories = Color(0xFFF08B3C);
}
