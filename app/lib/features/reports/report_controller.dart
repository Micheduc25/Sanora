import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../core/providers/app_providers.dart';
import '../../core/utils/extensions.dart';
import '../../domain/models/enums.dart';
import '../../domain/models/health_profile.dart';
import '../../domain/models/user_profile.dart';
import '../onboarding/onboarding_controller.dart';

class ReportDay {
  const ReportDay({
    required this.day,
    required this.calories,
    required this.proteinG,
    required this.waterMl,
    required this.steps,
    this.sleepHours,
    this.weightKg,
  });

  final DateTime day;
  final double calories;
  final double proteinG;
  final double waterMl;
  final int steps;
  final double? sleepHours;
  final double? weightKg;
}

class WeeklyReport {
  const WeeklyReport({
    required this.profile,
    required this.health,
    required this.days,
    required this.habitsCompletionPct,
    required this.workoutsCompleted,
    required this.weightDelta,
    required this.mealsLogged,
  });

  final UserProfile profile;
  final HealthProfile health;
  final List<ReportDay> days;
  final int habitsCompletionPct;
  final int workoutsCompleted;
  final double? weightDelta;
  final int mealsLogged;

  double get avgCalories => _avg(days.map((d) => d.calories));
  double get avgProtein => _avg(days.map((d) => d.proteinG));
  double get avgSteps => _avg(days.map((d) => d.steps.toDouble()));
  double get avgWater => _avg(days.map((d) => d.waterMl));
  double? get avgSleep {
    final values = days.map((d) => d.sleepHours).whereType<double>();
    return values.isEmpty ? null : _avg(values);
  }

  static double _avg(Iterable<double> values) {
    final list = values.toList();
    if (list.isEmpty) return 0;
    return list.reduce((a, b) => a + b) / list.length;
  }
}

final weeklyReportProvider = FutureProvider.autoDispose<WeeklyReport?>((
  ref,
) async {
  final profile = ref.watch(userProfileProvider);
  final health = ref.watch(healthProfileProvider);
  if (profile == null || health == null) return null;

  final metrics = ref.watch(metricsRepositoryProvider);
  final meals = ref.watch(mealsRepositoryProvider);
  final habits = ref.watch(habitsRepositoryProvider);
  final workouts = ref.watch(workoutsRepositoryProvider);
  final activity = ref.watch(activityServiceProvider);

  final today = DateTime.now().dateOnly;
  final days = <ReportDay>[];
  for (var offset = 6; offset >= 0; offset--) {
    final day = today.subtract(Duration(days: offset));
    final nutrition = meals.dayNutrition(day);
    final sleep = metrics
        .forDay(day)
        .where((m) => m.type == MetricType.sleep)
        .firstOrNull
        ?.value;
    final weight = metrics
        .forDay(day)
        .where((m) => m.type == MetricType.weight)
        .firstOrNull
        ?.value;
    // Same merge rule as the dashboard — take whichever source saw more —
    // so the two screens can never quote different step counts.
    final manualSteps = metrics.dayTotal(MetricType.steps, day).round();
    final platformSteps = await activity.stepsForDay(day);
    days.add(
      ReportDay(
        day: day,
        calories: nutrition.calories,
        proteinG: nutrition.proteinG,
        waterMl: metrics.dayTotal(MetricType.water, day),
        steps: platformSteps > manualSteps ? platformSteps : manualSteps,
        sleepHours: sleep,
        weightKg: weight,
      ),
    );
  }

  var habitsDue = 0;
  var habitsDone = 0;
  for (final day in days) {
    final due = habits.activeForDay(day.day);
    habitsDue += due.length;
    habitsDone += due.where((h) => habits.isDoneForDay(h, day.day)).length;
  }

  final weights = days.map((d) => d.weightKg).whereType<double>().toList();
  final weekAgoStart = today.subtract(const Duration(days: 6));

  return WeeklyReport(
    profile: profile,
    health: health,
    days: days,
    habitsCompletionPct: habitsDue == 0
        ? 0
        : (habitsDone / habitsDue * 100).round(),
    workoutsCompleted: workouts
        .completedBetween(weekAgoStart, today.add(const Duration(days: 1)))
        .length,
    weightDelta: weights.length >= 2 ? weights.last - weights.first : null,
    mealsLogged: days.fold(0, (sum, d) => sum + meals.forDay(d.day).length),
  );
});
