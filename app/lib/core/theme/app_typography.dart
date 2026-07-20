import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Bundled type families (declared in pubspec) so the app never fetches
/// fonts at runtime — essential for an offline-first product. Manrope is the
/// display face, Inter carries body and UI text.
abstract final class AppTypography {
  static const _display = 'Manrope';
  static const _body = 'Inter';

  static TextTheme textTheme(Color ink, Color inkMuted) {
    return TextTheme(
      displayLarge: TextStyle(
        fontFamily: _display,
        fontSize: 44,
        fontWeight: FontWeight.w800,
        letterSpacing: -1.2,
        height: 1.05,
        color: ink,
      ),
      displayMedium: TextStyle(
        fontFamily: _display,
        fontSize: 34,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.8,
        height: 1.1,
        color: ink,
      ),
      displaySmall: TextStyle(
        fontFamily: _display,
        fontSize: 28,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
        color: ink,
      ),
      headlineMedium: TextStyle(
        fontFamily: _display,
        fontSize: 24,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.4,
        color: ink,
      ),
      headlineSmall: TextStyle(
        fontFamily: _display,
        fontSize: 20,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
        color: ink,
      ),
      titleLarge: TextStyle(
        fontFamily: _display,
        fontSize: 18,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.2,
        color: ink,
      ),
      titleMedium: TextStyle(
        fontFamily: _body,
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: ink,
      ),
      titleSmall: TextStyle(
        fontFamily: _body,
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: ink,
      ),
      bodyLarge: TextStyle(
        fontFamily: _body,
        fontSize: 16,
        height: 1.5,
        color: ink,
      ),
      bodyMedium: TextStyle(
        fontFamily: _body,
        fontSize: 14,
        height: 1.5,
        color: ink,
      ),
      bodySmall: TextStyle(
        fontFamily: _body,
        fontSize: 12,
        height: 1.4,
        color: inkMuted,
      ),
      labelLarge: TextStyle(
        fontFamily: _body,
        fontSize: 15,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
        color: ink,
      ),
      labelMedium: TextStyle(
        fontFamily: _body,
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.3,
        color: inkMuted,
      ),
      labelSmall: TextStyle(
        fontFamily: _body,
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.4,
        color: inkMuted,
      ),
    );
  }

  static TextTheme get light => textTheme(AppColors.ink, AppColors.inkMuted);
  static TextTheme get dark =>
      textTheme(AppColors.inkDark, AppColors.inkMutedDark);
}
