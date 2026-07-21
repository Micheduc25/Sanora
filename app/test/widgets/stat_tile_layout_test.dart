import 'package:sanora/core/theme/app_colors.dart';
import 'package:sanora/core/theme/app_theme.dart';
import 'package:sanora/core/widgets/stat_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// The dashboard grid sizes these by [StatTile.preferredExtent], so the tile
/// has to fit that height at every width and text scale it ships at — a tile
/// that outgrows it overflows on the home screen, which is what a
/// `childAspectRatio` used to cause on narrow Android phones.
void main() {
  // Two columns inside 20pt page padding and 12pt of gutter.
  double tileWidth(double screen) => (screen - 40 - 12) / 2;

  for (final screen in [320.0, 360.0, 392.0, 412.0]) {
    for (final scale in [1.0, 1.3, 1.6]) {
      testWidgets('fits ${screen}px wide @${scale}x', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.light,
            home: MediaQuery(
              data: MediaQueryData(textScaler: TextScaler.linear(scale)),
              child: Scaffold(
                body: Center(
                  child: SizedBox(
                    width: tileWidth(screen),
                    height: StatTile.preferredExtent * scale,
                    child: const StatTile(
                      icon: Icons.local_fire_department_rounded,
                      color: AppColors.calories,
                      value: '12 500 kcal',
                      // The French label is the longest one shipped.
                      label: 'sur 2 400 kcal aujourd\'hui',
                      progress: 0.75,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pump();

        expect(tester.takeException(), isNull);
      });
    }
  }
}
