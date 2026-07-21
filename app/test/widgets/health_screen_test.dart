import 'dart:io';

import 'package:sanora/core/storage/local_store.dart';
import 'package:sanora/core/theme/app_theme.dart';
import 'package:sanora/domain/models/enums.dart';
import 'package:sanora/domain/models/metric_entry.dart';
import 'package:sanora/features/health/health_screen.dart';
import 'package:sanora/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

Widget _app(double textScale) => ProviderScope(
  child: MaterialApp(
    theme: AppTheme.light,
    localizationsDelegates: const [
      L.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: L.supportedLocales,
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(
        context,
      ).copyWith(textScaler: TextScaler.linear(textScale)),
      child: child!,
    ),
    home: const HealthScreen(),
  ),
);

void main() {
  late Directory tempDir;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('sanora_health_screen');
    Hive.init(tempDir.path);
    await LocalStore.open();
  });

  tearDownAll(() async {
    await Hive.close();
    await tempDir.delete(recursive: true);
  });

  // Hive writes are real file I/O, which never completes under the fake async
  // zone a widget test runs in — hence runAsync.
  Future<void> seed(WidgetTester tester, List<MetricEntry> entries) =>
      tester.runAsync(() async {
        await LocalStore.wipe();
        for (final e in entries) {
          await LocalStore.put(LocalStore.metricsBox, e.id, e.toJson());
        }
      });

  // A card whose content overflows raises during paint, failing the test.
  for (final (size, scale) in [
    (const Size(320, 800), 1.0),
    (const Size(360, 800), 1.0),
    (const Size(412, 900), 1.0),
    (const Size(360, 800), 1.6),
  ]) {
    testWidgets('metric cards fit at ${size.width}px @${scale}x', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await seed(tester, [
        MetricEntry(
          id: 'w',
          type: MetricType.waist,
          value: 86.5,
          recordedAt: DateTime(2026, 7, 20),
        ),
        MetricEntry(
          id: 's',
          type: MetricType.steps,
          value: 12500,
          recordedAt: DateTime.now(),
        ),
      ]);

      await tester.pumpWidget(_app(scale));
      await tester.pump(const Duration(seconds: 1));

      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('shows the latest reading and daily total for additive metrics', (
    tester,
  ) async {
    final today = DateTime.now();
    await seed(tester, [
      MetricEntry(
        id: 'w1',
        type: MetricType.weight,
        value: 80,
        recordedAt: today.subtract(const Duration(days: 2)),
      ),
      MetricEntry(
        id: 'w2',
        type: MetricType.weight,
        value: 79.5,
        recordedAt: today.subtract(const Duration(days: 1)),
      ),
      MetricEntry(
        id: 'h1',
        type: MetricType.water,
        value: 250,
        recordedAt: today,
      ),
      MetricEntry(
        id: 'h2',
        type: MetricType.water,
        value: 500,
        recordedAt: today,
      ),
      MetricEntry(
        id: 'h3',
        type: MetricType.water,
        value: 1000,
        recordedAt: today.subtract(const Duration(days: 3)),
      ),
    ]);

    await tester.pumpWidget(_app(1));
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('79.5 kg'), findsOneWidget);
    expect(find.text('750 ml'), findsOneWidget);
  });
}
