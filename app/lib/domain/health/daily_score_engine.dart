import 'dart:math' as math;

/// Computes the daily health score (0–100) shown on the dashboard.
///
/// Weighting favors movement and nutrition, and calories score highest when
/// close to target from either side — undereating is not rewarded.
class DailyScoreInput {
  const DailyScoreInput({
    this.steps = 0,
    required this.stepGoal,
    this.waterMl = 0,
    required this.waterGoalMl,
    this.proteinG = 0,
    required this.proteinGoalG,
    this.calories = 0,
    required this.calorieTarget,
    this.sleepHours,
    required this.sleepGoalHours,
    this.habitsCompleted = 0,
    this.habitsTotal = 0,
  });

  final int steps;
  final int stepGoal;
  final double waterMl;
  final double waterGoalMl;
  final double proteinG;
  final double proteinGoalG;
  final double calories;
  final double calorieTarget;
  final double? sleepHours;
  final double sleepGoalHours;
  final int habitsCompleted;
  final int habitsTotal;
}

class DailyScore {
  const DailyScore({
    required this.total,
    required this.movement,
    required this.nutrition,
    required this.hydration,
    required this.sleep,
    required this.habits,
  });

  final int total;
  final double movement;
  final double nutrition;
  final double hydration;
  final double sleep;
  final double habits;
}

abstract final class DailyScoreEngine {
  static const movementWeight = 30.0;
  static const nutritionWeight = 30.0;
  static const hydrationWeight = 10.0;
  static const sleepWeight = 20.0;
  static const habitsWeight = 10.0;

  static DailyScore compute(DailyScoreInput i) {
    final movement = _ratio(i.steps.toDouble(), i.stepGoal.toDouble());
    final hydration = _ratio(i.waterMl, i.waterGoalMl);

    final proteinScore = _ratio(i.proteinG, i.proteinGoalG);
    final calorieScore = i.calories <= 0
        ? 0.0
        : _closeness(i.calories, i.calorieTarget, tolerance: 0.25);
    final nutrition = proteinScore * 0.5 + calorieScore * 0.5;

    final sleep = i.sleepHours == null
        ? 0.7
        : _closeness(i.sleepHours!, i.sleepGoalHours, tolerance: 0.2);

    final habits = i.habitsTotal == 0 ? 0.7 : i.habitsCompleted / i.habitsTotal;

    final total =
        movement * movementWeight +
        nutrition * nutritionWeight +
        hydration * hydrationWeight +
        sleep * sleepWeight +
        habits.clamp(0.0, 1.0) * habitsWeight;

    return DailyScore(
      total: total.round().clamp(0, 100),
      movement: movement,
      nutrition: nutrition,
      hydration: hydration,
      sleep: sleep,
      habits: habits.clamp(0.0, 1.0),
    );
  }

  static double _ratio(double value, double goal) =>
      goal <= 0 ? 0 : math.min(value / goal, 1.0);

  /// 1.0 at target, linearly fading to 0 once |value − target| exceeds
  /// tolerance × target on either side.
  static double _closeness(
    double value,
    double target, {
    required double tolerance,
  }) {
    if (target <= 0) return 0;
    final deviation = (value - target).abs() / target;
    return (1 - deviation / tolerance).clamp(0.0, 1.0);
  }
}
