import 'package:bodi/core/theme/app_colors.dart';
import 'package:bodi/core/theme/app_theme.dart';
import 'package:bodi/core/widgets/empty_state.dart';
import 'package:bodi/core/widgets/progress_ring.dart';
import 'package:bodi/core/widgets/stat_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Golden tests pin the visual output of the design-system widgets in both
/// themes. Regenerate with `flutter test --update-goldens` when the design
/// intentionally changes.
Widget _frame(Widget child, ThemeData theme) {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: theme,
    home: Scaffold(
      body: Center(
        child: Padding(padding: const EdgeInsets.all(24), child: child),
      ),
    ),
  );
}

void main() {
  for (final (label, theme) in [
    ('light', AppTheme.light),
    ('dark', AppTheme.dark),
  ]) {
    testWidgets('StatTile golden ($label)', (tester) async {
      await tester.pumpWidget(_frame(
        const SizedBox(
          width: 170,
          height: 150,
          child: StatTile(
            icon: Icons.directions_walk_rounded,
            color: AppColors.steps,
            value: '7,500',
            label: 'of 10K steps',
            progress: 0.75,
          ),
        ),
        theme,
      ));
      await tester.pumpAndSettle();
      await expectLater(
        find.byType(StatTile),
        matchesGoldenFile('goldens/stat_tile_$label.png'),
      );
    });

    testWidgets('ProgressRing golden ($label)', (tester) async {
      await tester.pumpWidget(_frame(
        const ProgressRing(
          progress: 0.72,
          size: 120,
          strokeWidth: 12,
          child: Text('72'),
        ),
        theme,
      ));
      await tester.pumpAndSettle();
      await expectLater(
        find.byType(ProgressRing),
        matchesGoldenFile('goldens/progress_ring_$label.png'),
      );
    });

    testWidgets('EmptyState golden ($label)', (tester) async {
      await tester.pumpWidget(_frame(
        const SizedBox(
          width: 360,
          height: 420,
          child: EmptyState(
            icon: Icons.restaurant_rounded,
            title: 'What did you eat today?',
            message:
                'Snap a photo, describe it, or search the food database.',
            actionLabel: 'Log your first meal',
          ),
        ),
        theme,
      ));
      await tester.pumpAndSettle();
      await expectLater(
        find.byType(EmptyState),
        matchesGoldenFile('goldens/empty_state_$label.png'),
      );
    });
  }
}
