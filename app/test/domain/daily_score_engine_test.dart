import 'package:bodi/domain/health/daily_score_engine.dart';
import 'package:flutter_test/flutter_test.dart';

DailyScoreInput input({
  int steps = 0,
  double waterMl = 0,
  double proteinG = 0,
  double calories = 0,
  double? sleepHours,
  int habitsCompleted = 0,
  int habitsTotal = 0,
}) =>
    DailyScoreInput(
      steps: steps,
      stepGoal: 10000,
      waterMl: waterMl,
      waterGoalMl: 2500,
      proteinG: proteinG,
      proteinGoalG: 120,
      calories: calories,
      calorieTarget: 2000,
      sleepHours: sleepHours,
      sleepGoalHours: 8,
      habitsCompleted: habitsCompleted,
      habitsTotal: habitsTotal,
    );

void main() {
  test('a perfect day scores 100', () {
    final score = DailyScoreEngine.compute(input(
      steps: 10000,
      waterMl: 2500,
      proteinG: 120,
      calories: 2000,
      sleepHours: 8,
      habitsCompleted: 3,
      habitsTotal: 3,
    ));
    expect(score.total, 100);
  });

  test('an empty day scores low but not zero (neutral sleep/habits)', () {
    final score = DailyScoreEngine.compute(input());
    expect(score.total, lessThan(30));
    expect(score.total, greaterThan(0));
  });

  test('overshooting steps does not overshoot the score', () {
    final capped = DailyScoreEngine.compute(input(steps: 25000));
    final exact = DailyScoreEngine.compute(input(steps: 10000));
    expect(capped.movement, exact.movement);
  });

  test('calories score highest near target from either side', () {
    final under = DailyScoreEngine.compute(input(calories: 1200));
    final near = DailyScoreEngine.compute(input(calories: 1950));
    final over = DailyScoreEngine.compute(input(calories: 2900));
    expect(near.nutrition, greaterThan(under.nutrition));
    expect(near.nutrition, greaterThan(over.nutrition));
  });

  test('no calories logged scores zero on the calorie component', () {
    final score = DailyScoreEngine.compute(input(proteinG: 120));
    expect(score.nutrition, 0.5);
  });

  test('unlogged sleep gets a neutral 0.7', () {
    expect(DailyScoreEngine.compute(input()).sleep, 0.7);
  });

  test('total is always within 0–100', () {
    final maxed = DailyScoreEngine.compute(input(
      steps: 99999,
      waterMl: 99999,
      proteinG: 999,
      calories: 2000,
      sleepHours: 8,
      habitsCompleted: 10,
      habitsTotal: 3,
    ));
    expect(maxed.total, inInclusiveRange(0, 100));
  });
}
