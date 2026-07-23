import 'dart:io';

import 'package:sanora/domain/models/enums.dart';
import 'package:sanora/domain/models/workout.dart';
import 'package:sanora/features/workouts/workout_detail_screen.dart';
import 'package:sanora/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

Widget _app(Workout workout) => ProviderScope(
  child: MaterialApp(
    localizationsDelegates: const [
      L.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: L.supportedLocales,
    home: WorkoutDetailScreen(workout: workout),
  ),
);

Workout _workout(List<WorkoutExercise> exercises) => Workout(
  id: 'w1',
  name: 'Test workout',
  category: WorkoutCategory.home,
  durationMinutes: 20,
  estimatedCalories: 140,
  exercises: exercises,
  createdAt: DateTime(2026, 7, 23),
);

void main() {
  testWidgets('shows the illustration for a tagged exercise', (tester) async {
    await tester.pumpWidget(
      _app(
        _workout(const [
          WorkoutExercise(
            name: 'Bodyweight squat',
            instructions: 'Sit back and down.',
            illustration: ExerciseIllustration.squat,
          ),
        ]),
      ),
    );
    final svg = tester.widget<SvgPicture>(find.byType(SvgPicture));
    expect(
      (svg.bytesLoader as SvgAssetLoader).assetName,
      'assets/illustrations/exercises/squat.svg',
    );
    expect(find.text('Watch tutorial'), findsOneWidget);
  });

  testWidgets('an untagged exercise renders without an illustration', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        _workout(const [
          WorkoutExercise(name: 'Mystery move', instructions: 'Just move.'),
        ]),
      ),
    );
    expect(find.text('Mystery move'), findsOneWidget);
    expect(find.byType(SvgPicture), findsNothing);
  });

  test('an unknown illustration slug from a newer backend parses to null', () {
    final exercise = WorkoutExercise.fromJson(const {
      'name': 'Pistol squat',
      'instructions': 'One leg.',
      'illustration': 'handstand',
    });
    expect(exercise.illustration, isNull);
  });

  test('every illustration has a bundled asset', () {
    for (final illustration in ExerciseIllustration.values) {
      expect(
        File(illustration.asset).existsSync(),
        isTrue,
        reason: '${illustration.asset} is missing',
      );
    }
  });
}
