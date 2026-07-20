import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

abstract final class AppTypography {
  static TextTheme textTheme(Color ink, Color inkMuted) {
    final display = GoogleFonts.manropeTextTheme();
    final body = GoogleFonts.interTextTheme();
    return TextTheme(
      displayLarge: display.displayLarge!.copyWith(
        fontSize: 44,
        fontWeight: FontWeight.w800,
        letterSpacing: -1.2,
        color: ink,
      ),
      displayMedium: display.displayMedium!.copyWith(
        fontSize: 34,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.8,
        color: ink,
      ),
      displaySmall: display.displaySmall!.copyWith(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
        color: ink,
      ),
      headlineMedium: display.headlineMedium!.copyWith(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.4,
        color: ink,
      ),
      headlineSmall: display.headlineSmall!.copyWith(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
        color: ink,
      ),
      titleLarge: display.titleLarge!.copyWith(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.2,
        color: ink,
      ),
      titleMedium: body.titleMedium!.copyWith(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: ink,
      ),
      titleSmall: body.titleSmall!.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: ink,
      ),
      bodyLarge: body.bodyLarge!.copyWith(fontSize: 16, height: 1.5, color: ink),
      bodyMedium: body.bodyMedium!.copyWith(fontSize: 14, height: 1.5, color: ink),
      bodySmall: body.bodySmall!.copyWith(
        fontSize: 12,
        height: 1.4,
        color: inkMuted,
      ),
      labelLarge: body.labelLarge!.copyWith(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
        color: ink,
      ),
      labelMedium: body.labelMedium!.copyWith(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.3,
        color: inkMuted,
      ),
      labelSmall: body.labelSmall!.copyWith(
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
